
# Tools - RBAC-Manager

## Preliminary steps

```bash
cd rbac-manager_rbac-lookup_rakkess/
```

## 1. Deploy RBAC-Manager

```bash
kubectl apply -f ./yaml/namespace.yaml && \
kubectl apply -f ./yaml/rbac-manager && \
kubectl apply -f ./yaml/roles && \
kubectl apply -f ./yaml/permissions
```

## 2. List crated K8s resources

```bash
kubectl get clusterroles | grep custom

kubectl get rolebindings -n default

kubectl get rolebindings -n kube-system | grep admin
```

## 3. Review roles with RBAC-Lookup

`(i) INFO` This step requires `RBAC-Looup` installed. Please see [here](https://rbac-lookup.docs.fairwinds.com/#installation).

```bash
# cluster scope
rbac-lookup

# cluster scope, users only
rbac-lookup --kind user

# cluster scope, service accounts only
rbac-lookup --kind serviceaccount
rbac-lookup --kind serviceaccount | grep rbac

# cluster scope, specific user only
rbac-lookup admin
rbac-lookup admin --output wide
rbac-lookup user1 --output wide
```

## 4. Review roles with Rakkess

`(i) INFO` This step requires `Rakkess` installed. Please see [here](https://github.com/corneliusweig/rakkess#installation).

```bash
# as specific user, specific namespace only
rakkess --as admin@dex.io -n default
rakkess --as admin@dex.io -n kube-system

# as specific service account, specific namespace only
rakkess --sa rbac-manager -n rbac-manager

# on specific resource, cluster scope
rakkess resource configmaps

# on specific resource, specific namespace only
rakkess resource configmaps -n default
rakkess resource deployments -n kube-system
```
