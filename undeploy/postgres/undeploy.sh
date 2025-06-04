#!/bin/bash -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/config.sh"

echo "🧹 Cleaning up PostgreSQL deployment in namespace: $INFRA_NAMESPACE"

echo "🔻 Deleting Helm release: $POSTGRES_RELEASE_NAME"
microk8s helm uninstall "$POSTGRES_RELEASE_NAME" --namespace "$INFRA_NAMESPACE" || true

echo "🧻 Deleting secret: $POSTGRES_SECRET_NAME"
microk8s kubectl delete secret "$POSTGRES_SECRET_NAME" --namespace "$INFRA_NAMESPACE" || true

echo "📦 Deleting PVCs..."
microk8s kubectl delete pvc -l app.kubernetes.io/instance="$POSTGRES_RELEASE_NAME" --namespace "$INFRA_NAMESPACE" || true

echo "✅ Done cleaning PostgreSQL resources."