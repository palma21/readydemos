#!/bin/bash

# Including DemoMagic
. demo-magic.sh

# Defining Type Speed
TYPE_SPEED=20

# Defining Custom prompt    
DEMO_PROMPT="${green2}\u@\H${WHITE}:${blue2}\w${yellow}$ "

LOCATION=westus
ACR_NAME=<CHANGE THIS>
ACR_URL=<CHANGE THIS>
ACR_RG_NAME=<CHANGE THIS>
LOCATION=westus
RG_NAME=readydemo-rg
AKS_NAME=readydemo
VN_SUBNET_NAME=vnreadydemosubnet
APPINSIGHTS_INSTRUMENTATIONKEY=<CHANGE THIS>
COSMOS_NAME=<CHANGE THIS>
MONGODB_USER=<CHANGE THIS>
MONGODB_PASSWORD=<CHANGE THIS>
ACR_USERNAME=<CHANGE THIS>
ACR_PASSWORD=<CHANGE THIS>

# Setup
clear
kctx ${AKS_NAME} > /dev/null

# Manual Scaling
pe "k scale deployment service-tracker-ui -n hackfest --replicas=3"

pe "k get deployments -n hackfest"

# HPA
p "k apply -f hpa.yaml -n hackfest"
k apply -f ~/workbench/kubernetes-hackfest/labs/scaling/hpa.yaml -n hackfest

pe "kubectl get pod,svc -n hackfest"

# Cluster scaling
# pe "az aks scale --name ${AKS_NAME} --resource-group ${RG_NAME} --node-count 5"
p "az aks scale --name ${AKS_NAME} --resource-group ${RG_NAME} --node-count 5"

pe "az aks update --resource-group ${RG_NAME} --name ${AKS_NAME} --enable-cluster-autoscaler --min-count 1 --max-count 7"


# Clean up ??
# az aks update --resource-group ${RG_NAME} --name ${AKS_NAME} --disable-cluster-autoscaler

k delete -f ~/workbench/kubernetes-hackfest/labs/scaling/hpa.yaml -n hackfest > /dev/null

# Virtual Nodes
pe "az aks enable-addons --resource-group ${RG_NAME} --name ${AKS_NAME} --addons virtual-node --subnet-name ${VN_SUBNET_NAME}"

pe "k get nodes"

# pe "az container create --name data-updater --image ${ACR_NAME}.azurecr.io/hackfest/data-updater:1.0 --resource-group ${RG_NAME} --location ${LOCATION} --cpu 1 --memory 2 --registry-login-server ${ACR_NAME}.azurecr.io --registry-username ${ACR_USERNAME} --registry-password ${ACR_PASSWORD} --environment-variables MONGODB_USER=$MONGODB_USER MONGODB_PASSWORD=$MONGODB_PASSWORD APPINSIGHTS_INSTRUMENTATIONKEY=$APPINSIGHTS_INSTRUMENTATIONKEY UPDATE_INTERVAL=180000"

p "k apply -f aci/service-tracker-ui.yaml -n hackfest"
k apply -f ~/workbench/kubernetes-hackfest/labs/aci/service-tracker-ui.yaml -n hackfest

pe "k get pods -n hackfest -o wide"

pe "k delete deploy service-tracker-ui -n hackfest"

pe "k get pods -n hackfest -o wide"

pe "clear"

# Clean up
helm upgrade --install service-tracker-ui ~/workbench/kubernetes-hackfest/charts/service-tracker-ui --namespace hackfest --reset-values > /dev/null
az aks update --resource-group ${RG_NAME} --name ${AKS_NAME} --disable-cluster-autoscaler > /dev/null

k delete -f ~/workbench/kubernetes-hackfest/labs/aci/service-tracker-ui.yaml -n hackfest > /dev/null

az aks disable-addons --resource-group ${RG_NAME} --name ${AKS_NAME} --addons virtual-node > /dev/null

az container delete -n data-updater -g readydemo-rg -y > /dev/null



