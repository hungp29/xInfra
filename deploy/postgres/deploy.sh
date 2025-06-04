#!/bin/bash -e

if [[ -z "$PROJECT_ROOT" ]]; then
  echo "❌ PROJECT_ROOT is not set. Please run:"
  echo "   export PROJECT_ROOT=/path/to/your/project"
  exit 1
fi

SCRIPT_DIR="$PROJECT_ROOT/deploy"
CONFIG_FILE="$PROJECT_ROOT/config/env.sh"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Missing config file: $CONFIG_FILE"
  exit 1
fi
source "$CONFIG_FILE"

# Default configuration
POSTGRES_DB_USER_PASSWORD=$(openssl rand -base64 16)
POSTGRES_ADMIN_PASSWORD=$(openssl rand -base64 16)

# Check helm is installed
if ! command -v microk8s helm &> /dev/null; then
  echo "❌ Helm is not installed. Please install Helm by running setup.sh first."
  exit 1
fi

echo "🔍 Checking if namespace '$INFRA_NAMESPACE' exists..."
microk8s kubectl get namespace "$INFRA_NAMESPACE" >/dev/null 2>&1 || \
microk8s kubectl create namespace "$INFRA_NAMESPACE"

echo "🔐 Creating Kubernetes Secret with generated password..."
microk8s kubectl create secret generic $POSTGRES_SECRET_NAME \
  --from-literal=password="$POSTGRES_DB_USER_PASSWORD" \
  --from-literal=postgres-password="$POSTGRES_ADMIN_PASSWORD" \
  --namespace $INFRA_NAMESPACE \
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
microk8s helm upgrade --install "$POSTGRES_RELEASE_NAME" $POSTGERS_CHART_NAME \
  --namespace "$INFRA_NAMESPACE" \
  --set auth.username="$POSTGRES_DB_NAME_USER" \
  --set auth.database="$POSTGRES_DB_NAME" \
  --set auth.existingSecret="$POSTGRES_SECRET_NAME" \
  --set containerPorts.postgresql=$POSTGRES_PORT \
  -f "$SCRIPT_DIR/values.yaml"

echo "✅ Done!"
echo "🔗 PostgreSQL user: $POSTGRES_DB_NAME_USER"
echo "🔑 PostgreSQL user password: $POSTGRES_DB_USER_PASSWORD"
echo "🔑 PostgreSQL admin password: $POSTGRES_ADMIN_PASSWORD"
echo "🔗 PostgreSQL db: $POSTGRES_DB_NAME"
echo "📌 To port-forward and access from host, run:"
echo "   microk8s kubectl port-forward --namespace $INFRA_NAMESPACE svc/$POSTGRES_SERVICE_NAME $POSTGRES_PORT:5432"