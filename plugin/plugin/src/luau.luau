-- Downloads from https://github.com/RadiatedExodus/LuauCeption while building
return {
	luau_compile = function()
		error("Use build script when building plugin")
	end,
} :: {
	luau_compile: (
		src: string,
		optLevel: number?,
		dbgLevel: number?,
		typInfLevel: number?,
		covLevel: number?
	) -> (string, number),
}
