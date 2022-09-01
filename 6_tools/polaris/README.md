
# Tools - Polaris

## Preliminary steps

```bash
cd polaris/
```

## 1. YAML manifests

```bash
docker run --rm \
	-v $(pwd)/../yaml/:/opt/app/yaml/ \
	quay.io/fairwinds/polaris:7.0.2 \
	polaris audit --audit-path /opt/app/yaml/ --format=score

docker run --rm \
	-v $(pwd)/../yaml/:/opt/app/yaml/ \
	quay.io/fairwinds/polaris:7.0.2 \
	polaris audit --audit-path /opt/app/yaml/ --format=yaml
```

## 2. K8s cluster

```bash
kubectl apply -f ./yaml/namespace.yaml

kubectl apply -f ./yaml/deploy

kubectl port-forward -n polaris svc/polaris-dashboard 8080

# in another terminal or directly in the browser
open http://localhost:8080
```
