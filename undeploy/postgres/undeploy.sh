#!/bin/bash -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE="default"                 
RELEASE_NAME="x-postgres"         
SECRET_NAME="pg-secret"      

echo "🧹 Cleaning up PostgreSQL deployment in namespace: $NAMESPACE"

echo "🔻 Deleting Helm release: $RELEASE_NAME"
microk8s helm uninstall "$RELEASE_NAME" --namespace "$NAMESPACE" || true

echo "🧻 Deleting secret: $SECRET_NAME"
microk8s kubectl delete secret "$SECRET_NAME" --namespace "$NAMESPACE" || true

echo "📦 Deleting PVCs..."
microk8s kubectl delete pvc -l app.kubernetes.io/instance="$RELEASE_NAME" --namespace "$NAMESPACE" || true

echo "✅ Done cleaning PostgreSQL resources."