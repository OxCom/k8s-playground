#!/bin/bash

ARG_CMD=${1:-help}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

function usage {
   cat << EOF
Usage: 01-metrics.sh <command>

Available commands:
  up       - install metrics server into a cluster
  down     - uninstall metrics server into a cluster
  help     - show this help

Example:
  $ ./01-metrics.sh up

EOF
   exit 1
}

case $ARG_CMD in
  up)
    echo 'Setup Metrics server'
    kubectl apply -f ${DIR}/../../src/cluster/metrics.yaml
    ;;

  down)
    echo 'Remove Metrics server'
    kubectl delete -f ${DIR}/../../src/cluster/metrics.yaml
    ;;

  *)
    usage
    ;;
esac
