#!/usr/bin/env bash
set -euo pipefail

darklua_build --config .darklua.build.toml

# TODO: Move this into repo without tooling dying
curl -L https://github.com/RadiatedExodus/LuauCeption/releases/download/0.654/Luau.LuauCeption.Compiler.0.654.luau > out/plugin/src/luau.luau

rojo build out/plugin/plugin.project.json --output out/plugin/bin/plugin.rbxm
cd out # Do this after using rojo as we can't use it inside the out dir

sed -i -e \
    "s/private = true/private = false/" \
    pesde.toml plugin/bin/pesde.toml

sed -i -e \
    "s/version = \"0.0.0\"/$(grep -P "^version = \".+\"$" pesde.toml)/" \
    plugin/bin/pesde.toml