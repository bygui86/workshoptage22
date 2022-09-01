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
echo "Minikube domain: ${MINIKUBE_DOMAIN}"
echo "Minikube certs folder path: ${MINIKUBE_CERTS_PATH}"
echo "Minikube cert file path: ${MINIKUBE_CERT_FILE_PATH}"
echo "Dex domain: ${DEX_DOMAIN}"
echo "DNS entries: ${DNS_ENTRIES}"
echo "CA common name: ${CA_CN}"
echo "CA key file path: ${CA_KEY_FILE}"
echo "CA cert file path: ${CA_CERT_FILE}"
echo "Server organisation: ${SERVER_ORG}"
echo "Server key file path: ${SERVER_KEY_FILE}"
echo "Server cert request path: ${SERVER_CERT_REQUEST_FILE}"
echo "Server cert file path: ${SERVER_CERT_FILE}"
echo "OpenSSL cnf: ${OPENSSL_CNF}"


# actions
echo "Cleanup ssl dir"
rm -rf ./ssl && mkdir -p ./ssl

echo "Generate certificates"
openssl genrsa -out ${CA_KEY_FILE} 4096
openssl req \
	-new -x509 -nodes -key ${CA_KEY_FILE} -sha256 \
	-subj /CN="${CA_CN}" \
	-days 1024 \
	-reqexts SAN -extensions SAN \
	-config <(cat ${OPENSSL_CNF} <(printf "[SAN]\nbasicConstraints=critical, CA:TRUE\nkeyUsage=keyCertSign, cRLSign, digitalSignature")) \
	-outform PEM -out ${CA_CERT_FILE}
openssl genrsa -out ${SERVER_KEY_FILE} 2048
openssl req \
	-new -sha256 -key ${SERVER_KEY_FILE} \
	-subj "/O=${SERVER_ORG}/CN=${MINIKUBE_DOMAIN}" \
	-reqexts SAN \
	-config <(cat ${OPENSSL_CNF} <(printf "\n[SAN]\nsubjectAltName=${DNS_ENTRIES}\nbasicConstraints=critical, CA:FALSE\nkeyUsage=digitalSignature, keyEncipherment, keyAgreement, dataEncipherment\nextendedKeyUsage=serverAuth")) \
	-outform PEM -out ${SERVER_CERT_REQUEST_FILE}
openssl x509 \
	-req -in ${SERVER_CERT_REQUEST_FILE} \
	-CA ${CA_CERT_FILE} -CAkey ${CA_KEY_FILE} -CAcreateserial \
	-days 365 \
	-sha256 \
	-extfile <(printf "subjectAltName=${DNS_ENTRIES}\nbasicConstraints=critical, CA:FALSE\nkeyUsage=digitalSignature, keyEncipherment, keyAgreement, dataEncipherment\nextendedKeyUsage=serverAuth") \
	-outform PEM -out ${SERVER_CERT_FILE}
cat ${SERVER_CERT_FILE} ${CA_CERT_FILE} > ssl/kube.crt

echo "List generated certificates"
ls -lh ./ssl

echo "Copy certs to Minikube shared folder"
mkdir -p ${MINIKUBE_CERTS_PATH}
cp ${CA_CERT_FILE} ${MINIKUBE_CERT_FILE_PATH}
echo "List Minikube certificates"
ls -lh ${MINIKUBE_CERT_FILE_PATH}
