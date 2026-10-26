#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_dir"
exec .venv/bin/protein-forge-play \
  --host "${PROTEIN_FORGE_HOST:-0.0.0.0}" \
  --port "${PROTEIN_FORGE_PORT:-8000}"
