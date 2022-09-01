
# K8s Pod Security Standards and Admission

## Preliminary steps

```bash
cd 4_pss-psa/
```

## 1. Start Minikube

```bash
minikube --driver virtualbox --cpus 4 --memory 8192 --disk-size 20g start -p pss-psa --extra-config=apiserver.enable-admission-plugins=PodSecurity
# or
minikube --driver qemu --cpus 4 --memory 8192 --disk-size 20g start -p pss-psa --extra-config=apiserver.enable-admission-plugins=PodSecurity
```

## 2. Before applying a policy to a namespace

```bash
kubectl label --dry-run=server --overwrite ns --all pod-security.kubernetes.io/enforce=baseline
```

## 3. Review cluster-wide policy

```bash
open yaml/admission-config.yaml
```

## 4. Create namespaces

```bash
kubectl apply -f yaml/namespaces.yaml
```

## 5. Deploy some insecure pods

```bash
kubectl apply -f yaml/nginx.yaml -n privileged
# expected output
# 	pod/nginx created
# expected result
# 	"nginx" pod created in namespace "privileged"

kubectl apply -f yaml/nginx.yaml -n baseline
# expected output
# 	Warning: would violate PodSecurity "restricted:latest": allowPrivilegeEscalation != false (container "nginx" must set securityContext.allowPrivilegeEscalation=false), unrestricted capabilities (container "nginx" must set securityContext.capabilities.drop=["ALL"]), runAsNonRoot != true (pod or container "nginx" must set securityContext.runAsNonRoot=true), seccompProfile (pod or container "nginx" must set securityContext.seccompProfile.type to "RuntimeDefault" or "Localhost")
# 	pod/nginx created
# expected result
# 	"nginx" pod created in namespace "baseline"

kubectl apply -f yaml/nginx.yaml -n restricted
# expected output
# 	Error from server (Forbidden): error when creating "nginx.yaml": pods "nginx" is forbidden: violates PodSecurity "restricted:latest": allowPrivilegeEscalation != false (container "nginx" must set securityContext.allowPrivilegeEscalation=false), unrestricted capabilities (container "nginx" must set securityContext.capabilities.drop=["ALL"]), runAsNonRoot != true (pod or container "nginx" must set securityContext.runAsNonRoot=true), seccompProfile (pod or container "nginx" must set securityContext.seccompProfile.type to "RuntimeDefault" or "Localhost")
# expected result
# 	no pod created
```

## 6. Deploy some secure pods

```bash
kubectl apply -f yaml/busybox_amd64.yaml -n privileged
# or
kubectl apply -f yaml/busybox_arm64.yaml -n privileged
# expected output
# 	pod/nginx created
# expected result
# 	"busybox" pod created in namespace "privileged"

kubectl apply -f yaml/busybox_amd64.yaml -n baseline
# or
kubectl apply -f yaml/busybox_arm64.yaml -n baseline
# expected output
# 	pod/busybox created
# expected result
# 	"busybox" pod created in namespace "baseline"

kubectl apply -f yaml/busybox_amd64.yaml -n restricted
# or
kubectl apply -f yaml/busybox_arm64.yaml -n restricted
# expected output
# 	pod/busybox created
# expected result
# 	"busybox" pod created in namespace "restricted"
```

## 7. Deploy a malicious app

```bash
kubectl apply -f yaml/malicious-app.yaml -n privileged
# expected output
# 	Warning: would violate PodSecurity "baseline:latest": hostPath volumes (volume "k8s-certs")
# 	deployment.apps/malicious-app created
# expected result
# 	"malicious-app" pod created in namespace "privileged"

kubectl apply -f yaml/malicious-app.yaml -n baseline
# expected output
# 	Warning: would violate PodSecurity "restricted:latest": allowPrivilegeEscalation != false (container "busybox" must set securityContext.allowPrivilegeEscalation=false), unrestricted capabilities (container "busybox" must set securityContext.capabilities.drop=["ALL"]), restricted volume types (volume "k8s-certs" uses restricted volume type "hostPath"), runAsNonRoot != true (pod or container "busybox" must set securityContext.runAsNonRoot=true), seccompProfile (pod or container "busybox" must set securityContext.seccompProfile.type to "RuntimeDefault" or "Localhost")
# 	deployment.apps/malicious-app created
# expected result
# 	no pod created
kubectl describe -n baseline deploy malicious-app
# pay attention to "Conditions"
kubectl describe -n baseline replicaset -l app=malicious-app
# pay attention to "Events"

kubectl apply -f yaml/malicious-app.yaml -n restricted
# expected output
# 	deployment.apps/malicious-app created
# expected result
# 	no pod created
kubectl describe -n restricted deploy malicious-app
# pay attention to "Conditions"
kubectl describe -n restricted replicaset -l app=malicious-app
# pay attention to "Events"
```

## 8. Cleanup

```bash
# stop and delete Minikube
minikube stop -p pss-psa && minikube delete -p pss-psa
```

---

## Docs

- [Links](docs/links.md)
