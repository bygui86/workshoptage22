
# K8s Security Context

## Preliminary steps

```bash
cd 3_security-context/
```

## 1. Start Minikube

```bash
minikube --driver virtualbox --cpus 4 --memory 8192 --disk-size 20g start -p sec-ctx
# or
minikube --driver qemu --cpus 4 --memory 8192 --disk-size 20g start -p sec-ctx
```

## 2. Deploy and verify insecure pod

```bash
kubectl apply -f yaml/insecure-pod.yaml && \
kubectl wait --for=condition=ready pod insecure && \
kubectl exec -it insecure -- sh

id
# expected output
# uid=0(root) gid=0(root) groups=10(wheel)

ps
# expected output
# PID   USER     TIME  COMMAND
#     1 root      0:00 sleep 1h
#    21 root      0:00 sh
#    28 root      0:00 ps

echo hello > /tmp/testfile && ls -l /tmp
# expected output
# -rw-r--r--    1 root     root             6 Aug 27 11:16 testfile

ls -l /data
# expected output
# drwxrwxrwx    2 root     root          4096 Aug 27 10:36 demo

echo hello > /data/demo/testfile && ls -l /data/demo
# expected output
# -rw-r--r--    1 root     root             6 Aug 27 10:49 testfile

cat /proc/1/status | grep Cap
# expected output
# CapInh:	0000000000000000
# CapPrm:	00000000a80425fb
# CapEff:	00000000a80425fb
# CapBnd:	00000000a80425fb
# CapAmb:	0000000000000000
```

## 3. Deploy and verify secure pod

```bash
kubectl apply -f yaml/secure-pod_amd64.yaml && \
kubectl wait --for=condition=ready pod secure && \
kubectl exec -it secure -- sh
# or
kubectl apply -f yaml/secure-pod_arm64.yaml && \
kubectl wait --for=condition=ready pod secure && \
kubectl exec -it secure -- sh

id
# expected output
# uid=1000 gid=3000 groups=2000

ps
# expected output
# PID   USER     TIME  COMMAND
#     1 1000      0:00 sleep 1h
#     7 1000      0:00 sh
#    13 1000      0:00 ps

echo hello > /tmp/testfile && ls -l /tmp
# expected output
# sh: can't create /tmp/testfile: Read-only file system

ls -l /data
# expected output
# drwxrwsrwx    2 root     2000          4096 Aug 27 10:41 demo

echo hello > /data/demo/testfile && ls -l /data/demo
# expected output
# -rw-r--r--    1 1000     2000             6 Aug 27 11:14 testfile

cat /proc/1/status | grep Cap
# expected output
# CapInh:	0000000000000000
# CapPrm:	0000000000000000
# CapEff:	0000000000000000
# CapBnd:	0000000000000000
# CapAmb:	0000000000000000
```

## 4. Cleanup

```bash
# stop and delete Minikube
minikube stop -p sec-ctx && minikube delete -p sec-ctx
```

---

## Docs

- [Links](docs/links.md)
