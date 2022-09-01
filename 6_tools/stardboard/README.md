
# Tools - Starboard

`(i) INFO` Following steps require `Starboard` installed. Please see [here](https://aquasecurity.github.io/starboard/v0.15.8/cli/installation/krew/).

`(i) INFO` Please have a look also at the `K8s Operator`.

## Preliminary steps

```bash
cd starboard/
```

## 1. Install in K8s cluster

```bash
# install
kubectl starboard install

# verify
kubectl api-resources --api-group aquasecurity.github.io
# expected output
# NAME                             SHORTNAMES                 APIVERSION                        NAMESPACED   KIND
# ciskubebenchreports              kubebench                  aquasecurity.github.io/v1alpha1   false        CISKubeBenchReport
# clustercompliancedetailreports   compliancedetail           aquasecurity.github.io/v1alpha1   false        ClusterComplianceDetailReport
# clustercompliancereports         compliance                 aquasecurity.github.io/v1alpha1   false        ClusterComplianceReport
# clusterconfigauditreports        clusterconfigaudit         aquasecurity.github.io/v1alpha1   false        ClusterConfigAuditReport
# clustervulnerabilityreports      clustervuln,clustervulns   aquasecurity.github.io/v1alpha1   false        ClusterVulnerabilityReport
# configauditreports               configaudit                aquasecurity.github.io/v1alpha1   true         ConfigAuditReport
# kubehunterreports                kubehunter                 aquasecurity.github.io/v1alpha1   false        KubeHunterReport
# vulnerabilityreports             vuln,vulns                 aquasecurity.github.io/v1alpha1   true         VulnerabilityReport
```

## 2. Vulnerabilities scanning

Run static vulnerability scanner for each container image of a given workload.

`(i) INFO` The default vulnerability scanning capabilities in Starboard are provided by `Trivy` scanner.

```bash
# scan pod and view report
kubectl starboard scan vulnerabilityreports pod/nginx -n default && \
kubectl starboard get vulnerabilityreports pod/nginx -n default -o yaml

# scan deployment and view report
kubectl starboard scan vulnerabilityreports deployment/malicious-app -n default && \
kubectl starboard get vulnerabilityreports deployment/malicious-app -n default -o yaml

# view summary
kubectl get vulnerabilityreports -n default -o wide
```

## 3. Configuration auditing

Run a variety of checks to ensure that a given workload is configured using best practices

Kubernetes applications and other core configuration objects, such as Ingress, NetworkPolicy, ResourceQuota, RBAC resources, are evaluated against [Built-in Policies](https://aquasecurity.github.io/starboard/v0.15.8/configuration-auditing/built-in-policies/).

```bash
# scan pod and view report
kubectl starboard scan configauditreports pod/nginx -n default && \
kubectl starboard get configauditreports pod/nginx -n default -o yaml

# scan deployment and view report
kubectl starboard scan configauditreports deployment/malicious-app -n default && \
kubectl starboard get configauditreports deployment/malicious-app -n default -o yaml

# view summary
kubectl get configauditreport -n default -o wide
```

## 4. CIS benchmarking

Run the CIS Kubernetes Benchmark for each node of your cluster.

```bash
# scan
kubectl starboard scan ciskubebenchreports

# view report
kubectl get ciskubebenchreports tools -o yaml

# view summary
kubectl get ciskubebenchreports -o wide
```

## 5. Weakness hunting

Hunt for security weaknesses in your Kubernetes cluster.

```bash
# scan
kubectl starboard scan kubehunterreports

# view report
kubectl get kubehunterreports cluster -o yaml

# view summary
kubectl get kubehunterreports -o wide
```
