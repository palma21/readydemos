#!/bin/bash

# Create Resource Group.
PREFIX="vp"
RG="${PREFIX}-rg"
LOC="westus2"
NAME="${PREFIX}20190212"
ACR_NAME="${NAME}acr"
VNET_NAME="${PREFIX}vnet"
AKSSUBNET_NAME="${PREFIX}akssubnet"
SVCSUBNET_NAME="${PREFIX}svcsubnet"
ACISUBNET_NAME="${PREFIX}acisubnet"
FWSUBNET_NAME="AzureFirewallSubnet"
APPGWSUBNET_NAME="${PREFIX}appgwsubnet"
WORKSPACENAME="${PREFIX}k8slogs"
KV_NAME="${PREFIX}kv"
IDENTITY_NAME="${PREFIX}identity"
FWNAME="${PREFIX}fw"
FWPUBLICIP_NAME="${PREFIX}fwpublicip"
FWIPCONFIG_NAME="${PREFIX}fwconfig"
FWROUTE_TABLE_NAME="${PREFIX}fwrt"
FWROUTE_NAME="${PREFIX}fwrn"
AGNAME="${PREFIX}ag"
AGPUBLICIP_NAME="${PREFIX}agpublicip"

# Get ARM Access Token and Subscription ID
ACCESS_TOKEN=$(az account get-access-token -o tsv --query 'accessToken')
# Note: Update Subscription Name
SUBID=$(az account show -s '<YOUR ACCOUNT NAME>' -o tsv --query 'id')

# Create Resource Group
az group create --name $RG --location $LOC

# Create Virtual Network & Subnets for AKS, k8s Services, ACI, Firewall and WAF
az network vnet create \
    --resource-group $RG \
    --name $VNET_NAME \
    --address-prefixes 10.42.0.0/16 \
    --subnet-name $AKSSUBNET_NAME \
    --subnet-prefix 10.42.1.0/24
az network vnet subnet create \
    --resource-group $RG \
    --vnet-name $VNET_NAME \
    --name $SVCSUBNET_NAME \
    --address-prefix 10.42.2.0/24    
az network vnet subnet create \
    --resource-group $RG \
    --vnet-name $VNET_NAME \
    --name $ACISUBNET_NAME \
    --address-prefix 10.42.3.0/24
az network vnet subnet create \
    --resource-group $RG \
    --vnet-name $VNET_NAME \
    --name $FWSUBNET_NAME \
    --address-prefix 10.42.4.0/24
az network vnet subnet create \
    --resource-group $RG \
    --vnet-name $VNET_NAME \
    --name $APPGWSUBNET_NAME \
    --address-prefix 10.42.5.0/24

