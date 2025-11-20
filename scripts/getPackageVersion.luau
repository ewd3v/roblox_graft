local fs = require("@lune/fs")
local serde = require("@lune/serde")
local stdio = require("@lune/stdio")

local contents = serde.decode("toml", fs.readFile("pesde.toml"))
stdio.write(contents.version)
