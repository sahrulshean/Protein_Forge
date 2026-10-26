#!/usr/bin/env bash
set -euo pipefail

# Node.js and the Playwright package are supplied by the cloud runtime.
export PLAYWRIGHT_BROWSERS_PATH="${PLAYWRIGHT_BROWSERS_PATH:-/workspace/.cache/ms-playwright}"
playwright_cli="$(node -p 'require("node:path").join(require("node:path").dirname(require.resolve("playwright")), "cli.js")')"
node "$playwright_cli" install chromium
