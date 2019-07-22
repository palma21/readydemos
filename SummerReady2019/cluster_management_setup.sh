#!/bin/bash


# My Aliases
function k() {
    /usr/local/bin/kubectl "$@"
}

function kctx() {
    /usr/local/bin/kubectl config use-context "$@"
}

## Only works on WSL
 function chrome(){
     /c/Program\ Files\ \(x86\)/Google/Chrome/Application/chrome.exe "$@"
}

# Variables
PREFIX="aksmgmt-demo"
RG="${PREFIX}-rg"
LOC="westus2"
AKSNAME="${PREFIX}"
AKSNAME2="${PREFIX}2"
K8S_VERSION=1.13.5
AZURE_ACCOUNT_NAME="JPalma-Internal"
PLUGIN=azure
VM_SIZE=Standard_D2s_v3
WINDOWS_PASSWORD='Pa$$w0rd2019!'
WINDOWS_USER="jpalma"
MC_RG_NAME="infra-${PREFIX}"
MC_RG_NAME2="infra-${PREFIX}2"
NODEPOOL_NAME="ready"

usage()
{
    echo "usage: aks-test-setup.sh [[[-p Network_Plugin ] [-s NODE_VM_SIZE]] | [-h]]"
}


while [ "$1" != "" ]; do
  case $1 in
  -p | --plugin )         
    shift
    PLUGIN=$1
    ;;
  -s | --node-vm-size )
    shift   
    VM_SIZE=$1
    ;;
  -h | --help )
    usage
    exit
    ;;
  * )
    usage
    exit 1
  esac
  shift
done


# Setup right subscription
az account set -s $AZURE_ACCOUNT_NAME


# pre-clean up
az group delete -y -n $RG &> /dev/null

az ad sp delete --id "http://${PREFIX}sp" &> /dev/null


eval "$(az ad sp create-for-rbac -n ${PREFIX}sp --skip-assignment | jq -r '. | to_entries | .[] | .key + "=\"" + .value + "\""' | sed -r 's/^(.*=)/\U\1/')"
echo $APPID
echo $PASSWORD

sleep 30

# Create Resource Group if not exists
az group create --name $RG --location $LOC 2> /dev/null
    



# Create AKS
az aks create -g $RG -n $AKSNAME -k $K8S_VERSION -l $LOC \
  --node-count 3 --generate-ssh-keys -a monitoring -s $VM_SIZE \
  --network-plugin $PLUGIN \
  --service-principal $APPID \
  --client-secret $PASSWORD \
  --windows-admin-password $WINDOWS_PASSWORD \
  --windows-admin-username $WINDOWS_USER \
  --enable-vmss \
  --load-balancer-sku standard \
  --node-zones 1 2 3 \
  --node-resource-group $MC_RG_NAME \
  --tags 'event=Ready' 'Session=R-AIT300'


# Get AKS Credentials so kubectl works
az aks get-credentials -g $RG -n $AKSNAME --admin --overwrite-existing

# Get Nodes
kubectl get nodes -o wide

az aks upgrade -n $AKSNAME -g $RG -k 1.14.3

k apply -f ~/workbench/aks-examples/azure-vote.yaml

# Create new nodepool
az aks nodepool add --cluster-name $AKSNAME -g $RG -n $NODEPOOL_NAME -c 2 -k 1.13.5


# Create AKS 2
az aks create -g $RG -n $AKSNAME2 -k $K8S_VERSION -l $LOC \
  --node-count 3 --generate-ssh-keys -a monitoring -s $VM_SIZE \
  --network-plugin $PLUGIN \
  --service-principal $APPID \
  --client-secret $PASSWORD \
  --windows-admin-password $WINDOWS_PASSWORD \
  --windows-admin-username $WINDOWS_USER \
  --enable-vmss \
  --load-balancer-sku standard \
  --node-zones 1 2 3 \
  --node-resource-group $MC_RG_NAME2 \
  --tags 'event=Ready' 'Session=R-AIT300'

# Get AKS Credentials so kubectl works
az aks get-credentials -g $RG -n $AKSNAME2 --admin --overwrite-existing

# Get Nodes
kubectl get nodes -o wide

az aks upgrade -n $AKSNAME2 -g $RG -k 1.14.3

k apply -f ~/workbench/aks-examples/azure-vote.yaml

# Create new nodepool
az aks nodepool add --cluster-name $AKSNAME2 -g $RG -n $NODEPOOL_NAME -c 2 -k 1.14.3

