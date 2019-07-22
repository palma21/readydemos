#!/bin/bash

# Including DemoMagic
. demo-magic.sh

# Defining Type Speed
TYPE_SPEED=20

# Defining Custom prompt
DEMO_PROMPT="${green2}\u@\H${WHITE}:${blue2}\w${yellow}$ "


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


# Demo Variables
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
NODEPOOL_NAME="ready"


# Pre-cleanup
# az aks delete -y -n $AKSNAME -g $RG &> /dev/null

# Create Resource Group if it doesn't exist
# az group create --name $RG --location $LOC &> /dev/null


# Create AKS
p "az aks create -g $RG -n $AKSNAME -k $K8S_VERSION -l $LOC \
  -c 3 -a monitoring -s \$VM_SIZE \
  --network-plugin $PLUGIN \
  --service-principal \$APPID \
  --client-secret \$PASSWORD \
  --windows-admin-password \$WINDOWS_PASSWORD \
  --windows-admin-username \$WINDOWS_USER \
  --enable-vmss \
  --load-balancer-sku standard \
  --node-zones 1 2 3 \
  --node-resource-group $MC_RG_NAME \
  --tags 'event=Ready' 'Session=R-AIT300' --no-wait"

pe "kctx aksmgmt-demo-admin"

pe "clear"

chrome "https://ms.portal.azure.com/#@microsoft.onmicrosoft.com/resource/subscriptions/df4aff33-3507-48d9-a24c-3439ab6b3079/resourceGroups/aksmgmt-demo-rg/providers/Microsoft.ContainerService/managedClusters/aksmgmt-demo/overview"

# Create new nodepool
p "az aks nodepool add --cluster-name $AKSNAME -g $RG -n $NODEPOOL_NAME -c 2 --no-wait"


pe "clear"

chrome "https://ms.portal.azure.com/#@microsoft.onmicrosoft.com/resource/subscriptions/df4aff33-3507-48d9-a24c-3439ab6b3079/resourceGroups/aksmgmt-demo-rg/providers/Microsoft.ContainerService/managedClusters/aksmgmt-demo/nodePools"

# Upgrade Control plane
p "az aks upgrade -n $AKSNAME -g $RG -k 1.14.3"

p "az aks nodepool upgrade --cluster-name $AKSNAME -g $RG -n $NODEPOOL_NAME -k 1.14.3 --no-wait"

pe "kctx aksmgmt-demo2-admin"

# Use Chrome instead
pe "k get nodes"

pe "k get pods -o wide"

pe "k cordon -l agentpool=nodepool1"

pe "k drain -l agentpool=nodepool1 --ignore-daemonsets --delete-local-data"

pe "k get pods -o wide"

pe "k uncordon -l agentpool=nodepool1"


pe "clear"

# Clean up

k cordon -l agentpool=ready
k drain -l agentpool=ready --ignore-daemonsets --delete-local-data
k uncordon -l agentpool=ready






