#!/bin/bash -e

if [[ -z "$PROJECT_ROOT" ]]; then
  echo "❌ PROJECT_ROOT is not set. Please run:"
  echo "   export PROJECT_ROOT=/path/to/your/project"
  exit 1
fi

# Deploy whoami service to test the setup
echo "🚀 Deploying whoami service to test the setup..."
microk8s kubectl apply -f $PROJECT_ROOT/whoami/whoami.yaml
microk8s kubectl rollout status deployment/whoami

cp "$PROJECT_ROOT/whoami/whoami.yaml" ~/whoami.yaml
host=$(yq 'select(.kind == "Ingress") | .spec.tls[0].hosts[0]' ~/whoami.yaml)
rm ~/whoami.yaml
echo "🔗 You can now access the whoami service at https://$host"
echo "To undeploy the whoami service, run:"
echo "microk8s kubectl delete -f $PROJECT_ROOT/whoami/whoami.yaml"