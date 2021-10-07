#!/bin/bash

ARG_CMD=${1:-help}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

function usage {
   cat << EOF
Usage: 00-network.sh <command>

Available commands:
  up       - install Calico on K8S cluster
  down     - uninstall Calico on K8S cluster
  help     - show this help

Example:
  $ ./00-network.sh up

EOF
   exit 1
}

case $ARG_CMD in
  up)
    echo 'Calico setup'
    echo "See Calico SRC https://docs.projectcalico.org/getting-started/kubernetes/self-managed-onprem/onpremises"
    helm repo add rook-release https://charts.rook.io/release
    kubectl apply -f ${DIR}/../../src/cluster/network-calico.yaml
    ;;

  down)
    echo 'Remove Calico network'
    kubectl delete -f ${DIR}/../../src/cluster/network-calico.yaml
    ;;

  *)
    usage
    ;;
esac
