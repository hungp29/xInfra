#!/bin/bash -e
# This script sets up the environment for the projects by installing necessary dependencies.

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root"
  exit 1
fi

# Install necessary packages
CURRENT_USER=${SUDO_USER:-$(whoami)}

if ! command -v snap &> /dev/null; then
  echo "📦 'snap' not found. Installing snapd..."
  apt update -y
  apt install -y snapd
fi

if ! snap list | grep -q yq; then
  echo "📦 Installing yq..."
  snap install yq
fi

echo "🔍 Checking if MicroK8s is installed..."
if ! snap list | grep -q microk8s; then
  echo "📦 Installing MicroK8s..."
  snap install microk8s --classic --channel=1.25
else
  echo "✅ MicroK8s is already installed."
fi

echo "👤 Adding $CURRENT_USER to 'microk8s' group..."
usermod -a -G microk8s $CURRENT_USER
chown -f -R $CURRENT_USER ~/.kube

echo "⏳ Waiting for MicroK8s to be ready..."
microk8s status --wait-ready

echo "⚙️ Enabling addons: dns, ingress, cert-manager, hostpath-storage, helm3 ..."
REQUIRED_ADDONS=("dns" "ingress" "cert-manager" "hostpath-storage" "helm3")

for addon in "${REQUIRED_ADDONS[@]}"; do
  if microk8s status --format short | grep -qE ".*/$addon: enabled"; then
    echo "[OK] Addon '$addon' is already enabled."
  else
    echo "[..] Enabling addon '$addon'..."
    microk8s enable "$addon"
  fi
done

# Create cluster issuer if it does not exist
create_cluster_issuer() {
  NAME=$1
  YAML_FILE=$2

  if microk8s kubectl get clusterissuer "$NAME" >/dev/null 2>&1; then
    echo "[OK] ClusterIssuer '$NAME' already exists."
  else
    echo "[+] Creating ClusterIssuer '$NAME' from $YAML_FILE..."
    microk8s kubectl apply -f "$YAML_FILE"
  fi
}

echo "🔧 Configuring cert-manager ClusterIssuer..."
create_cluster_issuer "letsencrypt-prod" "./cert-manager/cluster-issuer-prod.yaml"

# Deploy whoami service to test the setup
echo "🚀 Deploying whoami service to test the setup..."
microk8s kubectl apply -f ./whoami/whoami.yaml
microk8s kubectl rollout status deployment/whoami


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# echo $SCRIPT_DIR
# ls -l "$SCRIPT_DIR/whoami/whoami.yaml"
# ls -l /tmp
# host=$(yq '.spec.tls[0].hosts[0]' /tmp/whoami.yaml)
# host=$(yq '.spec.tls[0].hosts[0]' "$SCRIPT_DIR/whoami/whoami.yaml")

# host=$(yq '.spec.tls[0].hosts[0]' /tmp/whoami.yaml)
cp "$SCRIPT_DIR/whoami/whoami.yaml" ~/whoami.yaml
host=$(yq '.spec.tls[0].hosts[0]' ~/whoami.yaml)
rm ~/whoami.yaml
if [ -z "$host" ]; then
  echo "❌ Failed to extract host from whoami.yaml"
  exit 1
fi
echo "🔗 You can now access the whoami service at https://$host"

echo "✅ MicroK8s setup complete!"
