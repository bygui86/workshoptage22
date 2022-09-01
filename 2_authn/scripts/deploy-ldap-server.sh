#!/bin/bash


# /!\ WARN /!\
# Rembemer to run this script from the same folder as the README.md


# settings
set -eo pipefail


# variables
# INFO: in case this script has to be executed all alone
# echo "Load environment variables"
# . ./scripts/global-variables.sh
echo "OpenLDAP namespace: ${OPENLDAP_NAMESPACE}"
echo "LDAP admin username: ${LDAP_ADMIN_USERNAME}"
echo "LDAP admin password: ${LDAP_ADMIN_PASSWORD}"


# actions
echo "Prepare LDAP server YAML manifest"
envsubst < ./yaml/openldap_template.yaml > ./yaml/openldap.yaml

echo "Deploy LDAP server"
kubectl create namespace ${OPENLDAP_NAMESPACE}
kubectl apply -n ${OPENLDAP_NAMESPACE} -f ./yaml/openldap.yaml
sleep 5
kubectl wait pod -n ${OPENLDAP_NAMESPACE} -l app=openldap --for=condition=Ready
sleep 1
kubectl get pods -n ${OPENLDAP_NAMESPACE}
# expected output
# NAME                        READY   STATUS    RESTARTS   AGE
# openldap-57d4fdcd85-zv29m   1/1     Running   0          22s

echo "Access dex-k8s-authenticator and try to login with LDAP"
echo "username: 'user02'"
echo "password: 'password02'"
open http://${DEX_K8S_AUTH_HOST}
