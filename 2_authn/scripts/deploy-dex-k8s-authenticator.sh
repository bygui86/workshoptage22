#!/bin/bash


# /!\ WARN /!\
# Rembemer to run this script from the same folder as the README.md


# settings
set -eo pipefail


# variables
# INFO: in case this script has to be executed all alone
# echo "Load environment variables"
# . ./scripts/global-variables.sh
echo "Minikube IP: ${MINIKUBE_IP}"
echo "Dex namespace: ${DEX_NAMESPACE}"
echo "Dex host: ${DEX_HOST}"
echo "Dex k8s authenticator host: ${DEX_K8S_AUTH_HOST}"
echo "Dex k8s authenticator name: ${DEX_K8S_AUTH_NAME}"
echo "Dex k8s authenticator secret: ${DEX_K8S_AUTH_SECRET}"
echo "Dex k8s cluster: ${DEX_K8S_CLUSTER}"
echo "K8s ca pem: ${K8S_CA_PEM}"
echo "Trusted root ca: ${TRUSTED_ROOT_CA}"


# actions
echo "Prepare dex-k8s-authenticator YAML manifest"
envsubst < ./yaml/dex-k8s-authenticator_template.yaml > ./yaml/dex-k8s-authenticator.yaml

echo "Deploy dex-k8s-authenticator"
kubectl apply -n ${DEX_NAMESPACE} -f ./yaml/dex-k8s-authenticator.yaml
sleep 5
kubectl wait pod -n ${DEX_NAMESPACE} -l app=dex-k8s-authenticator --for=condition=Ready
sleep 1
kubectl get pods -n ${DEX_NAMESPACE}
# expected output
# NAME                                     READY   STATUS    RESTARTS   AGE
# dex-7f5b5fcb4c-2rhk9                     1/1     Running   0          97m
# dex-k8s-authenticator-7b44c88bb4-glx6q   1/1     Running   0          54s

echo "Access dex-k8s-authenticator and try to login with Email"
echo "email: 'user1@dex.io'"
echo "password: 'password'"
open http://${DEX_K8S_AUTH_HOST}
