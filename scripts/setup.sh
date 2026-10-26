#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_dir"
export UV_CACHE_DIR="${UV_CACHE_DIR:-/workspace/.cache/uv}"
export UV_PYTHON_DOWNLOADS=never

python3 --version
uv --version
uv sync --frozen --group dev --python 3.12
uv pip check
uv run --frozen --no-sync pytest -q
uv build --python 3.12
uv run --frozen --no-sync protein-forge " acd ef "
