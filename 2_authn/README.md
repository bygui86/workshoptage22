
# Authentication - Minikube with Dex

`(i) INFO` From now on please use always the same terminal window/tab.

## Preliminary steps

```bash
cd 2_authn/
```

## 1. Start Minikube

```bash
# Start Minikube (this may take few minutes)
# /!\ WARN /!\
# Do not use Minikube with Docker or QEMU as a driver for this demo. 
# It might cause problems with ingress, DNS or K8s apiserver authentication.
# Please use VirtualBox.
minikube --driver virtualbox --cpus 4 --memory 8192 --disk-size 20g start -p authn

# Enable Minikube 'ingress' addon (this may take some seconds)
minikube addons enable ingress -p authn
minikube addons list -p authn
```

## 2. Generate certs

`(i) INFO` This step requires `OpenSSL` installed. Please see [here](https://www.openssl.org/source/).

```bash
# Cleanup ssl dir
rm -rf ./ssl && mkdir -p ./ssl

# Prepare some variables
export MINIKUBE_IP="$( minikube ip -p authn )"
echo "Minikube IP: ${MINIKUBE_IP}"
export MINIKUBE_DOMAIN="${MINIKUBE_IP}.nip.io"
echo "Minikube domain: ${MINIKUBE_DOMAIN}"
export DEX_DOMAIN="dex.${MINIKUBE_DOMAIN}"
echo "Dex domain: ${DEX_DOMAIN}"
export DNS_ENTRIES=DNS:${DEX_DOMAIN},DNS:*.${DEX_DOMAIN},DNS:*.sharded.${DEX_DOMAIN}   # INFO: corresponding configurations in dex.yaml/ConfigMap
echo "DNS entries: ${DNS_ENTRIES}"
export CA_CN="Local Dex Signer"
echo "CA-CN: ${CA_CN}"
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

# Generate certificates
openssl genrsa -out $CA_KEY_FILE 4096
openssl req \
	-new -x509 -nodes -key $CA_KEY_FILE -sha256 \
	-subj /CN="${CA_CN}" \
	-days 1024 \
	-reqexts SAN -extensions SAN \
	-config <(cat ${OPENSSL_CNF} <(printf "[SAN]\nbasicConstraints=critical, CA:TRUE\nkeyUsage=keyCertSign, cRLSign, digitalSignature")) \
	-outform PEM -out $CA_CERT_FILE
openssl genrsa -out $SERVER_KEY_FILE 2048
openssl req \
	-new -sha256 -key $SERVER_KEY_FILE \
	-subj "/O=${SERVER_ORG}/CN=${MINIKUBE_DOMAIN}" \
	-reqexts SAN \
	-config <(cat $OPENSSL_CNF <(printf "\n[SAN]\nsubjectAltName=${DNS_ENTRIES}\nbasicConstraints=critical, CA:FALSE\nkeyUsage=digitalSignature, keyEncipherment, keyAgreement, dataEncipherment\nextendedKeyUsage=serverAuth")) \
	-outform PEM -out $SERVER_CERT_REQUEST_FILE
openssl x509 \
	-req -in $SERVER_CERT_REQUEST_FILE \
	-CA $CA_CERT_FILE -CAkey $CA_KEY_FILE -CAcreateserial \
	-days 365 \
	-sha256 \
	-extfile <(printf "subjectAltName=${DNS_ENTRIES}\nbasicConstraints=critical, CA:FALSE\nkeyUsage=digitalSignature, keyEncipherment, keyAgreement, dataEncipherment\nextendedKeyUsage=serverAuth") \
	-outform PEM -out $SERVER_CERT_FILE
cat $SERVER_CERT_FILE $CA_CERT_FILE > ./ssl/kube.crt

# List generated certificates
ls -lh ./ssl

# Copy certs to Minikube shared folder
export MINIKUBE_CERTS_PATH="/etc/ca-certificates"
export MINIKUBE_CERT_FILE_PATH="${MINIKUBE_CERTS_PATH}/openid-ca.pem"
mkdir -p $HOME/.minikube/files${MINIKUBE_CERTS_PATH}
cp ${CA_CERT_FILE} $HOME/.minikube/files${MINIKUBE_CERT_FILE_PATH}
ls -lh $HOME/.minikube/files${MINIKUBE_CERT_FILE_PATH}
cat $HOME/.minikube/files${MINIKUBE_CERT_FILE_PATH}
```

## 3. Deploy Dex

```bash
# Prepare some variables
export DEX_NAMESPACE="dex"
echo "Dex namespace: ${DEX_NAMESPACE}"
export DEX_HOST="${DEX_DOMAIN}:32000"   # INFO: include port, do not include https://
echo "Dex host: ${DEX_HOST}"
export LDAP_HOST="openldap.${MINIKUBE_IP}.nip.io:32500"   # INFO: include port, do not include http:// or https://
echo "LDAP host: ${LDAP_HOST}"
export LDAP_ADMIN_USER_DN="cn=admin,dc=example,dc=org"
echo "LDAP admin user dn: ${LDAP_ADMIN_USER_DN}"
export LDAP_ADMIN_PASSWORD="adminpassword"
echo "LDAP admin password: ${LDAP_ADMIN_PASSWORD}"
export DEX_K8S_AUTH_HOST="dex-k8s-authenticator.${MINIKUBE_IP}.nip.io"   # WARN: do not include port, do not include http://
echo "Dex k8s authenticator host: ${DEX_K8S_AUTH_HOST}"
export DEX_K8S_AUTH_NAME="example-app"
echo "Dex k8s authenticator name: ${DEX_K8S_AUTH_NAME}"
export DEX_K8S_AUTH_SECRET="ZXhhbXBsZS1hcHAtc2VjcmV0"   # INFO: randomly generated
echo "Dex k8s authenticator secret: ${DEX_K8S_AUTH_SECRET}"

# Prepare Dex YAML manifest
envsubst < ./yaml/dex_template.yaml > ./yaml/dex.yaml

# Deploy Dex
kubectl create namespace ${DEX_NAMESPACE}
kubectl create secret tls dex.tls \
	-n ${DEX_NAMESPACE} \
	--cert=./ssl/cert.pem --key=./ssl/key.pem
	kubectl apply -n ${DEX_NAMESPACE} -f ./yaml/dex.yaml
sleep 5
kubectl wait pod -n ${DEX_NAMESPACE} -l app=dex --for=condition=Ready
sleep 1
kubectl get pods -n ${DEX_NAMESPACE}
# expected output
# NAME                                     READY   STATUS    RESTARTS   AGE
# dex-7f5b5fcb4c-2rhk9                     1/1     Running   0          97m
```

## 4. Configure Minikube apiserver authN with Dex

```bash
# Prepare some variables
# DEX_DOMAIN already set
echo "Dex domain: ${DEX_DOMAIN}" && \
# DEX_K8S_AUTH_NAME already set
echo "Dex k8s authenticator name: ${DEX_K8S_AUTH_NAME}" && \
# MINIKUBE_CERT_FILE_PATH already set
echo "Minikube cert file path: ${MINIKUBE_CERT_FILE_PATH}"

# Reconfigure Minikube apiserver authentication
minikube \
	--extra-config="apiserver.oidc-issuer-url=https://${DEX_DOMAIN}:32000" \
	--extra-config="apiserver.oidc-client-id=${DEX_K8S_AUTH_NAME}" \
	--extra-config="apiserver.oidc-ca-file=${MINIKUBE_CERT_FILE_PATH}" \
	--extra-config="apiserver.oidc-username-claim=email" \
	--extra-config="apiserver.oidc-groups-claim=groups" \
	start -p authn

# Wait for K8s apiserver to be ready
kubectl wait pod -n kube-system -l component=kube-apiserver --for=condition=Ready
sleep 1
kubectl get pods -n kube-system
# (i) INFO: if an error like "The connection to the server 192.168.59.100:8443 was refused - did you specify the right host or port?" occurs, just wait for some seconds and retry
# expected output
# NAME                               READY   STATUS    RESTARTS        AGE
# coredns-6d4b75cb6d-lzmgt           1/1     Running   4 (26h ago)     28h
# etcd-minikube                      1/1     Running   3 (26h ago)     28h
# kube-apiserver-minikube            1/1     Running   2 (26h ago)     27h
# kube-controller-manager-minikube   1/1     Running   1 (26h ago)     27h
# kube-proxy-pf6gw                   1/1     Running   3 (26h ago)     28h
# kube-scheduler-minikube            1/1     Running   3 (26h ago)     28h
# storage-provisioner                1/1     Running   5 (3h22m ago)   28h
```

## 6. Deploy dex-k8s-authenticator static client

`PLEASE NOTE`: Deploy in the same namespace as Dex.

```bash
# Prepare some variables
export K8S_CA_PEM=$(\
	kubectl config view --minify --flatten -o json \
	| jq -r '.clusters[] | select(.name == "'$(kubectl config current-context)'") | .cluster."certificate-authority-data"' \
	| base64 -D \
	| sed 's/^/        /')
echo "K8s ca pem: ${K8S_CA_PEM}"
export TRUSTED_ROOT_CA=$(cat ssl/ca.pem | sed 's/^/        /')
echo "Trusted root ca: ${TRUSTED_ROOT_CA}"
# DEX_NAMESPACE already set
echo "Dex namespace: ${DEX_NAMESPACE}"
# DEX_HOST already set
echo "Dex host: ${DEX_HOST}"
# DEX_K8S_AUTH_HOST already set
echo "Dex k8s authenticator host: ${DEX_K8S_AUTH_HOST}"
# DEX_K8S_AUTH_NAME already set
echo "Dex k8s authenticator name: ${DEX_K8S_AUTH_NAME}"
# DEX_K8S_AUTH_SECRET already set
echo "Dex k8s authenticator secret: ${DEX_K8S_AUTH_SECRET}"
export DEX_K8S_CLUSTER="demo"
echo "Dex k8s cluster: ${DEX_K8S_CLUSTER}"
# MINIKUBE_IP already set
echo "Minikube IP: ${MINIKUBE_IP}"

# Prepare dex-k8s-authenticator YAML manifest
envsubst < ./yaml/dex-k8s-authenticator_template.yaml > ./yaml/dex-k8s-authenticator.yaml

# Deploy dex-k8s-authenticator
kubectl apply -n ${DEX_NAMESPACE} -f ./yaml/dex-k8s-authenticator.yaml
sleep 5
kubectl wait pod -n ${DEX_NAMESPACE} -l app=dex-k8s-authenticator --for=condition=Ready
sleep 1
kubectl get pods -n ${DEX_NAMESPACE}
# expected output
# NAME                                     READY   STATUS    RESTARTS   AGE
# dex-7f5b5fcb4c-2rhk9                     1/1     Running   0          97m
# dex-k8s-authenticator-7b44c88bb4-glx6q   1/1     Running   0          54s

# Access dex-k8s-authenticator and try to login with Email
# email: 'user1@dex.io'
# password: 'password'
open http://${DEX_K8S_AUTH_HOST}
```

## 7. Deploy LDAP server

```bash
# Prepare some variables
export OPENLDAP_NAMESPACE=openldap
echo "OpenLDAP namespace: ${OPENLDAP_NAMESPACE}"
export LDAP_ADMIN_USERNAME="admin"
echo "LDAP admin username: ${LDAP_ADMIN_USERNAME}"
# LDAP_ADMIN_PASSWORD already set
echo "LDAP admin password: ${LDAP_ADMIN_PASSWORD}"

# Prepare LDAP server YAML manifest
envsubst < ./yaml/openldap_template.yaml > ./yaml/openldap.yaml

# Deploy LDAP server
kubectl create namespace ${OPENLDAP_NAMESPACE}
kubectl apply -n ${OPENLDAP_NAMESPACE} -f ./yaml/openldap.yaml
sleep 5
kubectl wait pod -n ${OPENLDAP_NAMESPACE} -l app=openldap --for=condition=Ready
sleep 1
kubectl get pods -n ${OPENLDAP_NAMESPACE}
# expected output
# NAME                        READY   STATUS    RESTARTS   AGE
# openldap-57d4fdcd85-zv29m   1/1     Running   0          22s

# Access dex-k8s-authenticator and try to login with LDAP
# username: 'user02'
# password: 'password02'
open http://${DEX_K8S_AUTH_HOST}
```

## 8. Create Namespaces and RBAC

```bash
# Cleanup RBAC dir
rm -rf rbac && mkdir -p rbac/dex && mkdir -p rbac/ldap

# Create Namespaces and RBAC for Dex static users
for i in {1..5}; do
	export AUTHN_SOURCE="dex-static"
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

# Create RBAC for Dex static 'admin'
export USER_PREFIX="admin"
export USER="${USER_PREFIX}@dex.io"
envsubst < ./yaml/rbac-admin_template.yaml > ./rbac/dex/${USER_PREFIX}.yaml
kubectl apply -f ./rbac/dex/${USER_PREFIX}.yaml

# Create Namespaces and RBAC for LDAP users
for i in {1..2}; do
	export AUTHN_SOURCE="ldap"
	export NAMESPACE="user0${i}"
	echo "Namespace: ${NAMESPACE}"
	export USER="user0${i}"
	echo "User: ${USER}"
	kubectl create namespace ${NAMESPACE}
	kubectl label namespace ${NAMESPACE} authn-source=${AUTHN_SOURCE}
	sleep 1
	envsubst < ./yaml/rbac-user_template.yaml > ./rbac/ldap/${USER}.yaml
	kubectl apply -n ${NAMESPACE} -f ./rbac/ldap/${USER}.yaml
done

# List Dex static Namespaces
kubectl get namespaces -l authn-source=${AUTHN_SOURCE}
# List Dex static RoleBindings
kubectl get rolebindings -A -l authn-source=${AUTHN_SOURCE}
# List Dex static ClusterRoleBindings
kubectl get clusterrolebindings -l authn-source=${AUTHN_SOURCE}

# List LDAP Namespaces
kubectl get namespaces -l authn-source=${AUTHN_SOURCE}
# List LDAP RoleBindings
kubectl get rolebindings -A -l authn-source=${AUTHN_SOURCE}
```

## 9. Login as a user

```bash
# [OPTIONAL] Backup kubeconfig
cp ${HOME}/.kube/config ${HOME}/.kube/config_bak

# Access dex-k8s-authenticator and try to login with Email
# email: 'user1@dex.io'
# password: 'password'
open http://$DEX_K8S_AUTH_HOST

# Select your OS and follow steps to create certificates and configure your local kubectl

# example of command to create certificate
# mkdir -p ${HOME}/.kube/certs/demo/ && cat << EOF > ${HOME}/.kube/certs/demo/k8s-ca.crt
# -----BEGIN CERTIFICATE-----
# MIIDBjCCAe6gAwIBAgIBATANBgkqhkiG9w0BAQsFADAVMRMwEQYDVQQDEwptaW5p
# a3ViZUNBMB4XDTIwMTEwOTE2MzkyM1oXDTMwMTEwODE2MzkyM1owFTETMBEGA1UE
# AxMKbWluaWt1YmVDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALT8
# M0h94VdV/cpiO93bdyAU2WUXuxptb+s40JveAHznDd2S6oEL99t/CnxOfL58rtm0
# 1dWKdY1IRdUU8LV/bGTzSPJGXg9civIChflmMYai7sDPtbvg6YaDNcZ4mKI7v9dt
# AnGjKUZUzvBdem8pQEaQ3eDieF34CI6GfcZlpQ/n7Fe4ahzd4BXvwOs0UQ6N0p8s
# a4T3ZAfYOgadk3MWmRTgXe5NdvsVbhtGEH9pyM+t1+3D7ULxaNsAN2/mqiyZYGya
# 2LFgV3RM77ezuG1o8/ownbzQfleyY4vDxTXpIKhIvuBudsdP27gGxEHCr9OwG54I
# r+IQSq0oXTPZpSnI9/0CAwEAAaNhMF8wDgYDVR0PAQH/BAQDAgKkMB0GA1UdJQQW
# MBQGCCsGAQUFBwMCBggrBgEFBQcDATAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQW
# BBQdkQOnBCDLQ9BnlCKsgdMLp6Rh5TANBgkqhkiG9w0BAQsFAAOCAQEAEqA3Pe/7
# fX5l0r5QyRiVT72+x3hl47x3qYutxRL5FqVAB3tT38FJMFAWWQ2Jedyl7JMsoTUo
# RbLAIrB2dfuB4FjrbfLq8FiHD4wkY+rzGxWe6ZKtwdgSAdHk1owZlzMYRAxCAjC9
# Bz4MLO8A2T0UPKyR3WvcZQQKSJ/x0oKpOsSR78luOpNNlrSAEDp6Xyr4pu7whEU4
# 3HzYXPDa/QRRQX3NroA+f5VE8cfSaGZyzTIU1fRFjY1qOaro0nBuv0Dy28QGWYqt
# J1H0tIEQ0gK03fxYqe71/5ECVdy3z5WS/oO4tRHwuWMWbp45in8PN4xPheuGKh36
# G6a55G0mOGRKlw==
# -----END CERTIFICATE-----
# EOF

# List .kube/certs
ls -lh ${HOME}/.kube/certs/${DEX_K8S_CLUSTER}

# example of command to configure kubectl
# kubectl config set-cluster demo \
# 	--certificate-authority=${HOME}/.kube/certs/demo/k8s-ca.crt \
# 	--server=https://192.168.59.100:8443
# kubectl config set-credentials user1-demo \
#     --auth-provider=oidc \
#     --auth-provider-arg="idp-issuer-url=https://dex.192.168.59.100.nip.io:32000" \
#     --auth-provider-arg="client-id=example-app" \
#     --auth-provider-arg="client-secret=ZXhhbXBsZS1hcHAtc2VjcmV0" \
#     --auth-provider-arg="refresh-token=ChlxMnFwaXE3aXQzdTZ4emdudTVlZzQ1c2VwEhl2eG00dGR0aGJrNDVyajd0ZmZlenNsNzN4" \
#     --auth-provider-arg="id-token=eyJhbGciOiJSUzI1NiIsImtpZCI6IjQ1MzA4OGM0YWJlMTc5ZDc5M2YwZWE0ZmU3YWQ4NWNkNzVhMjM1MTEifQ.eyJpc3MiOiJodHRwczovL2RleC4xOTIuMTY4LjU5LjEwMC5uaXAuaW86MzIwMDAiLCJzdWIiOiJDZ0V4RWdWc2IyTmhiQSIsImF1ZCI6ImV4YW1wbGUtYXBwIiwiZXhwIjoxNjU4MjE5NjI2LCJpYXQiOjE2NTgxMzMyMjYsImF0X2hhc2giOiIwMDk1ZWZQQm54Qmk0czNYeDVBRHp3IiwiY19oYXNoIjoiLWhVX19yeS1FVFJ4M0JaRVFtT0VEZyIsImVtYWlsIjoidXNlcjFAZGV4LmlvIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsIm5hbWUiOiJ1c2VyMSJ9.e6EmARl9zMZpsBDY1458m25mMBLjzvWjk97VR1u7w8X9MnR7vvGfdZn5EzaMXPTXHI7dlcS9K0JW2cZJgeiH7rhVWoTbHXheSgGVJvdg30GJxRns83Wl45DSIIqxuhLTv2MMHwEWrzp3dncfH-4P-_byad1m4zSEA4W8eAXY1uXDjuea8motph6BCtEnZvbrJkQhjkBE9TVtHx39NiSNOwZvHvVd0uGIWVCs9cUyuBZVB8Wl819SyNP83SF0Z6KoJqJHB9dINGE4p89QLcgmSFxXclYJpmOQ4g4CMtStB_Mwbr5zrewxPEtC6bsSWG7ZH8Avq3ELAdMaIDpHggdIIQ"
# kubectl config set-context user1-demo \
#     --cluster=demo \
#     --user=user1-demo
# kubectl config use-context user1-demo

# Show kubectl configuration
kubectl config view
```

## 10. Test permissions as user

`INFO` Assuming I logged in as Dex static `user1` (email: `user1@dex.io`)

```bash
kubectl get pods -n user1
# expected output
# No resources found in user1 namespace.

kubectl get pods -n default
# expected output
# Error from server (Forbidden): pods is forbidden: User "user1@dex.io" cannot list resource "pods" in API group "" in the namespace "default"

kubectl get svc -n user4
# expected output
# Error from server (Forbidden): services is forbidden: User "user1@dex.io" cannot list resource "services" in API group "" in the namespace "user4"

kubectl get secret -n user02
# expected output
# Error from server (Forbidden): secrets is forbidden: User "user1@dex.io" cannot list resource "secrets" in API group "" in the namespace "user02"

kubectl get namespaces
# expected output
# Error from server (Forbidden): namespaces is forbidden: User "user1@dex.io" cannot list resource "namespaces" in API group "" at the cluster scope

kubectl get clusterrolebindings
# expected output
# Error from server (Forbidden): clusterrolebindings.rbac.authorization.k8s.io is forbidden: User "user1@dex.io" cannot list resource "clusterrolebindings" in API group "rbac.authorization.k8s.io" at the cluster scope

kubectl get rolebindings -n user1
# expected output
# NAME           ROLE                AGE
# user1@dex.io   ClusterRole/admin   20m
```

## 11. Cleanup

```bash
# Stop and delete Minikube
minikube delete -p authn

# Delete Minikube certs
rm -rf ${MINIKUBE_FILES_PATH}/*

# Delete all .kube/certs
rm -rf ${HOME}/.kube/certs

# Delete kubeconfig
rm -f ${HOME}/.kube/config

# [OPTIONAL] Restore previous kubeconfig
cp ${HOME}/.kube/config_bak ${HOME}/.kube/config
rm -f ${HOME}/.kube/config_bak
```

---

## Docs

- [Links](docs/links.md)
