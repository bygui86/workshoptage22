
# Tools - Falco

`/!\ WARN /!\` This part of the workshop can't run on ARM CPUs (e.g. Apple Silicon M1).

## Preliminary steps

```bash
cd falco/
```

## 1. Start Kubenernetes

```bash
# k3d
k3d cluster create falco --agents 2 --servers 1
kubectl get nodes

# minikube
minikube --driver qemu --cpus 4 --memory 8192 --disk-size 20g start -p falco
kubectl get nodes

# kind
kind create cluster --name falco --config=./kind/kind-config.yaml
kubectl get nodes

# microk8s
microk8s install --cpu 4 --mem 12 --disk 20
# https://github.com/canonical/microk8s/issues/3036
kubectl get nodes

# multipass+k3s
## list distros
multipass find
## launch
multipass launch --name falco-master --cpus 4 --mem 12288M --disk 20G focal
# multipass launch -name falco -cpus 4 -mem 12288M -disk 20G jammy
## ssh into vm
multipass shell falco-master
## update ubuntu
sudo apt update
sudo apt upgrade
## install k3s
curl -sfL https://get.k3s.io | sh -
## check k3s
sudo kubectl get node -o wide
## install helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
## remove control-plane taints
sudo kubectl taint nodes --all node-role.kubernetes.io/master-
sudo kubectl taint nodes --all  node-role.kubernetes.io/control-plane-
```

## 2. Install Falco

```bash
# all but multipass+k3s
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update
helm install falco falcosecurity/falco
watch "kubectl get pods -A"

# multipss+k3s
mkdir ./falco
curl -SL -o ./falco/clusterrole.yaml https://raw.githubusercontent.com/falcosecurity/deploy-kubernetes/main/kubernetes/falco/templates/clusterrole.yaml
curl -SL -o ./falco/clusterrolebinding.yaml https://raw.githubusercontent.com/falcosecurity/deploy-kubernetes/main/kubernetes/falco/templates/clusterrolebinding.yaml
curl -SL -o ./falco/configmap.yaml https://raw.githubusercontent.com/falcosecurity/deploy-kubernetes/main/kubernetes/falco/templates/configmap.yaml
curl -SL -o ./falco/daemonset.yaml https://raw.githubusercontent.com/falcosecurity/deploy-kubernetes/main/kubernetes/falco/templates/daemonset.yaml
curl -SL -o ./falco/serviceaccount.yaml https://raw.githubusercontent.com/falcosecurity/deploy-kubernetes/main/kubernetes/falco/templates/serviceaccount.yaml
sudo kubectl apply -f falco/
watch "sudo kubectl get pods -A"
```

## 3. Watch Falco logs

```bash
kubectl logs -l app.kubernetes.io/name=falco -f | grep "Notice Network"
```

## 4. Attempt a potential bad action

`(i) INFO` Falco comes with default rulesets, one of them is `Detect network tools launched inside container`

```bash
kubectl exec -ti testpod -n default -- nc -l 8080
```

## 5. Look at Falco logs

The result of the above potential bad action is a notification in STDOUT of Falco.

So we should notice a log line like this:

```log
Notice Network tool launched in container [..]
```

## 6. Cleanup

```bash
# k3d
k3d cluster delete falco

# minikube
minikube stop -p falco && minikube delete -p falco

# kind
kind delete cluster --name falco

# microk8s
microk8s uninstall

# multipass+k3s
multipass delete falco-master
multipass purge
```
