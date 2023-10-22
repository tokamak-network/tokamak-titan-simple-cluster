#!/bin/bash

NAMESPACE="default"
SERVICE="titan"

while [ $# -gt 0 ]; do
    OPTION=$1
    case $OPTION in
    -n | -namespace)
        if [[ -z $2 ]]; then
            echo "Error: Please Enter an option value"
            exit 1
        fi
        NAMESPACE=$2
        shift 2
        ;;
    -s | -service)
        if [[ -z $2 ]]; then
            echo "Error: Please Enter an option value"
            exit 1
        fi
        SERVICE=$2
        shift 2
        ;;
    *)
        POSITION+=($1)
        shift
        ;;
    esac
done
set -- "${POSITION[@]}"

if [[ $NAMESPACE != "default" ]] && ! kubectl get ns $NAMESPACE >/dev/null 2>&1; then
    kubectl create ns $NAMESPACE
fi

TASK=$1

TOKAMAK_TITAN_PATH=$(cd $(dirname $0)/../tokamak-optimism && pwd -P)
APPS_PATH=$(cd $(dirname $0)/../apps && pwd -P)
WORK_PATH=""

TOKAMAK_TITAN_RESOURCES=("secret" "storage" "l1chain" "deployer" "data-transport-layer" "l2geth" "batch-submitter" "relayer")
APPS_BLOCKSOCUT_RESOURCES=("postgresql" "sig-provider" "smart-contract-verifier" "visualizer" ".")
APPS_GATEWAY_RESOURCES=(".")
EXPORT_SERVICE_RESOURCES=("l1chain-svc" "l2geth-svc" "blockscout-svc" "app-gateway-svc")

# $1 = PATH, $2 = resource
function apply_resource() {
    local ns
    [[ $2 == "storage" ]] && ns="local-path-storage" || ns=$NAMESPACE
    kubectl -n $ns apply -f $1/$2
}

# $1 = PATH, $2 = resource
function delete_resource() {
    local ns
    [[ $2 == "storage" ]] && ns="local-path-storage" || ns=$NAMESPACE
    kubectl -n $ns delete -f $1/$2
}

# $1 = addons name
function enable_addons() {
    local addon_name=$1
    if [[ $(minikube addons list | awk -v a="$addon_name" '{if($2==a) print $6}') == "disabled" ]]; then
        minikube addons enable $addon_name
        [[ $addon_name == "ingress" ]] && echo Waiting $addon_name addon completed run... && sleep 15
    fi
}

function add_dns() {
    local dns="nameserver $(minikube ip)"
    local exist_minikube_dns=$(awk -v dns="$dns" '{if($0==dns) print "true"}' /etc/resolv.conf)
    if [[ $exist_minikube_dns != "true" ]]; then
        which resolvconf >/dev/null 2>&1 || sudo apt-get install resolvconf -y >/dev/null 2>&1
        echo $dns | sudo tee -a /etc/resolvconf/resolv.conf.d/tail
        sudo resolvconf -u
    fi
}

function check_minikube() {
    if ! minikube status >/dev/null 2>&1; then
        if which minikube >/dev/null 2>&1; then
            echo 'minikube is not running'
            echo 'Could you start minikube? [Y/N]'
            read input
            if [[ $input == 'Y' ]]; then
                echo '※ We recommanded minimum 2 cpus for running simplecluster ※'
                echo 'Please input Number of CPUs allocated to minikube (ex. 2) :'
                read cpus
                echo '※ We recommanded minimum 4096 memory for running simplecluster ※'
                echo 'Please input Amount of RAM to allocate to minikube (ex. 4096) :'
                read memory
                minikube start --driver=docker --cpus=$cpus --memory=$memory
            fi
        else
            echo 'minikube is not installed'
            echo 'Could you install minikube? [Y/N]'
            read input
            if [[ $input == 'Y' ]]; then
                source install_minikube.sh
            fi
        fi
    fi
}

