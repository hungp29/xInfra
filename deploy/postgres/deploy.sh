#!/bin/bash -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default configuration
RELEASE_NAME="xPostgres"
NAMESPACE="infra"
POSTGRES_USER=${POSTGRES_USER:-xroot}
POSTGRES_DB=${POSTGRES_DB:-xroot}
POSTGRES_PASSWORD=$(openssl rand -base64 16)
SECRET_NAME=pg-secret
NAMESPACE=default

# Check helm is installed
if ! command -v helm &> /dev/null; then
  echo "❌ Helm is not installed. Please install Helm by running setup.sh first."
  exit 1
fi

echo "🔐 Creating Kubernetes Secret with generated password..."
microk8s kubectl create secret generic $SECRET_NAME \
  --from-literal=postgres-password="$POSTGRES_PASSWORD" \
  --namespace $NAMESPACE \
  --dry-run=client -o yaml | microk8s kubectl apply -f -

echo "📦 Creating expandable StorageClass (if not exists)..."
microk8s kubectl apply -f storageclass.yaml || true

# Add Bitnami Helm repository if it does not exist
if ! helm repo list | grep -q "bitnami"; then
  echo "📦 Adding Bitnami Helm repository..."
  helm repo add bitnami https://charts.bitnami.com/bitnami
fi

echo "🔄 Update Helm repo..."
helm repo update

# Deploy PostgreSQL
echo "🚀 Deploy PostgreSQL..."
helm upgrade --install $RELEASE_NAME bitnami/postgresql \
  --namespace $NAMESPACE \
  --set auth.username=$POSTGRES_USER \
  --set auth.database=$POSTGRES_DB
  -f values.yaml
# helm upgrade --install $RELEASE_NAME bitnami/postgresql \
#   --namespace $NAMESPACE \
#   --set auth.username=$POSTGRES_USER \
#   --set auth.password=$DB_PASSWORD \
#   --set auth.database=$POSTGRES_DB

echo "✅ Done!"
echo "🔗 PostgreSQL user: $POSTGRES_USER"
echo "🔗 PostgreSQL db: $POSTGRES_DB"
echo "🔑 PostgreSQL password: $POSTGRES_PASSWORD"
echo "📌 To port-forward and access from host, run:"
echo "   microk8s kubectl port-forward svc/$RELEASE_NAME-postgresql 5432:5432"