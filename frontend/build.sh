#!/usr/bin/env bash
# Build static assets into dist/. Requires API_URL (e.g. https://api.example.com).
set -euo pipefail
: "${API_URL:?API_URL must be set}"
cd "$(dirname "$0")"
rm -rf dist && mkdir dist
cp index.html style.css app.js dist/
# sed instead of envsubst so the script runs the same locally (macOS) and in CI.
sed "s|\${API_URL}|${API_URL}|g" config.js.tpl > dist/config.js
echo "Built frontend into $(pwd)/dist"
