local EncodingService = game:GetService("EncodingService")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Graft = require("@pkg/graft")

local graftData = ServerStorage:WaitForChild("__Graft", 3)

local canGraft = false
if not RunService:IsStudio() then
	print("[Graft] Can't graft (not running in studio)")
elseif graftData == nil then
	print("[Graft] Can't graft (plugin not found)")
elseif graftData:GetAttribute("Activated") ~= true then
	print("[Graft] Can't graft (plugin not activated)")
else
	print("[Graft] Can graft")
	canGraft = true
end

--[=[
	@class GraftExtension

	@external Graft https://github.com/ewd3v/luau_graft
	@external Interface https://github.com/ewd3v/luau_graft/blob/main/src/interface.luau

	An extension class for [Graft].
	Inherits from [Graft].
]=]

local GraftExtension = setmetatable({}, Graft) :: impl
GraftExtension.__index = GraftExtension

export type proto = {
	_watchConnection: RBXScriptConnection,
} & Graft.proto
export type impl = typeof(setmetatable(
	{} :: {
		__index: impl,

		new: (source: string?, module: Module?) -> GraftExtension,

		CanGraft: () -> boolean,
	},
	Graft
))

export type GraftExtension = typeof(setmetatable({} :: proto, GraftExtension)) & Graft.Graft

--[=[
	@within GraftExtension
	@type Module ModuleScript | Script

	A Roblox script.
]=]
export type Module = ModuleScript | Script

local function isModule(module: Module | any): boolean
	return typeof(module) == "Instance" and (module:IsA("ModuleScript") or module:IsA("Script"))
end

local function getModule(level: number?): Module?
	local offsetLevel = (level or 1) + 1

	do
		local env = getfenv(offsetLevel)
		local script = env and rawget(env, "script")
		if isModule(script) then
			return script
		end
	end

	do
		local source = debug.info(offsetLevel, "s")
		local sourcePath = string.split(source, ".")

		local current: Instance? = game
		while current and #sourcePath > 0 do
			local childName = {}
			local child: Instance?
			while not child and #sourcePath > 0 do
				table.insert(childName, table.remove(sourcePath, 1))
				child = current:FindFirstChild(table.concat(childName, "."))
			end

			current = child
		end

		if isModule(current) then
			return current :: any
		end
	end

	return nil
end

local function getModuleFolder(module: Module): Folder
	assert(graftData, "Graft data not found")

	local folderName = module:GetFullName()
	local foundFolder = graftData:FindFirstChild(folderName)
	if foundFolder then
		return foundFolder
	end

	local folder = Instance.new("Folder")
	folder.Archivable = false
	folder.Name = folderName
	folder.Parent = graftData

	return folder
end

local function getModuleData(module: Module): StringValue
	local folder = getModuleFolder(module)
	for _, objectValue in ipairs(folder:GetChildren()) do
		if not objectValue:IsA("ObjectValue") or objectValue.Value ~= module :: Instance then
			continue
		end

		return assert(
			objectValue:FindFirstChildOfClass("StringValue"),
			`Can't find string value in {objectValue:GetFullName()}`
		)
	end

	local objectValue = Instance.new("ObjectValue")
	objectValue.Archivable = false
	objectValue.Name = "module"
	objectValue.Value = module

	local stringValue = Instance.new("StringValue")
	stringValue.Archivable = false
	stringValue.Name = "bytecode"
	stringValue.Parent = objectValue

	module.Destroying:Once(function()
		objectValue:Destroy()
		if #folder:GetChildren() == 0 then
			folder:Destroy()
		end
	end)

	objectValue.Parent = folder
	return stringValue
end

local function getBytecodeWrapperForModule(module: Module): (() -> buffer, RBXScriptSignal)
	local moduleData = getModuleData(module)
	return function()
		local value = moduleData.Value
		if #value == 0 then
			error("not ready")
		end

		local algorithm = tonumber(moduleData:GetAttribute("CompressionAlgorithm")) or 0
		return EncodingService:DecompressBuffer(
			EncodingService:Base64Decode(buffer.fromstring(value)),
			-- selene: allow(incorrect_standard_library_use) -- Check: https://github.com/Kampfkarren/selene/issues/619
			Enum.CompressionAlgorithm:FromValue(algorithm)
		)
	end,
		moduleData.Changed
end

--[=[
	Creates a new [Graft] object with an [Interface] that works for Roblox.

	Also sets up a watcher thread that will automatically hot reload the Luau module when changes are detected.

	@error "Can't graft." -- Is thrown if Graft.CanGraft returns false. Check the return of that function before calling this function.
	@error "Failed to get module." -- Is thrown when the constructor is unable to automatically determine the path to the currently running script.
]=]
function GraftExtension.new(source: string?, module: Module?): GraftExtension
	assert(GraftExtension.CanGraft(), "Can't graft.")

	local gotModule = assert(module or getModule(2), "Failed to get module.")
	local getBytecode, bytecodeUpdated = getBytecodeWrapperForModule(gotModule)

	local self: GraftExtension = setmetatable(
		Graft.new({
			GetBytecode = getBytecode,
		}, source or debug.info(2, "s")) :: any,
		GraftExtension
	)

	self._watchConnection = bytecodeUpdated:Connect(function()
		self:Patch()
	end)

	return self
end

--[=[
	Returns true if hot reloading is currently supported.  
	This should always be checked before attempting to use [Graft.new].

	Reasons for why this function may return false:
	- The Roblox Studio plugin isn't installed (use the CLI to install).
	- The Roblox Studio plugin isn't activated (activate from the plugin tab).
	- The running environment isn't Roblox Studio.
]=]
function GraftExtension.CanGraft(): boolean
	return canGraft
end

return GraftExtension
