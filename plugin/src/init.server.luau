local isEdit = game:GetService("RunService"):IsEdit()

local ACTIVATED_SETTING = "Activated"
local activated = plugin:GetSetting(ACTIVATED_SETTING) or false

local toolbar = plugin:CreateToolbar("Graft")

local activateButton = toolbar:CreateButton(
	"Graft",
	"Toggles whether if Graft should be activated or not when running the game",
	"rbxassetid://14978048121"
)
activateButton.Enabled = isEdit

local function setActivated(active: boolean)
	activated = active
	activateButton:SetActive(active)
	plugin:SetSetting(ACTIVATED_SETTING, active)
end

setActivated(activated)
activateButton.Click:Connect(function()
	setActivated(not activated)
end)

if not isEdit then
	require("@self/runtime")(activated)
end
