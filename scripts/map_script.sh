#!/bin/bash -e

# Root directory of the project
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "🌍 Project root: $PROJECT_ROOT"

BIN_DIR="/usr/local/bin"

# List of scripts to symlink
declare -A SCRIPTS=(
  ["deploy"]="$PROJECT_ROOT/scripts/deploy.sh"
  ["helper"]="$PROJECT_ROOT/scripts/helper.sh"
  ["service_test"]="$PROJECT_ROOT/scripts/service_test.sh"
)
echo "📦 Mapping CLI scripts to $BIN_DIR..."

for name in "${!SCRIPTS[@]}"; do
  target="${SCRIPTS[$name]}"

  if [[ ! -f "$target" ]]; then
    echo "❌ Script $target not found!"
    exit 1
  fi

  # Tạo wrapper trong /usr/local/bin
  echo "🔗 Mapping $name -> $target"

  cat <<EOF | sudo tee "$BIN_DIR/$name" > /dev/null
#!/bin/bash
export PROJECT_ROOT="$PROJECT_ROOT"
source "$PROJECT_ROOT/config/env.sh"
echo "$INFRA_NAMESPACE"
bash "$target" "\$@"
EOF

  sudo chmod +x "$BIN_DIR/$name"
done

echo "✅ Done. You can now run: deploy, helper ..."