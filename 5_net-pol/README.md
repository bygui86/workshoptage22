
# K8s Network Policies

## Preliminary steps

```bash
cd 5_net-pol/
```

## 1. Start Minikube

```bash
# /!\ WARN /!\
# Do not use Minikube with VirtualBox or QEMU as a driver for this demo. 
# It might prevent network plugin (Calico) to work properly. 
# Better using Minikube.
minikube --driver docker --cpus 4 --memory 8192 --disk-size 20g start -p net-pol --network-plugin cni --cni calico
```

## 2. Verify Calico is up and running

```bash
kubectl wait -n kube-system --for=condition=ready pod -l k8s-app=calico-node && \
kubectl get pods -l k8s-app=calico-node -n kube-system
```

## 3. Deploy pods

`(i) INFO` From now on please use always the same terminal window/tab.

`(i) INFO` This step requires `jq` installed. Please see [here](https://stedolan.github.io/jq/download/).

```bash
kubectl apply -f yaml/pods.yaml && \
kubectl wait --for=condition=ready pod -l test=network-policies

# if 'jq' is installed
export BUSYBOX_A_IP_ADDRESS=$(kubectl get pod busybox-a -o json | jq -r '.status.podIP')
export BUSYBOX_B_IP_ADDRESS=$(kubectl get pod busybox-b -o json | jq -r '.status.podIP')
export BUSYBOX_C_IP_ADDRESS=$(kubectl get pod busybox-c -o json | jq -r '.status.podIP')
# otherwise manually :(
export BUSYBOX_A_IP_ADDRESS=...
export BUSYBOX_B_IP_ADDRESS=...
export BUSYBOX_C_IP_ADDRESS=...
```

## 4. Check connectivity

```bash
# from busybox-a to busybox-b
kubectl exec -n default -ti busybox-a -- sh

ping ${BUSYBOX_B_IP_ADDRESS}
# expected result
# 	working
ping ${BUSYBOX_C_IP_ADDRESS}
# expected result
# 	working

# from busybox-b to busybox-a
kubectl exec -n default -ti busybox-b -- sh

ping ${BUSYBOX_A_IP_ADDRESS}
# expected result
# 	working
ping ${BUSYBOX_C_IP_ADDRESS}
# expected result
# 	working
```

## 5. Deploy "deny" policies

```bash
kubectl apply -f yaml/deny-all.yaml
```

## 6. Check connectivity

```bash
# from busybox-a to busybox-b
kubectl exec -n default -ti busybox-a -- sh

ping ${BUSYBOX_B_IP_ADDRESS}
# expected result
# 	not working
ping ${BUSYBOX_C_IP_ADDRESS}
# expected result
# 	not working

# from busybox-b to busybox-a
kubectl exec -n default -ti busybox-b -- sh

ping ${BUSYBOX_A_IP_ADDRESS}
# expected result
# 	not working
ping ${BUSYBOX_C_IP_ADDRESS}
# expected result
# 	not working

# from busybox-c to busybox-a and busybox-b
kubectl exec -n kube-system -ti busybox-c -- sh

ping ${BUSYBOX_A_IP_ADDRESS}
# expected result
# 	not working
ping ${BUSYBOX_B_IP_ADDRESS}
# expected result
# 	not working
```

## 7. Deploy "allow inside namespace" policy

```bash
# /!\ WARN /!\
# Without any label we are not able to proper identify namespace from network policies
kubectl label namespace default name=default && \
kubectl label namespace kube-system name=kube-system

kubectl apply -f yaml/allow-inside-ns.yaml
```

## 8. Check connectivity

```bash
# from busybox-a to busybox-b
kubectl exec -n default -ti busybox-a -- sh

ping ${BUSYBOX_B_IP_ADDRESS}
# expected result
# 	working
ping ${BUSYBOX_C_IP_ADDRESS}
# expected result
# 	not working

# from busybox-b to busybox-a
kubectl exec -n default -ti busybox-b -- sh

ping ${BUSYBOX_A_IP_ADDRESS}
# expected result
# 	working
ping ${BUSYBOX_C_IP_ADDRESS}
# expected result
# 	not working

# from busybox-c to busybox-a and busybox-b
kubectl exec -n kube-system -ti busybox-c -- sh

ping ${BUSYBOX_A_IP_ADDRESS}
# expected result
# 	not working
ping ${BUSYBOX_B_IP_ADDRESS}
# expected result
# 	not working
```

## 9. Deploy "allow busybox-c to busybox-a" policy

```bash
kubectl apply -f yaml/allow-c.yaml
```

## 10. Check connectivity

```bash
# from busybox-a to busybox-b
kubectl exec -n default -ti busybox-a -- sh

ping ${BUSYBOX_B_IP_ADDRESS}
# expected result
# 	working
ping ${BUSYBOX_C_IP_ADDRESS}
# expected result
# 	not working

# from busybox-b to busybox-a
kubectl exec -n default -ti busybox-b -- sh

ping ${BUSYBOX_A_IP_ADDRESS}
# expected result
# 	working
ping ${BUSYBOX_C_IP_ADDRESS}
# expected result
# 	not working

# from busybox-c to busybox-a and busybox-b
kubectl exec -n kube-system -ti busybox-c -- sh

ping ${BUSYBOX_A_IP_ADDRESS}
# expected result
# 	working
ping ${BUSYBOX_B_IP_ADDRESS}
# expected result
# 	not working
```

## 11. Cleanup

```bash
# stop and delete Minikube
minikube stop -p net-pol && minikube delete -p net-pol
```

---

## Docs

- [Links](docs/links.md)
