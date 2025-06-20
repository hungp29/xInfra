#!/bin/bash -e
# This script sets up the environment for the projects by installing necessary dependencies.

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root"
  exit 1
fi

CURRENT_USER=${SUDO_USER:-$(whoami)}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Mapping the scripts
"$SCRIPT_DIR/scripts/map_script.sh"

# Install necessary packages
if ! command -v snap &> /dev/null; then
  echo "📦 'snap' not found. Installing snapd..."
  apt update -y
  apt install -y snapd
fi

if ! command -v yq &> /dev/null; then
  echo "📦 Installing yq..."
  sudo wget -q https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq
  sudo chmod +x /usr/local/bin/yq
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
microk8s status --wait-ready > /dev/null

echo "⚙️ Enabling addons: dns, ingress, cert-manager, hostpath-storage, helm3, metallb ..."
REQUIRED_ADDONS=("dns" "ingress" "cert-manager" "hostpath-storage" "helm3" "metallb")
METALLB_RANGE="192.168.0.202-192.168.0.220"

for addon in "${REQUIRED_ADDONS[@]}"; do
  if microk8s status --format short | grep -qE ".*/$addon: enabled"; then
    echo "[OK] Addon '$addon' is already enabled."
  else
    echo "[..] Enabling addon '$addon'..."
    if [ "$addon" = "metallb" ]; then
      microk8s enable "$addon:$METALLB_RANGE"
    else
      microk8s enable "$addon"
    fi
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
create_cluster_issuer "letsencrypt-prod" "$SCRIPT_DIR/cert-manager/cluster-issuer-prod.yaml"

# Deploy whoami service to test the setup
service_test

echo "✅ MicroK8s setup complete!"

SCRIPT_NAME="check_network.sh"
SOURCE_PATH="$SCRIPT_DIR/scripts/$SCRIPT_NAME"
TARGET_PATH="/usr/local/bin/$SCRIPT_NAME"

if [[ ! -f "$SOURCE_PATH" ]]; then
  echo "❌ Source script $SOURCE_PATH does not exist."
  exit 1
fi

echo "📂 Copying from $SOURCE_PATH to $TARGET_PATH..."
sudo cp "$SOURCE_PATH" "$TARGET_PATH"

echo "🔒 Permissions for $TARGET_PATH..."
sudo chmod +x "$TARGET_PATH"

CRON_JOB="*/5 * * * * $TARGET_PATH"

EXISTS=$(sudo crontab -l 2>/dev/null | grep -F "$CRON_JOB" || true)

if [[ -z "$EXISTS" ]]; then
  echo "⏱️  Adding cron job to check network every 5 minutes..."
  (sudo crontab -l 2>/dev/null; echo "$CRON_JOB") | sudo crontab -
else
  echo "✅ Cron job already exists."
fi

echo "✅ Setup complete! Please reboot your system to apply changes."