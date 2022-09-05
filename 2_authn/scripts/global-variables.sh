#!/bin/bash

# /!\ WARN /!\
# This script is meant to be loaded, not run

# minikube

export MINIKUBE_IP="$( minikube ip -p authn )"
echo "Minikube IP: ${MINIKUBE_IP}"

export MINIKUBE_DOMAIN="${MINIKUBE_IP}.nip.io"
echo "Minikube domain: ${MINIKUBE_DOMAIN}"

export MINIKUBE_FILES_PATH="$HOME/.minikube/files"
echo "Minikube files path: ${MINIKUBE_FILES_PATH}"

export MINIKUBE_CERTS_PATH="${MINIKUBE_FILES_PATH}/etc/ca-certificates"
echo "Minikube certs folder path: ${MINIKUBE_CERTS_PATH}"

export MINIKUBE_CERT_FILE_PATH="${MINIKUBE_CERTS_PATH}/openid-ca.pem"
echo "Minikube cert file path: ${MINIKUBE_CERT_FILE_PATH}"

# certs

export CA_CN="Local Dex Signer"
echo "CA common name: ${CA_CN}"

export CA_KEY_FILE="ssl/ca.key"
echo "CA key file path: ${CA_KEY_FILE}"

export CA_CERT_FILE="ssl/ca.pem"
echo "CA cert file path: ${CA_CERT_FILE}"

export SERVER_ORG="Local Dex"
echo "Server organisation: ${SERVER_ORG}"

export SERVER_KEY_FILE="ssl/key.pem"
echo "Server key file path: ${SERVER_KEY_FILE}"

export SERVER_CERT_REQUEST_FILE="ssl/domain.csr"
echo "Server cert request path: ${SERVER_CERT_REQUEST_FILE}"

export SERVER_CERT_FILE="ssl/cert.pem"
echo "Server cert file path: ${SERVER_CERT_FILE}"

# Look for openssl configuration file location depending on OS (macos and linux only supported)
export OPENSSL_CNF="/etc/pki/tls/openssl.cnf"   # linux
if [[ ! -f $OPENSSL_CNF ]]; then
	export OPENSSL_CNF="/etc/ssl/openssl.cnf"   # macos
fi
echo "OpenSSL cnf: ${OPENSSL_CNF}"

# dex

export DEX_DOMAIN="dex.${MINIKUBE_DOMAIN}"
echo "Dex domain: ${DEX_DOMAIN}"

export DEX_NAMESPACE="dex"
echo "Dex namespace: ${DEX_NAMESPACE}"

# INFO: include port number but not http:// or https://
export DEX_HOST="${DEX_DOMAIN}:32000"
echo "Dex host: ${DEX_HOST}"

# WARN: do not include port number and http:// or https://
export DEX_K8S_AUTH_HOST="dex-k8s-authenticator.${MINIKUBE_IP}.nip.io"
echo "Dex k8s authenticator host: ${DEX_K8S_AUTH_HOST}"

export DEX_K8S_AUTH_NAME="example-app"
echo "Dex k8s authenticator name: ${DEX_K8S_AUTH_NAME}"

# INFO: randomly generated
export DEX_K8S_AUTH_SECRET="ZXhhbXBsZS1hcHAtc2VjcmV0"
echo "Dex k8s authenticator secret: ${DEX_K8S_AUTH_SECRET}"

export DEX_K8S_CLUSTER="demo"
echo "Dex k8s cluster: ${DEX_K8S_CLUSTER}"

# dns

# INFO: corresponding configurations in yaml/dex.yaml/ConfigMap
export DNS_ENTRIES=DNS:${DEX_DOMAIN},DNS:*.${DEX_DOMAIN},DNS:*.sharded.${DEX_DOMAIN}
echo "DNS entries: ${DNS_ENTRIES}"

# dex-k8s-auth

export K8S_CA_PEM=$(\
	kubectl config view --minify --flatten -o json \
	| jq -r '.clusters[] | select(.name == "'$(kubectl config current-context)'") | .cluster."certificate-authority-data"' \
	| base64 -D \
	| sed 's/^/        /')
echo "K8s ca pem: ${K8S_CA_PEM}"

export TRUSTED_ROOT_CA=$(cat ssl/ca.pem | sed 's/^/        /')
echo "Trusted root ca: ${TRUSTED_ROOT_CA}"

# ldap

export OPENLDAP_NAMESPACE=openldap
echo "OpenLDAP namespace: ${OPENLDAP_NAMESPACE}"

# INFO: include port but not http:// or https://
export LDAP_HOST="openldap.${MINIKUBE_IP}.nip.io:32500"
echo "LDAP host: ${LDAP_HOST}"

export LDAP_ADMIN_USER_DN="cn=admin,dc=example,dc=org"
echo "LDAP admin user dn: ${LDAP_ADMIN_USER_DN}"

export LDAP_ADMIN_USERNAME="admin"
echo "LDAP admin username: ${LDAP_ADMIN_USERNAME}"

export LDAP_ADMIN_PASSWORD="adminpassword"
echo "LDAP admin password: ${LDAP_ADMIN_PASSWORD}"
