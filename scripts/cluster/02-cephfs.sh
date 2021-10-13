#!/bin/bash

ARG_CMD=${1:-help}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

function usage {
   cat << EOF
Usage: 02-cephfs.sh <command>

Available commands:
  up       - install rook with CephFS support on K8S cluster
  down     - uninstall rook with CephFS support on K8S cluster
  help     - show this help

Example:
  $ ./02-ephfs.sh up

EOF
   exit 1
}

function waitXSeconds {
  seconds=$1
  echo ">> waiting for ${seconds} seconds ..."
  while [ $seconds -gt 0 ]
  do
      sleep 1;
      echo -n .;
      seconds=$(( $seconds - 1 ));
  done

  echo '';
}

case $ARG_CMD in
  up)
    echo 'Helm setup'
    helm repo add rook-release https://charts.rook.io/release
    kubectl apply -f ${DIR}/../../src/cluster/storage/ns.yaml

    echo 'Deploying Rook'
    helm install rook-ceph --namespace rook-ceph rook-release/rook-ceph

    echo '>> Waiting for rook operator'
    until kubectl get -A pods | grep rook-ceph-operator | grep Running; do sleep 1; echo -n .; done

    echo '>> Create the CRDs'
    kubectl apply -f ${DIR}/../../src/cluster/storage/crds.yaml

    echo '>> Create the common resources that are necessary to start the operator and the ceph cluster'
    kubectl apply -f ${DIR}/../../src/cluster/storage/common.yaml

    echo '>> Wait few seconds for warm up before cluster setup'
    waitXSeconds 30

    echo 'Creating a Ceph cluster'
    kubectl apply -f ${DIR}/../../src/cluster/storage/cluster.yaml

    echo 'Adding block storage'
    kubectl apply -f ${DIR}/../../src/cluster/storage/storageclass-block.yaml
    kubectl apply -f ${DIR}/../../src/cluster/storage/storageclass-shared.yaml

    echo 'Deploying the Rook Toolbox'
    kubectl apply -f ${DIR}/../../src/cluster/storage/toolbox.yaml

    ;;

  down)
    echo 'Remove Rook'
    echo 'ERROR: at this moment remove rook cause stuck the K8S in a process to delete related resources. Investigation required.'

    echo '>> Drop PVC and PC'
    kubectl get pvc,pv | grep rook-ceph-block | cut -d' ' -f1 | while read s; do kubectl delete $s; done

    echo '>> Remove block storage'
    kubectl delete -f ${DIR}/../../src/cluster/storage/storageclass-block.yaml
    kubectl delete -f ${DIR}/../../src/cluster/storage/storageclass-shared.yaml
    kubectl get storageclass | grep rook-ceph | cut -d' ' -f1 | while read s; do kubectl delete storageclass/$s; done

    echo '>> Remove the Rook Toolbox'
    kubectl delete -f ${DIR}/../../src/cluster/storage/toolbox.yaml

    echo '>> Remove a Ceph cluster'
    kubectl delete -f ${DIR}/../../src/cluster/storage/cluster.yaml

    echo '>> Wait few seconds for teardown the cluster'
    waitXSeconds 30

    echo '>> Remove the common resources that are necessary to start the operator and the ceph cluster'
    kubectl delete -f ${DIR}/../../src/cluster/storage/common.yaml

    echo '>> Remove the CRDs'
    kubectl delete -f ${DIR}/../../src/cluster/storage/crds.yaml

    echo '>> Clean helm deployment'
    helm delete rook-ceph --namespace rook-ceph rook-release/rook-ceph
    waitXSeconds 30

    echo '>> Drop SCI drivers'
    kubectl get csidrivers | grep rook-ceph | cut -d' ' -f1 | while read s; do kubectl delete csidrivers/$s; done

    echo '>> Drop NS'
    kubectl delete -f ${DIR}/../../src/cluster/storage/ns.yaml

    echo '>> Manual work required'
    cat << EOF
To get Rook functional again we have to wipe disks on each node (tested only on Ubuntu):

  lsblk -f
  dd if=/dev/zero of=/dev/sdc bs=512 count=1
  dd if=/dev/zero of=/dev/sdd bs=512 count=1
  lvremove -f /dev/mapper/ceph*
  pvremove -ffy /dev/sdc*
  pvremove -ffy /dev/sdd*
  lsblk -f
  docker system prune -a -f

EOF

    ;;

  *)
    usage
    ;;
esac
