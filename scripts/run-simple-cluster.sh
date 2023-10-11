#!/bin/bash

NAMESPACE="default"

while [ $# -gt 0 ]; do
    OPTION=$1
    case $OPTION in
    -n | -namespace)
        NAMESPACE=$2
        shift 2
        ;;
    *)
        POSITION+=($1)
        shift
        ;;
    esac
done
set -- "${POSITION[@]}"

if [[ $NAMESPACE != "default" && -z $(kubectl get ns | grep $NAMESPACE) ]]; then
    kubectl create ns $NAMESPACE
fi

TASK=$1

TOKAMAK_TITAN_PATH=$(cd $(dirname $(dirname $0))/tokamak-optimism && pwd -P)
APPS_PATH=$(cd $(dirname $(dirname $0))/apps && pwd -P)
WORK_PATH=""

PRERUN_RESOURCES=("secret" "storage")
TOKAMAK_TITAN_RESOURCES=("l1chain" "deployer" "data-transport-layer" "l2geth" "batch-submitter" "relayer")

# $1 = PATH, $2 = resource
function set_manifests() {
    if [[ $# -lt 2 ]]; then
        echo "Error: there is no arguments to set manifests"
        unset_manifests
        exit 1
    fi

    WORK_PATH="$1/$2"
    MANIFESTS=($(ls $WORK_PATH | grep -v pvc && ls $WORK_PATH | grep pvc))
}

function unset_manifests() {
    unset MANIFESTS
    unset WORK_PATH
}

# $1 = PATH, $2 = resource
function check_resource() {
    local ns
    [[ $2 == "storage" ]] && ns="local-path-storage" || ns=$NAMESPACE
    set_manifests $1 $2
    for manifest in ${MANIFESTS[@]}; do
        if [[ -z $(kubectl -n $ns get -f $WORK_PATH/$manifest) ]]; then
            unset_manifests
            echo false
            exit 1
        fi
    done
    unset_manifests
    echo true
}

# $1 = PATH, $2 = resource
function apply_resource() {
    local ns
    [[ $2 == "storage" ]] && ns="local-path-storage" || ns=$NAMESPACE
    set_manifests $1 $2
    for manifest in ${MANIFESTS[@]}; do
        kubectl -n $ns apply -f $WORK_PATH/$manifest
    done
    unset_manifests
}

case $TASK in
start)
    for resource in ${PRERUN_RESOURCES[@]}; do
        if [[ $(check_resource $TOKAMAK_TITAN_PATH $resource) == "false" ]]; then
            apply_resource $TOKAMAK_TITAN_PATH $resource
        fi
    done
    ;;
delete) ;;
esac
