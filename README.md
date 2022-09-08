
# [Cloud Security: from Docker to Kubernetes](https://workshoptage.ch/workshops/2022/cloud-security-from-docker-to-kubernetes/)

#### [Workshop-Tage 2022](https://workshoptage.ch/programm-2022/)

---

## Supported OS

- MacOS (M1 not fully)
- Linux

`PLEASE NOTE` Windows not supported. If you don’t have any alternative, be sure to be proficient with all tools listed below.

---

## Required tools

It’s really better to install and configure everything listed below BEFORE the workshop, so it's easier follow it the right way.

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- [Docker](https://docs.docker.com/get-docker/)
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads) or [QEMU](https://www.qemu.org/download/)
- [Minikube](https://minikube.sigs.k8s.io/docs/start/) **(\*)**
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/quickstart/#install-helm)
- [Openssl](https://www.openssl.org/source/)
- [jq](https://stedolan.github.io/jq/download/)
- [Popeye](https://github.com/derailed/popeye/releases/tag/v0.10.1)
- [RBAC-Looup](https://rbac-lookup.docs.fairwinds.com/#installation)
- [Rakkess](https://github.com/corneliusweig/rakkess#installation)
- [Starboard](https://aquasecurity.github.io/starboard/v0.15.8/cli/installation/krew/)
- [Trivy](https://aquasecurity.github.io/trivy/v0.18.3/installation/)

**(\*)** Minikube has some cool alternatives (KinD, K3s/K3d, MicroK8s, GCP, AWS, Azure), but for some parts of the workshop the support is not granted, 
so please be sure to be proficient with any alternative you choose.

---

## Presentation

See [here](docs/presentation.key)

---

## Hands-on

1. [Dockerfiles](1_dockerfiles/)
1. [Authentication](2_authn/)
1. [K8s Security Context](3_security-context/)
1. [K8s Pod Security Standards and Admission](4_pss-psa/)
1. [K8s Network Policies](5_net-pol/)
1. [Tools](6_tools/)

---

## Docs

- [NSA-CISA guidance](docs/NSA-CISA_CTR_KUBERNETES_HARDENING_GUIDANCE_1.2_20220829.PDF)
