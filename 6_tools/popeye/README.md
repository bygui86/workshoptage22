
# Tools - Popeye

## Preliminary steps

```bash
cd popeye/
```

## 1. Run from local

`(i) INFO` This step requires `Popeye` installed. Please see [here](https://github.com/derailed/popeye/releases/tag/v0.10.1).

```bash
# scan whole cluster, output full report
popeye -A

# scan whole cluster, output score only
popeye -A -o score

# scan whole cluster and output full report file
POPEYE_REPORT_DIR=. popeye -A --save -o html --output-file report.html && \
open report.html
```

## 2. Run inside K8s

```bash
# deploy
kubectl apply -f ./yaml && \

# wait until pod has finish it's job (including error)

# review report
kubectl logs -n default -l app=popeye --tail 100000
```
