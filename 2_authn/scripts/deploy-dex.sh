#!/bin/bash


# /!\ WARN /!\
# Rembemer to run this script from the same folder as the README.md


# settings
set -eo pipefail


# variables
# INFO: in case this script has to be executed all alone
# echo "Load environment variables"
# . ./scripts/global-variables.sh
echo "Dex namespace: ${DEX_NAMESPACE}"
echo "Dex host: ${DEX_HOST}"
echo "Dex k8s authenticator host: ${DEX_K8S_AUTH_HOST}"
echo "Dex k8s authenticator name: ${DEX_K8S_AUTH_NAME}"
echo "Dex k8s authenticator secret: ${DEX_K8S_AUTH_SECRET}"
echo "LDAP host: ${LDAP_HOST}"
echo "LDAP admin user dn: ${LDAP_ADMIN_USER_DN}"
echo "LDAP admin password: ${LDAP_ADMIN_PASSWORD}"


# actions
echo "Prepare Dex YAML manifest"
envsubst < ./yaml/dex_template.yaml > ./yaml/dex.yaml

echo "Deploy Dex"
kubectl create namespace ${DEX_NAMESPACE}
kubectl create secret tls dex.tls \
	-n ${DEX_NAMESPACE} \
	--cert=ssl/cert.pem --key=ssl/key.pem
kubectl apply -n ${DEX_NAMESPACE} -f ./yaml/dex.yaml
sleep 5
kubectl wait pod -n ${DEX_NAMESPACE} -l app=dex --for=condition=Ready
sleep 1
kubectl get pods -n ${DEX_NAMESPACE}
# expected output
# NAME                                     READY   STATUS    RESTARTS   AGE
# dex-7f5b5fcb4c-2rhk9                     1/1     Running   0          97m
