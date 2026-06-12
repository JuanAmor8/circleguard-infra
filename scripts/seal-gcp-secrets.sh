#!/bin/bash
# ================================================
# Seal GCP/GKE Secrets - Circle Guard
# Espejo de seal-dev-secrets.sh para el sitio DR en GKE (cg-gke-dr).
# Genera k8s/gcp/sealed-secrets.yaml. NECESARIO porque un SealedSecret solo
# lo descifra el cluster cuya clave privada lo cifró: el sealed-secrets.yaml
# de dev (cifrado con la clave de cg-aks-dev) NO sirve en GKE.
#
# Requisitos:
#   - kubectl apuntando a cg-gke-dr con el controller instalado:
#       helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
#       helm install sealed-secrets sealed-secrets/sealed-secrets -n kube-system
#   - kubeseal CLI
#
# Uso:
#   ./scripts/seal-gcp-secrets.sh
#   DB_PASSWORD=otro QR_SECRET=otro ./scripts/seal-gcp-secrets.sh
# ================================================

set -euo pipefail
cd "$(dirname "$0")/.."

NAMESPACE="circleguard-dr"
OUT="k8s/gcp/sealed-secrets.yaml"
CERT="k8s/gcp/sealed-secrets-cert.pem"

# Valores: env var si existe, si no el default mock
DB_PASSWORD="${DB_PASSWORD:-password}"
JWT_SECRET="${JWT_SECRET:-my-super-secret-jwt-key-for-dev-only}"
# >= 32 bytes (256 bits): JJWT rejects shorter keys for HMAC-SHA (RFC 7518 3.2)
QR_SECRET="${QR_SECRET:-my-super-secret-qr-key-for-dev-only}"
LDAP_BIND_PASSWORD="${LDAP_BIND_PASSWORD:-admin}"
NEO4J_PASSWORD="${NEO4J_PASSWORD:-password}"
VAULT_SECRET="${VAULT_SECRET:-testsecret}"
VAULT_SALT="${VAULT_SALT:-deadbeef}"
VAULT_HASH_SALT="${VAULT_HASH_SALT:-12345678}"
TWILIO_ACCOUNT_SID="${TWILIO_ACCOUNT_SID:-AC_MOCK_SID}"
TWILIO_AUTH_TOKEN="${TWILIO_AUTH_TOKEN:-mock-token}"
TWILIO_FROM_NUMBER="${TWILIO_FROM_NUMBER:-+15550000000}"
GOTIFY_TOKEN="${GOTIFY_TOKEN:-mock-gotify-token}"

echo "[1/3] Generando Secret plano en memoria..."
PLAIN=$(kubectl create secret generic circleguard-secrets \
  --namespace "$NAMESPACE" \
  --dry-run=client -o yaml \
  --from-literal=DB_PASSWORD="$DB_PASSWORD" \
  --from-literal=JWT_SECRET="$JWT_SECRET" \
  --from-literal=QR_SECRET="$QR_SECRET" \
  --from-literal=LDAP_BIND_PASSWORD="$LDAP_BIND_PASSWORD" \
  --from-literal=NEO4J_PASSWORD="$NEO4J_PASSWORD" \
  --from-literal=NEO4J_AUTH="neo4j/$NEO4J_PASSWORD" \
  --from-literal=VAULT_SECRET="$VAULT_SECRET" \
  --from-literal=VAULT_SALT="$VAULT_SALT" \
  --from-literal=VAULT_HASH_SALT="$VAULT_HASH_SALT" \
  --from-literal=TWILIO_ACCOUNT_SID="$TWILIO_ACCOUNT_SID" \
  --from-literal=TWILIO_AUTH_TOKEN="$TWILIO_AUTH_TOKEN" \
  --from-literal=TWILIO_FROM_NUMBER="$TWILIO_FROM_NUMBER" \
  --from-literal=GOTIFY_TOKEN="$GOTIFY_TOKEN")

echo "[2/3] Sellando con kubeseal (cert del cluster cg-gke-dr)..."
if [ -f "$CERT" ]; then
    echo "$PLAIN" | kubeseal --cert "$CERT" --format yaml > "$OUT"
else
    echo "$PLAIN" | kubeseal \
      --controller-name sealed-secrets \
      --controller-namespace kube-system \
      --format yaml > "$OUT"
    echo "      Exportando cert público para sellados offline futuros..."
    kubeseal --fetch-cert \
      --controller-name sealed-secrets \
      --controller-namespace kube-system > "$CERT"
fi

echo "[3/3] Listo: $OUT"
echo "Commitea $OUT y $CERT (ambos seguros: cifrado + clave pública)."
