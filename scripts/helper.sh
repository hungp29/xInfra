#!/bin/bash -e

HELPER_DIR="$PROJECT_ROOT/helper"

function usage() {
  echo "Usage: $0 <component> <command> [args...]"
  echo "Example:"
  echo "  $0 postgres connect"
  echo "  $0 postgres backup /tmp/backup.sql"
  exit 1
}

COMPONENT="$1"
COMMAND="$2"
shift 2 || usage

SCRIPT_PATH="$HELPER_DIR/$COMPONENT/$COMMAND.sh"

if [[ -f "$SCRIPT_PATH" ]]; then
  bash "$SCRIPT_PATH" "$@"
else
  echo "❌ Command not found: $SCRIPT_PATH"
  usage
fi