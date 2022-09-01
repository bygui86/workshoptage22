#!/bin/bash


# /!\ WARN /!\
# Rembemer to run this script from the same folder as the README.md


# settings
set -eo pipefail


# variables
# INFO: no need for global environment variables


# actions
echo "Cleanup RBAC dir"
rm -rf ./rbac && mkdir -p ./rbac/dex && mkdir -p ./rbac/ldap

echo "Create Namespaces and RBAC for Dex static users"
export AUTHN_SOURCE="dex-static"
for i in {1..5}; do
	export NAMESPACE="user${i}"
	echo "Namespace: ${NAMESPACE}"
	export USER_PREFIX="user${i}"
	export USER="${USER_PREFIX}@dex.io"
	echo "User: ${USER}"
	kubectl create namespace ${NAMESPACE}
	kubectl label namespace ${NAMESPACE} authn-source=${AUTHN_SOURCE}
	sleep 1
	envsubst < ./yaml/rbac-user_template.yaml > ./rbac/dex/${USER_PREFIX}.yaml
	kubectl apply -n ${NAMESPACE} -f ./rbac/dex/${USER_PREFIX}.yaml
done

sleep 1

echo "Create RBAC for Dex static 'admin'"
export USER_PREFIX=""   # INFO to be sure it's empty
export USER_PREFIX="admin"
export USER=""   # INFO to be sure it's empty
export USER="${USER_PREFIX}@dex.io"
envsubst < ./yaml/rbac-admin_template.yaml > ./rbac/dex/${USER_PREFIX}.yaml
kubectl apply -f ./rbac/dex/${USER_PREFIX}.yaml

sleep 1

echo "Create Namespaces and RBAC for LDAP users"
export AUTHN_SOURCE=""   # INFO to be sure it's empty
export AUTHN_SOURCE="ldap"
for i in {1..2}; do
	export NAMESPACE=""   # INFO to be sure it's empty
	export NAMESPACE="user0${i}"
	echo "Namespace: ${NAMESPACE}"
	export USER=""   # INFO to be sure it's empty
	export USER="user0${i}"
	echo "User: ${USER}"
	kubectl create namespace ${NAMESPACE}
	kubectl label namespace ${NAMESPACE} authn-source=${AUTHN_SOURCE}
	sleep 1
	envsubst < ./yaml/rbac-user_template.yaml > ./rbac/ldap/${USER}.yaml
	kubectl apply -n ${NAMESPACE} -f ./rbac/ldap/${USER}.yaml
done

sleep 1

echo "List Dex static Namespaces"
kubectl get namespaces -l authn-source=${AUTHN_SOURCE}
echo "List Dex static RoleBindings"
kubectl get rolebindings -A -l authn-source=${AUTHN_SOURCE}
echo "List Dex static ClusterRoleBindings"
kubectl get clusterrolebindings -l authn-source=${AUTHN_SOURCE}
echo "List LDAP Namespaces"
kubectl get namespaces -l authn-source=${AUTHN_SOURCE}
echo "List LDAP RoleBindings"
kubectl get rolebindings -A -l authn-source=${AUTHN_SOURCE}
# echo "List all namespaces"
# kubectl get namespaces