# Create Public IP
az network public-ip create -g $RG -n $FWPUBLICIP_NAME -l $LOC --sku "Standard"
# Create Firewall
az network firewall create -g $RG -n $FWNAME -l $LOC
# Configure Firewall IP Config
# This command will take a few mins.
az network firewall ip-config create -g $RG -f $FWNAME -n $FWIPCONFIG_NAME --public-ip-address $FWPUBLICIP_NAME --vnet-name $VNET_NAME
# Capture Firewall IP Address for Later Use
FWPUBLIC_IP=$(az network public-ip show -g $RG -n $FWPUBLICIP_NAME --query "ipAddress")
FWPRIVATE_IP=$(az network firewall show -g $RG -n $FWNAME --query "ipConfigurations[0].privateIpAddress" -o tsv)
# Validate Firewall IP Address Values
echo $FWPUBLIC_IP
echo $FWPRIVATE_IP
# Create UDR & Routing Table
az network route-table create -g $RG --name $FWROUTE_TABLE_NAME
az network route-table route create -g $RG --name $FWROUTE_NAME --route-table-name $FWROUTE_TABLE_NAME --address-prefix 0.0.0.0/0 --next-hop-type VirtualAppliance --next-hop-ip-address $FWPRIVATE_IP --subscription $SUBID
# Add Network FW Rules
# TCP - * - * - 22
# Destination IP Addresses (US East DC): 13.68.128.0/17,13.72.64.0/18,13.82.0.0/16,13.90.0.0/16,13.92.0.0/16,20.38.98.0/24,20.39.32.0/19,20.42.0.0/17,20.185.0.0/16,20.190.130.0/24,23.96.0.0/17,23.98.45.0/24,23.100.16.0/20,23.101.128.0/20,40.64.0.0/16,40.71.0.0/16,40.76.0.0/16,40.78.219.0/24,40.78.224.0/21,40.79.152.0/21,40.80.144.0/21,40.82.24.0/22,40.82.60.0/22,40.85.160.0/19,40.87.0.0/17,40.87.164.0/22,40.88.0.0/16,40.90.130.96/28,40.90.131.224/27,40.90.136.16/28,40.90.136.32/27,40.90.137.96/27,40.90.139.224/27,40.90.143.0/27,40.90.146.64/26,40.90.147.0/27,40.90.148.64/27,40.90.150.32/27,40.90.224.0/19,40.91.4.0/22,40.112.48.0/20,40.114.0.0/17,40.117.32.0/19,40.117.64.0/18,40.117.128.0/17,40.121.0.0/16,40.126.2.0/24,52.108.16.0/21,52.109.12.0/22,52.114.132.0/22,52.125.132.0/22,52.136.64.0/18,52.142.0.0/18,52.143.207.0/24,52.146.0.0/17,52.147.192.0/18,52.149.128.0/17,52.150.0.0/17,52.151.128.0/17,52.152.128.0/17,52.154.64.0/18,52.159.96.0/19,52.168.0.0/16,52.170.0.0/16,52.179.0.0/17,52.186.0.0/16,52.188.0.0/16,52.190.0.0/17,52.191.0.0/18,52.191.64.0/19,52.191.96.0/21,52.191.104.0/27,52.191.105.0/24,52.191.106.0/24,52.191.112.0/20,52.191.192.0/18,52.224.0.0/16,52.226.0.0/16,52.232.146.0/24,52.234.128.0/17,52.239.152.0/22,52.239.168.0/22,52.239.207.192/26,52.239.214.0/23,52.239.220.0/23,52.239.246.0/23,52.239.252.0/24,52.240.0.0/17,52.245.8.0/22,52.245.104.0/22,52.249.128.0/17,52.253.160.0/24,52.255.128.0/17,65.54.19.128/27,104.41.128.0/19,104.44.91.32/27,104.44.94.16/28,104.44.95.160/27,104.44.95.240/28,104.45.128.0/18,104.45.192.0/20,104.211.0.0/18,137.116.112.0/20,137.117.32.0/19,137.117.64.0/18,137.135.64.0/18,138.91.96.0/19,157.56.176.0/21,168.61.32.0/20,168.61.48.0/21,168.62.32.0/19,168.62.160.0/19,191.233.16.0/21,191.234.32.0/19,191.236.0.0/18,191.237.0.0/17,191.238.0.0/18
az extension add --name azure-firewall
az network firewall network-rule create -g $RG -f $FWNAME --collection-name 'aksfwnr' -n 'ssh' --protocols 'TCP' --source-addresses '*' --destination-addresses '*' --destination-ports 22 --action allow --priority 100
# Add Application FW Rules
# *eastus.azmk8s.io,k8s.gcr.io,storage.googleapis.com,*auth.docker.io,*cloudflare.docker.io,*registry-1.docker.io,*.azurecr.io
az network firewall application-rule create -g $RG -f $FWNAME --collection-name 'aksfwar' -n 'AKS' --source-addresses '*' --protocols 'http=80' 'https=443' --target-fqdns '*gcr.io' 'storage.googleapis.com' '*azmk8s.io' '*auth.docker.io' '*cloudflare.docker.io' '*docker.com' '*docker.io' '*.ubuntu.com' '*azurecr.io' '*blob.core.windows.net' '*mcr.microsoft.com' '*cdn.mscr.io' '*microsoftonline.com' --action allow --priority 100
# Associate AKS Subnet to FW
az network vnet subnet update -g $RG --vnet-name $VNET_NAME --name $AKSSUBNET_NAME --route-table $FWROUTE_TABLE_NAME
# OR
#az network vnet subnet show -g $RG --vnet-name $VNET_NAME --name $AKSSUBNET_NAME --query id -o tsv
#SUBNETID=$(az network vnet subnet show -g $RG --vnet-name $VNET_NAME --name $AKSSUBNET_NAME --query id -o tsv)
#az network vnet subnet update -g $RG --route-table $FWROUTE_TABLE_NAME --ids $SUBNETID

# Create SP and Assign Permission to Virtual Network
az ad sp create-for-rbac -n "${PREFIX}sp" --skip-assignment
# Take the SP Creation output from above command and fill in Variables accordingly
APPID="<SP CLIENT ID>"
PASSWORD="<SP PASSWORD>"
VNETID=$(az network vnet show -g $RG --name $VNET_NAME --query id -o tsv)
# Assign SP Permission to VNET
az role assignment create --assignee $APPID --scope $VNETID --role Contributor

