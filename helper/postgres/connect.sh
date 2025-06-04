#!/bin/bash -e

set -euo pipefail

if [[ -z "$PROJECT_ROOT" ]]; then
  echo "❌ PROJECT_ROOT is not set. Please run:"
  echo "   export PROJECT_ROOT=/path/to/your/project"
  exit 1
fi

SCRIPT_DIR="$PROJECT_ROOT/deploy/postgres"
CONFIG_FILE="$PROJECT_ROOT/config/env.sh"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Missing config file: $CONFIG_FILE"
  exit 1
fi
source "$CONFIG_FILE"

# NAMESPACE="infra"
# SERVICE_NAME="x-postgres-postgresql"
# PORT=5432
# DB_USER="myuser"
# DB_NAME="mydb"
# QUERY=""

# Parse optional arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --user) DB_USER="$2"; shift ;;
    --db) DB_NAME="$2"; shift ;;
    --port) PORT="$2"; shift ;;
    --query) QUERY="$2"; shift ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
  shift
done

# Check if psql is installed, if not install it
if ! command -v psql &>/dev/null; then
  echo "📦 'psql' not found. Installing postgresql-client..."
  if [[ -f /etc/debian_version ]]; then
    sudo apt update
    sudo apt install -y postgresql-client
  else
    echo "❌ Unsupported OS. Please install psql manually."
    exit 1
  fi
fi

echo "🔗 Port-forwarding PostgreSQL service..."
microk8s kubectl port-forward -n "$NAMESPACE" svc/$SERVICE_NAME "$PORT:$PORT" > /dev/null 2>&1 &
FORWARD_PID=$!

# Ensure cleanup when script exits
cleanup() {
  kill $FORWARD_PID > /dev/null 2>&1 || true
}
trap cleanup EXIT

sleep 2

# Get password from secret
PGPASSWORD=$(microk8s kubectl get secret -n "$NAMESPACE" "$SERVICE_NAME" -o jsonpath="{.data.postgres-password}" | base64 -d)

# Connect or run query
if [[ -n "$QUERY" ]]; then
  echo "▶️ Running query: $QUERY"
  PGPASSWORD="$PGPASSWORD" psql -h localhost -p "$PORT" -U "$DB_USER" -d "$DB_NAME" -c "$QUERY"
else
  echo "💬 Connecting to interactive psql shell..."
  PGPASSWORD="$PGPASSWORD" psql -h localhost -p "$PORT" -U "$DB_USER" -d "$DB_NAME"
fi