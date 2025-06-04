#!/bin/bash -e

DEPLOY_DIR="$PROJECT_ROOT/deploy"
UNDEPLOY_DIR="$PROJECT_ROOT/undeploy"

ONLY=""
MODE="deploy"  # or "clean"

for arg in "$@"; do
  case $arg in
    --only=*)
      ONLY="${arg#--only=}"
      ;;
    --clean)
      MODE="clean"
      ;;
    *)
      echo "❌ Unknown argument: $arg"
      echo "Usage: $0 [--only=module] [--clean]"
      exit 1
      ;;
  esac
done

function list_modules {
  echo "📦 Available modules:"
  for dir in "$DEPLOY_DIR"/*; do
    if [[ -f "$dir/setup.sh" ]]; then
      echo "  - $(basename "$dir")"
    fi
  done
}

function run_script {
  local mode_dir=$1
  local module=$2
  local script_file="$mode_dir/$module/${mode_dir##*/}.sh"

  if [[ -f "$script_file" ]]; then
    echo "▶️  Running $script_file"
    bash "$script_file"
  else
    echo "⚠️  Skipping $module: no ${mode_dir##*/}.sh"
  fi
}

# Handle --only
if [[ -n "$ONLY" ]]; then
  if [[ "$MODE" == "deploy" ]]; then
    if [[ ! -d "$DEPLOY_DIR/$ONLY" ]]; then
      echo "❌ Module '$ONLY' not found in deploy/"
      list_modules
      exit 1
    fi
    run_script "$DEPLOY_DIR" "$ONLY"
  else
    if [[ ! -d "$UNDEPLOY_DIR/$ONLY" ]]; then
      echo "❌ Module '$ONLY' not found in undeploy/"
      exit 1
    fi
    run_script "$UNDEPLOY_DIR" "$ONLY"
  fi
else
  BASE_DIR="$([[ $MODE == "deploy" ]] && echo "$DEPLOY_DIR" || echo "$UNDEPLOY_DIR")"
  echo "🔁 Running $MODE for all modules in $(basename "$BASE_DIR")"
  for dir in "$BASE_DIR"/*; do
    mod_name=$(basename "$dir")
    run_script "$BASE_DIR" "$mod_name"
  done
fi

echo "✅ Done ($MODE mode)"