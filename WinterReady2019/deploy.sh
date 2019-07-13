#!/bin/bash

# Including DemoMagic
. demo-magic.sh

# Defining Type Speed
TYPE_SPEED=20

# Defining Custom prompt
DEMO_PROMPT="${green2}\u@\H${WHITE}:${blue2}\w${yellow}$ "


AKS_NAME=readydemo

# Setup
clear
kctx ${AKS_NAME} > /dev/null


p "helm upgrade --install data-api charts/data-api --namespace hackfest"
helm upgrade --install data-api ~/workbench/kubernetes-hackfest/charts/data-api --namespace hackfest --reset-values

p "helm upgrade --install quakes-api charts/quakes-api --namespace hackfest"
helm upgrade --install quakes-api ~/workbench/kubernetes-hackfest/charts/quakes-api --namespace hackfest --reset-values

p "helm upgrade --install weather-api charts/weather-api --namespace hackfest"
helm upgrade --install weather-api ~/workbench/kubernetes-hackfest/charts/weather-api --namespace hackfest --reset-values

p "helm upgrade --install flights-api charts/flights-api --namespace hackfest"
helm upgrade --install flights-api ~/workbench/kubernetes-hackfest/charts/flights-api --namespace hackfest --reset-values

p "helm upgrade --install service-tracker-ui charts/service-tracker-ui --namespace hackfest"
helm upgrade --install service-tracker-ui ~/workbench/kubernetes-hackfest/charts/service-tracker-ui --namespace hackfest --reset-values

pe "kubectl get pod,svc -n hackfest"

