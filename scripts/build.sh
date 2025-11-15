#!/usr/bin/env bash
set -euo pipefail

darklua_build --config .darklua.build.toml

# TODO: Move this into repo without tooling dying
curl -L https://github.com/RadiatedExodus/LuauCeption/releases/download/0.654/Luau.LuauCeption.Compiler.0.654.luau > out/plugin/luau.luau

sed -i -e \
    "s/private = true/private = false/" \
    out/pesde.toml