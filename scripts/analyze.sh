#!/usr/bin/env bash
set -euo pipefail

cd plugin/bin
lune setup
cd ../..

rojo sourcemap test.project.json -o sourcemap.json

selene \
    --no-summary \
    src plugin tests

curl -o types/globalTypes.d.luau https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/refs/heads/main/scripts/globalTypes.d.luau

luau-lsp analyze \
    --platform=roblox --defs types/globalTypes.d.luau --sourcemap sourcemap.json \
    --settings=".vscode/settings.json" \
    src plugin tests