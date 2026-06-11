# CircleGuard — Infrastructure

Repositorio de infraestructura del proyecto [CircleGuard](https://github.com/JuanAmor8/devops-project): plataforma de rastreo de contactos y alertas de salud para la comunidad universitaria ICESI.

Este repositorio contiene **todo lo necesario para aprovisionar y operar la plataforma**; el código de los microservicios, Dockerfiles, tests y pipelines CI viven en el repositorio de aplicación.

## Layout

```
circleguard-infra/
├── terraform/        # IaC: AKS (dev/stage/prod) en Azure + GKE DR opcional en GCP
│   ├── modules/      #   aks-cluster, gke-cluster
│   └── envs/         #   dev.tfvars, stage.tfvars, prod.tfvars
├── k8s/
│   ├── namespaces/   # circleguard-dev / -stage / -master
│   ├── dev/          # 8 servicios + datastores (Postgres, Kafka, Neo4j, Redis, OpenLDAP) + SealedSecrets
│   ├── stage/        # 8 servicios + datastores (emptyDir) — secrets vía envsubst desde Jenkins
│   ├── master/       # 8 servicios con HPA + datastores -prod con PVC + ingress TLS + observabilidad
│   ├── mesh/         # Demo Linkerd: canary 90/10, retries, circuit breaking
│   └── dr/           # Velero backup schedule (multi-cloud DR)
├── observability/    # Prometheus, Grafana (dashboards por servicio), Alertmanager, ELK, Jaeger
├── chaos/            # Experimentos Chaos Mesh
├── multicloud/       # Demo failover AKS↔GKE con HAProxy
└── scripts/          # deploy-all.sh (despliegue local a minikube/docker-desktop)
```

## Cómo lo consumen los pipelines

Los `Jenkinsfile-{dev,stage,master}` viven en el repo de aplicación (necesitan el código fuente para `gradle build` y `docker build`). En sus stages de **Deploy** hacen un segundo checkout de este repositorio en el directorio `infra/` y aplican los manifests:

```groovy
stage('Checkout Infra') {
    steps { dir('infra') { git url: env.INFRA_REPO, branch: env.INFRA_BRANCH } }
}
// ...
sh 'kubectl apply -f infra/k8s/master/ -n circleguard-master'
```

## Gestión de secretos

| Ambiente | Mecanismo | Razón |
|---|---|---|
| dev | **Sealed Secrets** (`k8s/dev/sealed-secrets.yaml`) | Antes los secrets dev estaban en base64 plano en git; ahora se commitea solo el secreto cifrado con la clave pública del controller. |
| stage / master | **Templates envsubst** (`k8s/{stage,master}/secrets.yaml`) | Los valores vienen de Jenkins `credentials()` en tiempo de deploy y nunca tocan git. Convertirlos a SealedSecrets acoplaría el repo a la clave de un cluster específico y rompería la rotación de credenciales vía Jenkins. |

### Sealed Secrets — instalación y sellado

```bash
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm install sealed-secrets sealed-secrets/sealed-secrets -n kube-system

# Sellar un Secret plano (nunca commitear el plano):
kubeseal --controller-name sealed-secrets --controller-namespace kube-system \
  --format yaml < secrets-local.yaml > k8s/dev/sealed-secrets.yaml

# Exportar cert público (commiteable, permite sellar offline):
kubeseal --fetch-cert --controller-name sealed-secrets \
  --controller-namespace kube-system > k8s/dev/sealed-secrets-cert.pem
```

> ⚠️ Los SealedSecrets están atados a la clave del cluster donde se sellaron. Si el cluster dev se recrea, hay que re-sellar con el nuevo cert.

## Validación local (sin cluster)

```bash
# Manifests K8s
kubeconform -strict -ignore-missing-schemas -summary k8s/dev k8s/stage k8s/master k8s/namespaces k8s/mesh k8s/dr

# Templates envsubst (render con dummies primero)
export DB_PASSWORD=x JWT_SECRET=x ... && envsubst < k8s/master/secrets.yaml | kubeconform -strict -

# Terraform
terraform -chdir=terraform init -backend=false
terraform -chdir=terraform validate
terraform -chdir=terraform fmt -check -recursive

# Dashboards Grafana
docker compose -f observability/docker-compose.observability.yml up -d grafana
```

## Terraform — ambientes

| Ambiente | Cluster | Nodos | Costo aprox. |
|---|---|---|---|
| dev | cg-aks-dev | 2× B2s | ~$85/mes |
| stage | cg-aks-stage | 3× B2ms + burst Spot 0-3 | ~$218/mes |
| prod | cg-aks-prod | 3× B4ms + 5× B2ms + ACR | ~$784/mes |
| dr (opcional) | cg-gke-dr | e2-medium Spot 1-3 | `-var enable_gke_dr=true` |

Backend remoto: Azure Storage (`rg-terraform-state`/`tfstate`), state por ambiente.

```bash
terraform init -backend-config="key=prod.tfstate" ...
terraform plan -var-file=envs/prod.tfvars
```

## Documentación extendida

La documentación completa (arquitectura, pipelines, testing, FinOps, runbooks) está en [`devops-project/docs/`](https://github.com/JuanAmor8/devops-project/tree/master/docs).
