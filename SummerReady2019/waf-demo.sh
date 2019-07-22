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


PREFIX="wafdemo"
RG="aks-security-demo-rg"
LOC="westus2"
AKSNAME="${PREFIX}"
VNET_NAME="${PREFIX}vnet"
AKSSUBNET_NAME="${PREFIX}akssubnet"
SVCSUBNET_NAME="${PREFIX}svcsubnet"
APPGWSUBNET_NAME="${PREFIX}appgwsubnet"
IDENTITY_NAME="${PREFIX}identity"
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
SUBID=$(az account show -s $AZURE_ACCOUNT_NAME -o tsv --query 'id')



p "az group create -n $RG -l $LOC --no-wait"

p "az network vnet create \
    --resource-group $RG \
    --name $VNET_NAME \
    --address-prefixes 10.42.0.0/16 \
    --subnet-name $AKSSUBNET_NAME \
    --subnet-prefix 10.42.1.0/24"

p "az network vnet subnet create \
    --resource-group $RG \
    --vnet-name $VNET_NAME \
    --name $SVCSUBNET_NAME \
    --address-prefix 10.42.2.0/24"

p "az network vnet subnet create \
    --resource-group $RG \
    --vnet-name $VNET_NAME \
    --name $APPGWSUBNET_NAME \
    --address-prefix 10.42.3.0/24"

# Get $VNETID & $SUBNETID
p 'VNETID=$(az network vnet show -g $RG --name $VNET_NAME --query id -o tsv)'
p 'SUBNETID=$(az network vnet subnet show -g $RG --vnet-name $VNET_NAME --name $AKSSUBNET_NAME --query id -o tsv)'


p "az aks create -g $RG -n $AKSNAME -k 1.13.5 -l $LOC \
  --node-count 2 --generate-ssh-keys \
  --network-plugin azure \
  --network-policy azure \
  --service-cidr 10.41.0.0/16 \
  --dns-service-ip 10.41.0.10 \
  --docker-bridge-address 172.17.0.1/16 \
  --vnet-subnet-id \$SUBNETID \
  --service-principal \$APPID \
  --client-secret \$PASSWORD"


p "az network public-ip create -g $RG -n $AGPUBLICIP_NAME -l $LOC --sku Standard --no-wait"

p "az network application-gateway create \
  --name $AGNAME \
  --resource-group $RG \
  --location $LOC \
  --min-capacity 2 \
  --frontend-port 80 \
  --http-settings-cookie-based-affinity Disabled \
  --http-settings-port 80 \
  --http-settings-protocol Http \
  --routing-rule-type Basic \
  --sku WAF_v2 \
  --private-ip-address 10.42.3.12 \
  --public-ip-address $AGPUBLICIP_NAME \
  --subnet $APPGWSUBNET_NAME \
  --vnet-name $VNET_NAME"


  # Either wait or use the previously created cluster at Setup
pe "kctx wafdemo-admin"

# Get Nodes
pe "k get nodes -o wide"


# Show APP GW config file
pe "code agw-helm-config.yaml"

# Install App GW Ingress Controller
pe "helm install --name $AGNAME -f agw-helm-config.yaml application-gateway-kubernetes-ingress/ingress-azure"

# Check created resources
pe "k get po,svc,ingress,deploy,secrets"


# Deploy Front-End
pe "code build19-web.yaml build19-ingress-web.yaml"

pe "k apply -f build19-web.yaml"
pe "k apply -f build19-ingress-web.yaml"

# Deploy Back-End
BUILD_RG="build-waf"
STORAGE_NAME="build05052019storage"
pe "STORAGE_KEY=\$(az storage account keys list -n $STORAGE_NAME -g $BUILD_RG --query [0].'value' -o tsv)"


pe "k create secret generic fruit-secret --from-literal=azurestorageaccountname=$STORAGE_NAME --from-literal=azurestorageaccountkey=\$STORAGE_KEY"

pe "k apply -f build19-worker.yaml"

pe "k get po,svc,ingress,deploy,secrets"

# Test App
pe "az network public-ip show -g $RG -n $AGPUBLICIP_NAME --query \"ipAddress\" -o tsv"



## Clean up
pe "clear"


k delete -f build19-worker.yaml > /dev/null
k delete secret fruit-secret > /dev/null
k delete -f build19-ingress-web.yaml > /dev/null
k delete -f build19-web.yaml > /dev/null

helm del --purge $AGNAME > /dev/null
helm reset > /dev/null