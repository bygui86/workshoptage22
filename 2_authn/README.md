
# Authentication - Minikube with Dex

## Preliminary steps

```bash
cd 2_authn/
```

## 1. Start Minikube

```bash
# /!\ WARN /!\
# Do not use Minikube with Docker as a driver for this demo. 
# It might cause problems with ingress and DNS. 
# Better using VirtualBox or QEMU.
minikube --driver virtualbox --cpus 4 --memory 8192 --disk-size 20g start -p authn
# or
minikube --driver qemu --cpus 4 --memory 8192 --disk-size 20g start -p authn

# Enable Minikube 'ingress' addon, this may take few minutes
minikube addons enable ingress

# Minikube addons
minikube addons list
```

## 2. Load environment variables

`(i) INFO` From now on please use always the same terminal window/tab.

```bash
. ./scripts/global-variables.sh
```

## 3. Generate certs

`(i) INFO` This step requires `OpenSSL` installed. Please see [here](https://www.openssl.org/source/).

```bash
# /!\ WARN /!\
# Please run from the same folder as this README
./scripts/generate-certs.sh
```

## 4. Deploy Dex

```bash
# /!\ WARN /!\
# Please run from the same folder as this README
./scripts/deploy-dex.sh
```

## 5. Configure Minikube apiserver authN with Dex

```bash
# Reconfigure Minikube apiserver authentication
minikube \
	--extra-config="apiserver.oidc-issuer-url=https://${DEX_DOMAIN}:32000" \
	--extra-config="apiserver.oidc-client-id=example-app" \
	--extra-config="apiserver.oidc-ca-file=${MINIKUBE_CERT_FILE_PATH}" \
	--extra-config="apiserver.oidc-username-claim=email" \
	--extra-config="apiserver.oidc-groups-claim=groups" \
	start
sleep 5

# Wait for K8s apiserver to be ready
kubectl wait pod -n kube-system -l component=kube-apiserver --for=condition=Ready
# if an error like
# "The connection to the server 192.168.59.100:8443 was refused - did you specify the right host or port?"
# occurs, just wait for some seconds and retry
sleep 1
kubectl get pods -n kube-system
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

```bash
# /!\ WARN /!\
# Please run from the same folder as this README
./scripts/deploy-dex-k8s-authenticator.sh
```

## 7. Deploy LDAP server

```bash
# /!\ WARN /!\
# Please run from the same folder as this README
./scripts/deploy-ldap-server.sh
```

## 8. Create Namespaces and RBAC

```bash
# /!\ WARN /!\
# Please run from the same folder as this README
./scripts/create-ns-rbac.sh
```

## 9. Login as a user

```bash
# Access dex-k8s-authenticator and login as a user you wish
open http://${DEX_K8S_AUTH_HOST}

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

`INFO` Assuming I'm logged in as Dex static `user1`

```bash
kubectl get pods -n user1
# expected output
# No resources found in user1 namespace.

kubectl get pods -n default
# expected output
# Error from server (Forbidden): pods is forbidden: User "user1@dex.io" cannot list resource "pods" in API group "" in the namespace "default"

kubectl get pods -n user4
# expected output
# Error from server (Forbidden): pods is forbidden: User "user1@dex.io" cannot list resource "pods" in API group "" in the namespace "user4"

kubectl get pods -n user02
# expected output
# Error from server (Forbidden): pods is forbidden: User "user1@dex.io" cannot list resource "pods" in API group "" in the namespace "user02"

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
minikube stop -p authn && minikube delete -p authn

# Delete Minikube certs
rm -rf ${MINIKUBE_FILES_PATH}/*

# Delete all .kube/certs
rm -rf ${HOME}/.kube/certs

# OPTIONAL
# 
# Delete default kubeconfig (.kube/config)
# 
# /!\ WARN /!\
# If you have other clusters configured, better to cleanup kubeconfig manually!
rm -f ${HOME}/.kube/config
```

---

## Docs

- [Links](docs/links.md)
