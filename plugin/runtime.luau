local EncodingService = game:GetService("EncodingService")
local ServerStorage = game:GetService("ServerStorage")

local luau = require("./luau")

local COMPRESSION_ALGORITHM = Enum.CompressionAlgorithm.Zstd

local function handleModule(objectValue: ObjectValue | Instance)
	if not objectValue:IsA("ObjectValue") then
		return
	end

	local stringValue = objectValue:FindFirstChildOfClass("StringValue")
	if not stringValue then
		return
	end

	local module = objectValue.Value :: ModuleScript | Script
	local function updateBytecode()
		local bytecode = buffer.fromstring((luau.luau_compile(module.Source)))
		stringValue:SetAttribute("CompressionAlgorithm", COMPRESSION_ALGORITHM.Value)
		stringValue.Value = buffer.tostring(
			EncodingService:Base64Encode(EncodingService:CompressBuffer(bytecode, COMPRESSION_ALGORITHM))
		)
	end

	module:GetPropertyChangedSignal("Source"):Connect(updateBytecode)
	updateBytecode()
end

return function(activated: boolean)
	local scriptData = Instance.new("Folder")
	scriptData.Archivable = false
	scriptData.Name = "__Graft"
	scriptData:SetAttribute("Activated", activated)
	scriptData.DescendantAdded:Connect(handleModule)
	scriptData.Parent = ServerStorage
end
