#!/usr/bin/env bash
set -euo pipefail

darklua_build --config .darklua.build.toml

cd out

# TODO: Move this into repo without tooling dying
curl -L https://github.com/RadiatedExodus/LuauCeption/releases/download/0.654/Luau.LuauCeption.Compiler.0.654.luau > plugin/plugin/src/luau.luau

sed -i -e \
    "s/version = \"0.0.0\"/version = \"$(lune run ../scripts/getPackageVersion)\"/" \
    plugin/bin/pesde.toml plugin/plugin/pesde.toml

cd .. # Back to top dir as we can't use rojo within out dir # TODO: <-- Fix
rojo build out/plugin/plugin/default.project.json --output out/plugin/bin/plugin.rbxm
cd out

sed -i -e \
    "s/private = true/private = false/" \
    pesde.toml plugin/bin/pesde.toml