# Create Log Analytics Workspace
az group deployment create -n $WORKSPACENAME -g $RG \
  --template-file azuredeploy-loganalytics.json \
  --parameters workspaceName=$WORKSPACENAME \
  --parameters location=$LOC \
  --parameters sku="Standalone"
# Set Workspace ID
WORKSPACEIDURL=$(az group deployment list -g $RG -o tsv --query '[].properties.outputResources[0].id')

# Version Info
az aks get-versions -l $LOC -o table

# Create AKS Cluster with Monitoring add-on
SUBNETID=$(az network vnet subnet show -g $RG --vnet-name $VNET_NAME --name $AKSSUBNET_NAME --query id -o tsv)
az aks create -g $RG -n $NAME -k 1.12.5 -l $LOC \
  --node-count 2 --generate-ssh-keys \
  --enable-addons monitoring \
  --workspace-resource-id $WORKSPACEIDURL \
  --network-plugin azure \
  --network-policy azure \
  --service-cidr 10.41.0.0/16 \
  --dns-service-ip 10.41.0.10 \
  --docker-bridge-address 172.17.0.1/16 \
  --vnet-subnet-id $SUBNETID \
  --service-principal $APPID \
  --client-secret $PASSWORD \
  --no-wait

# Create Registry
az acr create -g "MC_${RG}_${NAME}_${LOC}" -n $ACR_NAME --sku Premium --admin-enabled
# List the new Cluster & Registry
az aks list -o table
az acr list -o table
# Get AKS Credentials so kubectl works
az aks get-credentials -g $RG -n $NAME --admin
# Get Nodes
k get nodes -o wide

# DEMO 1
# Test FW
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: centos
spec:
  containers:
  - name: centoss
    image: centos
    ports:
    - containerPort: 80
    command:
    - sleep
    - "3600"
EOF
# Exec into Pod and Check Traffic
k get po -o wide
k exec -it centos -- /bin/bash
curl www.ubuntu.com
curl superman.com
exit

# Create Azure App Gateway v2 with WAF and autoscale set to manual.
# Note: Azure App Gateway v2 is currently in Preview. Also note that it is not possible at this time
# to create an Azure App Gateway with WAF enabled without a Public IP.
# Create Public IP First.
az network public-ip create -g $RG -n $AGPUBLICIP_NAME -l $LOC --sku "Standard"
# Create App Gateway using WAF_v2 SKU.
az network application-gateway create \
  --name $AGNAME \
  --resource-group $RG \
  --location $LOC \
  --min-capacity 2 \
  --capacity 2 \
  --frontend-port 80 \
  --http-settings-cookie-based-affinity Disabled \
  --http-settings-port 80 \
  --http-settings-protocol Http \
  --routing-rule-type Basic \
  --sku WAF_v2 \
  --private-ip-address 10.42.5.12 \
  --public-ip-address $AGPUBLICIP_NAME \
  --subnet $APPGWSUBNET_NAME \
  --vnet-name $VNET_NAME

# Deploy Azure AD Identity Stuff
k create -f https://raw.githubusercontent.com/Azure/aad-pod-identity/master/deploy/infra/deployment-rbac.yaml
k delete -f https://raw.githubusercontent.com/Azure/aad-pod-identity/master/deploy/infra/deployment-rbac.yaml
# Create User Identity
# **** Make sure it is in the same RG as the VMs. ****
IDENTITY=$(az identity create -g "MC_${RG}_${NAME}_${LOC}" -n $IDENTITY_NAME)
echo $IDENTITY
# Assign Reader Role
ROLEREADER=$(az role assignment create --role Reader --assignee $APPID --scope "/subscriptions/${SUBID}/resourcegroups/${RG}")
echo $ROLEREADER
# Providing required permissions for MIC Using AKS SP
SCOPEID=$(echo $IDENTITY | jq .id | tr -d '"')
echo $SCOPEID
ROLEMIC=$(az role assignment create --role "Managed Identity Operator" --assignee $APPID --scope $SCOPEID)
echo $ROLEMIC
# Install User Azure AD Identity
# Note: Update the ResourceID and ClientID in aadpodidentity.yaml with id and clientId output of the $IDENTITY variable.
echo $IDENTITY | jq .id | tr -d '"'
echo $IDENTITY | jq .clientId | tr -d '"'
k apply -f aadpodidentity.yaml
k delete -f aadpodidentity.yaml
# Install Pod to Identity Binding on k8s cluster
# Note: Update AzureIdentity in aadpodidentitybinding.yaml with name output of the $IDENTITY variable.
echo $IDENTITY | jq .name | tr -d '"'
k apply -f aadpodidentitybinding.yaml
k delete -f aadpodidentitybinding.yaml
# Check out Sample Deployment Using AAD Pod Identity to ensure everything is working.
# Note: Update --subscriptionid --clientid and --resourcegroup in aadpodidentity-deployment.yaml accordingly.
echo $SUBID
echo $RG
echo $IDENTITY | jq .clientId | tr -d '"'
k apply -f aadpodidentity-deployment.yaml
k delete -f aadpodidentity-deployment.yaml
# Take note of the aadpodidentitybinding label as this determines which binding is used. 
k get po --show-labels -o wide
k logs $(kubectl get pod -l "app=demo" -o jsonpath='{.items[0].metadata.name}')
k exec $(kubectl get pod -l "app=demo" -o jsonpath='{.items[0].metadata.name}') -- /bin/bash -c env
k delete -f aadpodidentity-deployment.yaml

