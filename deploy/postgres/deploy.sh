#!/bin/bash -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default configuration
RELEASE_NAME="x-postgres"
NAMESPACE="infra"
POSTGRES_USER=${POSTGRES_USER:-xroot}
POSTGRES_DB=${POSTGRES_DB:-xroot}
POSTGRES_USER_PASSWORD=$(openssl rand -base64 16)
POSTGRES_PASSWORD=$(openssl rand -base64 16)
SECRET_NAME=postgres-secret

# Check helm is installed
if ! command -v microk8s helm &> /dev/null; then
  echo "❌ Helm is not installed. Please install Helm by running setup.sh first."
  exit 1
fi

echo "🔍 Checking if namespace '$NAMESPACE' exists..."
microk8s kubectl get namespace "$NAMESPACE" >/dev/null 2>&1 || \
microk8s kubectl create namespace "$NAMESPACE"

echo "🔐 Creating Kubernetes Secret with generated password..."
microk8s kubectl create secret generic $SECRET_NAME \
  --from-literal=password="$POSTGRES_USER_PASSWORD" \
  --from-literal=postgres-password="$POSTGRES_PASSWORD" \
  --namespace $NAMESPACE \
  --dry-run=client -o yaml | microk8s kubectl apply -f -

echo "📦 Creating expandable StorageClass (if not exists)..."
microk8s kubectl apply -f "$SCRIPT_DIR/storageclass.yaml" || true

# Add Bitnami Helm repository if it does not exist
if ! microk8s helm repo list | grep -q "bitnami"; then
  echo "📦 Adding Bitnami Helm repository..."
  microk8s helm repo add bitnami https://charts.bitnami.com/bitnami
fi

echo "🔄 Update Helm repo..."
microk8s helm repo update

# Deploy PostgreSQL
echo "🚀 Deploy PostgreSQL..."
microk8s helm upgrade --install "$RELEASE_NAME" bitnami/postgresql \
  --namespace "$NAMESPACE" \
  --set auth.username="$POSTGRES_USER" \
  --set auth.database="$POSTGRES_DB" \
  -f "$SCRIPT_DIR/values.yaml"

echo "✅ Done!"
echo "🔗 PostgreSQL user: $POSTGRES_USER"
echo "🔗 PostgreSQL user password: $POSTGRES_USER_PASSWORD"
echo "🔗 PostgreSQL db: $POSTGRES_DB"
echo "🔑 PostgreSQL password: $POSTGRES_PASSWORD"
echo "📌 To port-forward and access from host, run:"
echo "   microk8s kubectl port-forward svc/$RELEASE_NAME-postgresql 5432:5432"