#!/usr/bin/env bash
# Instala Velero con el plugin GCP en el cluster ACTUAL del kubeconfig,
# apuntando al bucket de respaldo cruzado en GCS. Se ejecuta dos veces:
#   1) con kubeconfig de AKS (cluster activo)  -> produce backups
#   2) con kubeconfig de GKE (cg-gke-dr)       -> consume backups (restore)
# Así la pérdida total de Azure no se lleva también los respaldos (viven en GCP).
#
# Uso:
#   BUCKET=cg-velero-dr-<project> SA_KEY=./gcp-velero-sa.json ./scripts/velero-install-gcp.sh
set -euo pipefail

: "${BUCKET:?define BUCKET=cg-velero-dr-<project>}"
: "${SA_KEY:?define SA_KEY=ruta/gcp-velero-sa.json}"

velero install \
  --provider gcp \
  --plugins velero/velero-plugin-for-gcp:v1.10.0 \
  --bucket "$BUCKET" \
  --secret-file "$SA_KEY" \
  --use-volume-snapshots=false \
  --wait

echo "Velero instalado contra gs://$BUCKET en el cluster actual."
echo "Backup on-demand (en AKS):  velero backup create circleguard-ondemand --include-namespaces circleguard-dev --wait"
echo "Restore (en GKE):           velero restore create --from-backup circleguard-ondemand --wait"
