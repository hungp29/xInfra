#!/bin/bash -e

if [[ -z "$PROJECT_ROOT" ]]; then
  echo "❌ PROJECT_ROOT is not set. Please run:"
  echo "   export PROJECT_ROOT=/path/to/your/project"
  exit 1
fi

CONFIG_FILE="$PROJECT_ROOT/config/env.sh"

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

PVC_NAME=$(microk8s kubectl get pvc -n "$INFRA_NAMESPACE" \
  -l app.kubernetes.io/instance="$POSTGRES_RELEASE_NAME" \
  -o jsonpath="{.items[0].metadata.name}" 2>/dev/null || true)
PV_NAME=$(microk8s kubectl get pvc "$PVC_NAME" -n "$INFRA_NAMESPACE" \
  -o jsonpath="{.spec.volumeName}" 2>/dev/null || true)
if [[ ! -z "$PV_NAME" ]]; then
  echo "Consider deleting the pv manually: '$PV_NAME'"
  microk8s kubectl describe pv "$PV_NAME"
fi

echo "✅ Done cleaning PostgreSQL resources."