check_minikube

case $TASK in
start)
    enable_addons ingress
    enable_addons ingress-dns
    add_dns

    if [[ $SERVICE == "titan" ]]; then
        for resource in ${TOKAMAK_TITAN_RESOURCES[@]}; do
            apply_resource $TOKAMAK_TITAN_PATH $resource
        done
    elif [[ $SERVICE == "blockscout" ]]; then
        for resource in ${APPS_BLOCKSOCUT_RESOURCES[@]}; do
            apply_resource $APPS_PATH/blockscout $resource
        done
    elif [[ $SERVICE == "gateway" ]]; then
        for resource in ${APPS_GATEWAY_RESOURCES[@]}; do
            apply_resource $APPS_PATH/gateway $resource
        done
    elif [[ $SERVICE == "all" ]]; then
        for resource in ${TOKAMAK_TITAN_RESOURCES[@]}; do
            apply_resource $TOKAMAK_TITAN_PATH $resource
        done

        for resource in ${APPS_BLOCKSOCUT_RESOURCES[@]}; do
            apply_resource $APPS_PATH/blockscout $resource
        done

        for resource in ${APPS_GATEWAY_RESOURCES[@]}; do
            apply_resource $APPS_PATH/gateway $resource
        done
    fi
    ;;
delete)
    if [[ $SERVICE == "titan" ]]; then
        for resource in ${TOKAMAK_TITAN_RESOURCES[@]}; do
            delete_resource $TOKAMAK_TITAN_PATH $resource
        done
    elif [[ $SERVICE == "blockscout" ]]; then
        for resource in ${APPS_BLOCKSOCUT_RESOURCES[@]}; do
            delete_resource $APPS_PATH/blockscout $resource
        done
    elif [[ $SERVICE == "gateway" ]]; then
        for resource in ${APPS_GATEWAY_RESOURCES[@]}; do
            delete_resource $APPS_PATH/gateway $resource
        done
    elif [[ $SERVICE == "all" ]]; then
        for resource in ${TOKAMAK_TITAN_RESOURCES[@]}; do
            delete_resource $TOKAMAK_TITAN_PATH $resource
        done

        for resource in ${APPS_BLOCKSOCUT_RESOURCES[@]}; do
            delete_resource $APPS_PATH/blockscout $resource
        done

        for resource in ${APPS_GATEWAY_RESOURCES[@]}; do
            delete_resource $APPS_PATH/gateway $resource
        done
    fi
    ;;
export)
    port=8001
    ip=$(wget -qO- http://instance-data/latest/meta-data/public-ipv4)
    for service in ${EXPORT_SERVICE_RESOURCES[@]}; do
        if kubectl -n $NAMESPACE get svc $service >/dev/null 2>&1; then
            case $service in
            l1chain-svc)
                echo L1 Chian RPC address : http://$ip:$port
                kubectl port-forward --address 0.0.0.0 svc/$service $port:8545 >>/dev/null &
                ;;
            l2geth-svc)
                echo L2 Geth RPC address : http://$ip:$port
                kubectl port-forward --address 0.0.0.0 svc/$service $port:8545 >>/dev/null &
                ;;
            blockscout-svc)
                echo Blockscout address : http://$ip:$port
                kubectl port-forward --address 0.0.0.0 svc/$service $port:80 >>/dev/null &
                ;;
            app-gateway-svc)
                echo Gateway address : http://$ip:$port
                kubectl port-forward --address 0.0.0.0 svc/$service $port:80 >>/dev/null &
                ;;
            esac
            port=$((port + 1))
        fi
    done
    svc_pid=$(ps -fu | grep 'kubectl port-forward' | grep -v "grep" | awk '{print $2}')
    if [[ -z $svc_pid ]]; then
        echo There is not exist service
    else
        echo Press CTRL-C to stop server
        wait
        kill $svc_pid
    fi
    ;;
esac
