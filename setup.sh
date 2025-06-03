#!/bin/bash -e
# This script sets up the environment for the projects by installing necessary dependencies.

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root"
  exit 1
fi

CURRENT_USER=${SUDO_USER:-$(whoami)}

echo "🔍 Checking if 'snap' is installed..."
if ! command -v snap &> /dev/null; then
  echo "📦 'snap' not found. Installing snapd..."
  apt update -y
  apt install -y snapd
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
microk8s enable dns
microk8s enable ingress
microk8s enable cert-manager
microk8s enable hostpath-storage
microk8s enable helm3

echo "✅ MicroK8s setup complete!"
