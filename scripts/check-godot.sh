#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
godot_bin="${GODOT_BIN:-godot}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/workspace/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-/workspace/.local/share/protein-forge-tests}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/workspace/.config}"
mkdir -p "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_CONFIG_HOME"
check_log="$(mktemp)"
trap 'rm -f "$check_log"' EXIT

run_check() {
  "$godot_bin" "$@" 2>&1 | tee "$check_log"
  if grep -Eq '^(SCRIPT ERROR|ERROR):' "$check_log"; then
    return 1
  fi
}

"$godot_bin" --headless --version
run_check --headless --path "$project_dir" --editor --import
run_check --headless --path "$project_dir" --script res://godot/tests/test_session.gd
run_check --headless --path "$project_dir" --script res://godot/tests/test_ui.gd
