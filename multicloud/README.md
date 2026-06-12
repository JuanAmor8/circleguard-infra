# Multi-Cloud — demo local de balanceo y failover

Simula la arquitectura multi-cloud (AKS activo + GKE respaldo) con dos
clusters kind y un balanceador global HAProxy. Evidencia y diseño completo en
`docs/BONUS_MULTICLOUD.md`; IaC real del segundo proveedor en
`terraform/modules/gke-cluster` + el root `terraform/environments/gcp-dr/`.

## Levantar la demo

```bash
# 1. Dos clusters ("clouds")
kind create cluster --config multicloud/kind-azure.yaml   # localhost:31080
kind create cluster --config multicloud/kind-gcp.yaml     # localhost:32080

# 2. Workload identificando su cloud en cada cluster
sed 's/${CLOUD_PROVIDER}/azure/' multicloud/gateway-echo.yaml | \
  kubectl --context kind-cg-azure-sim apply -f -
sed 's/${CLOUD_PROVIDER}/gcp/' multicloud/gateway-echo.yaml | \
  kubectl --context kind-cg-gcp-sim apply -f -

# 3. Balanceador global
docker compose -f multicloud/docker-compose.yml up -d

# 4. Verificar balanceo round-robin entre clouds
for i in 1 2 3 4 5 6; do curl -s localhost:8090; done
# stats del LB: http://localhost:8404

# 5. Failover: "cae Azure"
kubectl --context kind-cg-azure-sim scale deploy/gateway-echo --replicas=0
for i in 1 2 3 4; do curl -s localhost:8090; done   # 100% cloud=gcp
```

## Balanceo entre clouds REALES (AKS + GKE)

Con ambos clusters desplegados y el gateway expuesto como `LoadBalancer`,
`haproxy.real.cfg` balancea las dos IPs públicas reales:

```bash
AKS_IP=$(kubectl --context cg-aks-dev get svc gateway-service -n circleguard-dev \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
GKE_IP=$(kubectl --context <ctx-gke> get svc gateway-service -n circleguard-dr \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
sed -e "s/AKS_PUBLIC_IP/$AKS_IP/" -e "s/GKE_PUBLIC_IP/$GKE_IP/" \
  multicloud/haproxy.real.cfg > /tmp/haproxy.cfg
haproxy -f /tmp/haproxy.cfg &
for i in 1 2 3 4 5 6; do curl -s localhost:8090/actuator/health; echo; done
```

Failover real: `kubectl --context cg-aks-dev scale deploy/gateway-service \
--replicas=0 -n circleguard-dev` → el health check (fall 2) expulsa AKS y el
100% va a GKE. En producción este rol lo cumple Azure Traffic Manager / GCP
Cloud DNS con health checks equivalentes.

## Limpieza

```bash
docker compose -f multicloud/docker-compose.yml down
kind delete cluster --name cg-azure-sim
kind delete cluster --name cg-gcp-sim
```
