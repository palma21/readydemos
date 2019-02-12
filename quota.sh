#!/bin/bash

# Including DemoMagic
. demo-magic.sh

# Defining Type Speed
TYPE_SPEED=20

# Defining Custom prompt
DEMO_PROMPT="${green2}\u@\H${WHITE}:${blue2}\w${yellow}$ "

LOCATION=westus
RG_NAME=readywinter-rg
AKS_NAME=readywinter


clear

pe "az aks get-credentials -n ${AKS_NAME} -g ${RG_NAME}"


pe "k get nodes"

p "k apply -f create-namespaces.yaml"
k apply -f ~/workbench/kubernetes-hackfest/labs/create-aks-cluster/create-namespaces.yaml

pe "k get ns"

# Assign Resource quotas and limits to the Namespaces
p "k apply -f namespace-quotas.yaml"
k apply -f ~/workbench/kubernetes-hackfest/labs/create-aks-cluster/namespace-quotas.yaml

pe "k run nginx-quotatest --image=nginx --restart=Never --replicas=1 --port=80 --requests='cpu=250m,memory=256Mi' --limits='cpu=500m,memory=512Mi' -n dev"

pe "k run nginx-test --image=nginx --restart=Never --replicas=1 --port=80 -n dev"

pe "clear"

pe "k describe ns dev"

# Assing limits to to the containers and PVCs
p "k apply -f namespace-limitranges.yaml"
k apply -f ~/workbench/kubernetes-hackfest/labs/create-aks-cluster/namespace-limitranges.yaml

pe "k run nginx-test2 --image=nginx --restart=Never --replicas=1 --port=80 -n dev"

pe "clear"

pe "k describe ns dev"

pe "k run nginx-quotatest --image=nginx --restart=Never --replicas=1 --port=80 --limits='cpu=1,memory=1Gi' -n dev"

# Clean up
kubectl delete -f  ~/workbench/kubernetes-hackfest/labs/create-aks-cluster/namespace-limitranges.yaml > /dev/null
kubectl delete -f  ~/workbench/kubernetes-hackfest/labs/create-aks-cluster/namespace-quotas.yaml > /dev/null
# kubectl delete po nginx-limittest nginx-quotatest -n dev > /dev/null
kubectl delete -f ~/workbench/kubernetes-hackfest/labs/create-aks-cluster/create-namespaces.yaml > /dev/null

