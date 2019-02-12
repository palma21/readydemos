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
K8S_VERSION=1.12.4

pe "az group create -n ${RG_NAME} -l ${LOCATION}"

pe "az aks create -n ${AKS_NAME} -g ${RG_NAME} -k ${K8S_VERSION} -c 3 -a monitoring --enable-vmss"



