#!/bin/bash -e

if [[ -z "$PROJECT_ROOT" ]]; then
  echo "❌ PROJECT_ROOT is not set. Please run:"
  echo "   export PROJECT_ROOT=/path/to/your/project"
  exit 1
fi

# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT_DIR="$PROJECT_ROOT/deploy"
CONFIG_FILE="$PROJECT_ROOT/config.sh"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Missing config file: $CONFIG_FILE"
  exit 1
fi
source "$CONFIG_FILE"

echo "🧹 Cleaning up PostgreSQL deployment in namespace: $INFRA_NAMESPACE"

echo "🔻 Deleting Helm release: $POSTGRES_RELEASE_NAME"
microk8s helm uninstall "$POSTGRES_RELEASE_NAME" --namespace "$INFRA_NAMESPACE" || true

echo "🧻 Deleting secret: $POSTGRES_SECRET_NAME"
microk8s kubectl delete secret "$POSTGRES_SECRET_NAME" --namespace "$INFRA_NAMESPACE" || true

echo "📦 Deleting PVCs..."
microk8s kubectl delete pvc -l app.kubernetes.io/instance="$POSTGRES_RELEASE_NAME" --namespace "$INFRA_NAMESPACE" || true

echo "✅ Done cleaning PostgreSQL resources."