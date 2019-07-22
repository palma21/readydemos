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
PREFIX="policy-demo"
RG="aks-security-demo-rg"
LOC="westus2"
AKSNAME="${PREFIX}"
AZURE_ACCOUNT_NAME="JPalma-Internal"

pe "kctx policy-demo-admin"

p "az aks enable-addons --addons azure-policy --name $AKSNAME --resource-group $RG"

pe "k get pods -n kube-system"

# Only works on WSL
chrome "https://ms.portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyMenuBlade/Overview"

pe "k apply -f test-pod.yaml"

pe "k run --generator=run-pod/v1 jpalma-hello --image=jpalma.azurecr.io/helloworld:v1"

pe "k run --generator=run-pod/v1 mekint-hello --image=mekint.azurecr.io/helloworld:v1"

pe "clear"

# Clean up

k delete pod jpalma-hello > /dev/null
