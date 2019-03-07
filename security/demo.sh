#!/bin/bash

# Pre-requisites
# 1. VNET, subnets and firewall + rules setup
# 2. Cluster created and integrated with AAD
# 3. AAD Pod Identity setup
# 4. App Gateway created
# 5. Network policy default deny setup

# Get Nodes
k get nodes

# DEMO 1
# Test Firewall
k exec -it centos -- /bin/bash
curl www.ubuntu.com
curl superman.com
exit

# DEMO2
# AAD Pod Identity talking to VMs
k logs demo-6c8fb4f787-qtvrm | grep 'succesfully made GET on instance metadata'
k describe po demo-6c8fb4f787-qtvrm | grep -i secret

# DEMO 3
# Add Ingress Controller + Pod Identity
k get po,svc,ingress,deploy,secrets
k exec -it centos -- curl 10.42.1.232
k logs $(kubectl get pod -l "app=ingress-azure" -o jsonpath='{.items[0].metadata.name}') | grep 'AuthorizationFailed'
az role assignment list --assignee "${ASSIGNEEID}" --all -o table
az role assignment create --role Contributor --assignee "${ASSIGNEEID}" --scope "/subscriptions/${SUBID}/resourceGroups/${RG}/providers/Microsoft.Network/applicationGateways/${AGNAME}"
az role assignment create --role Reader --assignee "${ASSIGNEEID}" --scope "/subscriptions/${SUBID}/resourcegroups/${RG}"
az role assignment list --assignee "${ASSIGNEEID}" --all -o table
k delete po $(kubectl get pod -l "app=ingress-azure" -o jsonpath='{.items[0].metadata.name}')
k logs $(kubectl get pod -l "app=ingress-azure" -o jsonpath='{.items[0].metadata.name}')
k apply -f winterready-ingress-web.yaml
# Check Browser - Working

# Reset Identity for DEMO 3
k delete -f winterready-ingress-web.yaml
az role assignment delete --assignee "${ASSIGNEEID}" --scope "/subscriptions/${SUBID}/resourceGroups/${RG}/providers/Microsoft.Network/applicationGateways/${AGNAME}"
az role assignment delete --assignee "${ASSIGNEEID}" --scope "/subscriptions/${SUBID}/resourcegroups/${RG}"
az role assignment list --assignee "${ASSIGNEEID}" --all -o table
k delete po $(kubectl get pod -l "app=ingress-azure" -o jsonpath='{.items[0].metadata.name}')
# Check Browser - Bad Gateway
k get po,svc,ingress,deploy,secrets
k logs $(kubectl get pod -l "app=ingress-azure" -o jsonpath='{.items[0].metadata.name}')

# DEMO 4
# Network Policy
k exec -it centos -- curl 10.42.1.232
k apply -f np-denyall.yaml
k exec -it centos -- curl 10.42.1.232
# Check Browser - Zero Workers
k apply -f np-web-allow-ingress.yaml
k apply -f np-web-allow-worker.yaml
k get networkpolicy
k exec -it centos -- curl 10.42.1.232
# Check Browser - Working

# Reset DEMO 4
k delete -f np-denyall.yaml
k delete -f np-web-allow-worker.yaml
k delete -f np-web-allow-ingress.yaml
k get po,svc,ingress,deploy,secrets,networkpolicy

# Cleanup
# Cleanup Identity
echo $ROLEREADER
echo $ROLEMIC
az role assignment list --assignee "${ASSIGNEEID}" --all -o table
az role assignment delete --assignee "${ASSIGNEEID}" --scope "/subscriptions/${SUBID}/resourceGroups/${RG}/providers/Microsoft.Network/applicationGateways/${AGNAME}"
az role assignment delete --assignee "${ASSIGNEEID}" --scope "/subscriptions/${SUBID}/resourcegroups/${RG}"
k delete -f winterready-ingress-web.yaml
k delete po $(kubectl get pod -l "app=ingress-azure" -o jsonpath='{.items[0].metadata.name}')
k apply -f winterready-ingress-web.yaml
k get po
# Cleanup K8s Contexts
kubectx khaksmicro
k config delete-context $NAME
k config delete-context "${NAME}-admin"
k config delete-cluster $NAME
k config unset "users.clusterUser_${RG}_${NAME}"
k config unset "users.clusterAdmin_${RG}_${NAME}"
k config view
# Delete RG
az group delete --name $RG --no-wait -y