# Setup App Gateway Ingress
# Setup Helm First
kubectl create serviceaccount --namespace kube-system tiller-sa
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller-sa
helm init --tiller-namespace kube-system --service-account tiller-sa
helm repo add application-gateway-kubernetes-ingress https://azure.github.io/application-gateway-kubernetes-ingress/helm/
helm repo update
# Install and Setup Ingress
# Grant AAD Identity Access to App Gateway
ASSIGNEEID=$(echo $IDENTITY | jq .clientId | tr -d '"')
echo $ASSIGNEEID
APPGATEWAYSCOPEID=$(az network application-gateway show -g $RG -n $AGNAME | jq .id | tr -d '"')
echo $APPGATEWAYSCOPEID
ROLEAGWCONTRIB=$(az role assignment create --role Contributor --assignee $ASSIGNEEID --scope $APPGATEWAYSCOPEID)
ROLEAGWREADER=$(az role assignment create --role Reader --assignee $ASSIGNEEID --scope "/subscriptions/${SUBID}/resourcegroups/${RG}")
echo $ROLEAGWCONTRIB
echo $ROLEAGWREADER
# Note: Update subscriptionId, resourceGroup, name, identityResourceID, identityClientID and apiServerAddress
# in agw-helm-config.yaml file with the following.
echo $SUBID
echo $RG
echo $(az network application-gateway show -g $RG -n $AGNAME | jq .name | tr -d '"')
echo $IDENTITY | jq .id | tr -d '"'
echo $IDENTITY | jq .clientId | tr -d '"'
k cluster-info
helm install --name wragw -f agw-helm-config.yaml application-gateway-kubernetes-ingress/ingress-azure
k get po,svc,ingress,deploy,secrets
helm list
helm delete wragw --purge
# Add Web Front-End
k apply -f winterready-web.yaml
k apply -f winterready-ingress-web.yaml
k delete -f winterready-web.yaml
k delete -f winterready-ingress-web.yaml
# Add Worker Back-End
k create secret generic fruit-secret --from-literal=azurestorageaccountname=<YOUR STORAGE NAMEE> --from-literal=azurestorageaccountkey=<YOUR STORAGE KEY> 
# Note: Not needed if we use Storage Service Endpoints.
#az network firewall network-rule create -g $RG -f $FWNAME --collection-name 'aksfwnr' -n 'fileshare' --protocols 'TCP' --source-addresses '*' --destination-addresses '*' --destination-ports 444 --action allow --priority 200
# You can just go to the portal an add another rule to an existing collection as well.
k apply -f winterready-worker.yaml
k delete -f winterready-worker.yaml
k get po,svc,ingress,deploy,secrets

# Network Policy Setup
k get networkpolicy
# Network Policy
k exec -it centos -- curl 10.42.2.232
k apply -f np-denyall.yaml
k exec -it centos -- curl 10.42.2.232
# Check Browser - Zero Workers
k apply -f np-web-allow-ingress.yaml
k apply -f np-web-allow-worker.yaml
k get networkpolicy
k exec -it centos -- curl 10.42.2.232
# Cleanup if Desired
k delete -f np-denyall.yaml
k delete -f np-web-allow-worker.yaml
k delete -f np-web-allow-ingress.yaml

# Cleanup
# Cleanup K8s Contexts
k config delete-context $NAME
k config delete-context "${NAME}-admin"
k config delete-cluster $NAME
k config unset "users.clusterUser_${RG}_${NAME}"
k config unset "users.clusterAdmin_${RG}_${NAME}"
k config view
# Delete RG
az group delete --name $RG --no-wait -y