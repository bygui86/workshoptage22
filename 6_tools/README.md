
# Tools

## Preliminary steps

```bash
cd 6_tools/
```

## 1. Start Minikube

One cluster to rule them all :)

```bash
minikube --driver docker --cpus 4 --memory 8192 --disk-size 20g start -p tools
# or
minikube --driver virtualbox --cpus 4 --memory 8192 --disk-size 20g start -p tools
# or
minikube --driver qemu --cpus 4 --memory 8192 --disk-size 20g start -p tools
```

## 2. Deploy some apps

```bash
kubectl apply -f ./yaml/busybox.yaml && \
kubectl apply -f ./yaml/nginx.yaml && \
kubectl apply -f ./yaml/malicious-app.yaml
```

## 3. Test some tools

1. [RBAC-Manager + RBAC-Lookup + Rakkess](rbac-manager_rbac-lookup_rakkess/)
1. [Trivy](trivy/)
1. [Polaris](polaris/)
1. [Popeye](popeye/)
1. [Starboard](starboard/)
1. [Falco](falco/)

## 4. Cleanup

```bash
minikube stop -p tools && minikube delete -p tools
```

---

## Docs

- [Links](docs/links.md)
