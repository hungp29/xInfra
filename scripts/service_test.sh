#!/bin/bash -e

if [[ -z "$PROJECT_ROOT" ]]; then
  echo "❌ PROJECT_ROOT is not set. Please run:"
  echo "   export PROJECT_ROOT=/path/to/your/project"
  exit 1
fi
WHOAMI_YAML="$PROJECT_ROOT/whoami/whoami.yaml"

if [[ "$1" == "--clean" ]]; then
  echo "🧹 Cleaning up whoami service..."
  microk8s kubectl delete -f "$WHOAMI_YAML" --ignore-not-found
  exit 0
fi

# Deploy whoami service to test the setup
echo "🚀 Deploying whoami service to test the setup..."
microk8s kubectl apply -f "$WHOAMI_YAML"
microk8s kubectl rollout status deployment/whoami

# Extract host from Ingress
host=$(yq 'select(.kind == "Ingress") | .spec.tls[0].hosts[0]' "$WHOAMI_YAML")

rm ~/whoami.yaml

echo "🔗 You can now access the whoami service at https://$host"
echo "To undeploy the whoami service, run:"
echo "microk8s kubectl delete -f $PROJECT_ROOT/whoami/whoami.yaml"
echo "or"
echo "service_test --clean"