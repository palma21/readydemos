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


# Variables
PREFIX="secdemo"
RG="${PREFIX}-rg"
LOC="westus2"
AKSNAME="${PREFIX}"
VNET_NAME="${PREFIX}vnet"
AKSSUBNET_NAME="${PREFIX}akssubnet"
SVCSUBNET_NAME="${PREFIX}svcsubnet"
APPGWSUBNET_NAME="${PREFIX}appgwsubnet"
FWSUBNET_NAME="AzureFirewallSubnet"
IDENTITY_NAME="${PREFIX}identity"
FWNAME="${PREFIX}fw"
FWPUBLICIP_NAME="${PREFIX}fwpublicip"
FWIPCONFIG_NAME="${PREFIX}fwconfig"
FWROUTE_TABLE_NAME="${PREFIX}fwrt"
FWROUTE_NAME="${PREFIX}fwrn"
AGNAME="${PREFIX}ag"
AGPUBLICIP_NAME="${PREFIX}agpublicip"
STORAGE_NAME="${PREFIX}${DATE}storage"
FILES_NAME="fruit"
AZURE_ACCOUNT_NAME="JPalma-Internal"
K8S_VERSION=1.13.5
VM_SIZE=Standard_D2s_v3
WINDOWS_PASSWORD='Pa$$w0rd2019!'
WINDOWS_USER="jpalma"
PLUGIN=azure
JUMPBOX=52.229.37.228
FWPUBLIC_IP=52.143.74.210

kctx secdemo-admin

# Get pods
pe "k get pods -o wide"

pe "k get svc"

APP_IP=$(az network public-ip show -g $RG -n $AGPUBLICIP_NAME --query "ipAddress" -o tsv)

chrome $APP_IP

# DEMO 1
# Test Firewall
pe "k exec -it centos -- /bin/bash"
# curl www.ubuntu.com
# curl superman.com
# exit

# DEMO 4
# Network Policy
pe "k get svc"
pe "k exec -it centos -- curl 10.42.2.232"
pe "k apply -f np-denyall.yaml"
pe "k exec -it centos -- curl 10.42.2.232"
# Check Browser - Zero Workers
pe "k apply -f np-web-allow-ingress.yaml"
pe "k apply -f np-web-allow-worker.yaml"
pe "k get networkpolicy"
pe "k exec -it centos -- curl 10.42.2.232"
# Check Browser - Working


pe "az aks update -g $RG -n $AKSNAME --api-server-authorized-ip-ranges $FWPUBLIC_IP/32,$JUMPBOX/32"

pe "ssh $JUMPBOX"

pe "clear"

# Reset DEMO 4
az aks update -g $RG -n $AKSNAME --api-server-authorized-ip-ranges '' 
k delete -f np-denyall.yaml
k delete -f np-web-allow-worker.yaml
k delete -f np-web-allow-ingress.yaml
k get po,svc,ingress,deploy,secrets,networkpolicy


