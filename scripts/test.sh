#!/bin/bash -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Deploy whoami service to test the setup
echo "🚀 Deploying whoami service to test the setup..."
microk8s kubectl apply -f $SCRIPT_DIR/whoami/whoami.yaml
microk8s kubectl rollout status deployment/whoami

cp "$SCRIPT_DIR/whoami/whoami.yaml" ~/whoami.yaml
host=$(yq 'select(.kind == "Ingress") | .spec.tls[0].hosts[0]' ~/whoami.yaml)
rm ~/whoami.yaml
echo "🔗 You can now access the whoami service at https://$host"
echo "To undeploy the whoami service, run:"
echo "microk8s kubectl delete -f $SCRIPT_DIR/whoami/whoami.yaml"