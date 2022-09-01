
# Tools - Trivy

`(i) INFO` Please have a look also at the `Trivy K8s Operator` and the `Vulnerability Exporter`.

## Preliminary steps

```bash
cd trivy/
```

## 1. Container image

### 1.1. Build container images

```bash
make build-secure build-insecure
```

### 1.2. Scan dockerfiles

```bash
docker run --rm \
	-v /tmp/trivy-cache:/root/.cache/ \
	-v $(pwd)/dockerfiles/:/root/dockerfiles/ \
	aquasec/trivy:0.31.3 \
	config /root/dockerfiles/

docker run --rm \
	-v /tmp/trivy-cache:/root/.cache/ \
	-v $(pwd)/dockerfiles/:/root/dockerfiles/ \
	aquasec/trivy:0.31.3 \
	--severity HIGH config /root/dockerfiles/

trivy config dockerfiles/
```

### 1.3. Scan container images

```bash
docker run --rm \
	-v /tmp/trivy-cache:/root/.cache/ \
	aquasec/trivy:0.31.3 \
	image --security-checks vuln python:3.4-alpine

# scan images on local registry
docker run --rm \
	-v /tmp/trivy-cache:/root/.cache/ \
	-v /var/run/docker.sock:/var/run/docker.sock \
	aquasec/trivy:0.31.3 \
	image --security-checks vuln secure:alpine-3.16.2

docker run --rm \
	-v /tmp/trivy-cache:/root/.cache/ \
	-v /var/run/docker.sock:/var/run/docker.sock \
	aquasec/trivy:0.31.3 \
	image --security-checks vuln insecure:debian-bullseye

trivy image --security-checks vuln python:3.4-alpine
trivy image --security-checks vuln secure:alpine-3.16.2
trivy image --security-checks vuln insecure:debian-bullseye
```

## 2. Kubernetes scanning

### 2.1. YAML manifests

```bash
docker run --rm \
	-v /tmp/trivy-cache:/root/.cache/ \
	-v $(pwd)/../yaml/:/root/yaml/ \
	aquasec/trivy:0.31.3 \
	config /root/yaml/

trivy config ../yaml/
```

### 2.2. Cluster

`/!\ WARN /!\` This is an experimental feature.

`(i) INFO` This step requires `Trivy` to be installed. Please see [here](https://aquasecurity.github.io/trivy/v0.18.3/installation/).

```bash
# entire cluster, including vulnerabilities, secrets and misconfigurations
trivy k8s --report summary cluster

# specific deployment
trivy k8s -n default deployment malicious-app

# specific pod
trivy k8s -n default pod nginx
```
