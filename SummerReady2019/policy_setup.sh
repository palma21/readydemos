#!/bin/bash

# Variables
PREFIX="policy-demo"
RG="aks-security-demo-rg"
LOC="westus2"
AKSNAME="${PREFIX}"
K8S_VERSION=1.14.3
AZURE_ACCOUNT_NAME="JPalma-Internal"
VM_SIZE=Standard_D2s_v3
WINDOWS_PASSWORD='Pa$$w0rd2019!'
WINDOWS_USER="jpalma"
PLUGIN=azure

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
#az group delete -y -n $RG &> /dev/null
az aks delete -y -n $AKSNAME -g $RG &> /dev/null 
az ad sp delete --id "http://${PREFIX}sp" &> /dev/null

# Automatically print the SP values into $APPID and $PASSWORD, trust me
eval "$(az ad sp create-for-rbac -n ${PREFIX}sp --skip-assignment | jq -r '. | to_entries | .[] | .key + "=\"" + .value + "\""' | sed -r 's/^(.*=)/\U\1/')"
echo $APPID
echo $PASSWORD

# Create Resource Group
az group create --name $RG --location $LOC

az aks create -g $RG -n $AKSNAME -k $K8S_VERSION -l $LOC \
  --node-count 2 --generate-ssh-keys -s $NODE_VM_SIZE \
  --network-plugin $PLUGIN \
  --service-principal $APPID \
  --client-secret $PASSWORD \
  --enabe-vmss

# Get AKS Credentials so kubectl works
az aks get-credentials -g $RG -n $AKSNAME --admin --overwrite-existing

k apply -f test-pod.yaml

az aks enable-addons --addons azure-policy --name $AKSNAME --resource-group $RG

