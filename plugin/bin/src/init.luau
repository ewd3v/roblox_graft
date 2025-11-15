local argparse = require("@pkg/argparse")
local chalk = require("@pkg/chalk")
local dirs = require("@pkg/dirs")
local pathfs = require("@pkg/pathfs")

local PESDE_ROOT = pathfs.Path.from(_G.PESDE_ROOT)

local cli = argparse("graft", "CLI to manage the Roblox Graft plugin")

do
	local pluginFile = pathfs.FilePath.fromExisting(PESDE_ROOT:join("plugin.rbxm"))
	local localPlugin = pathfs.FilePath.new(
		assert(dirs.configLocalDir(), "Failed to get local config directory"):join(
			"Roblox/Plugins/GraftManagedPlugin.rbxm"
		)
	)

	local plugin = cli:command("plugin", "Plugin related commands")
	do
		local install = plugin:command(
			"install",
			"Installs the plugin in Roblox Studio's local plugins folder. If the plugin is already installed, then this will overwrite the installed one."
		)
		install:action(function()
			localPlugin:writeFile(pluginFile:readFile())
			print(chalk.green("Installed Roblox Studio plugin"))
			print(chalk.dim("(You may need to restart Studio for changes to take affect)"))
		end)
	end

	do
		local uninstall =
			plugin:command("uninstall", "Uninstalls the plugin from Roblox Studio's local plugin folder if it exists.")
		uninstall:action(function()
			if localPlugin:isFile() then
				localPlugin:removeFile()
				print(chalk.green("Uninstalled Roblox Studio plugin"))
				print(chalk.dim("(You may need to restart Studio for changes to take affect)"))
			else
				print(chalk.red("Roblox Studio plugin isn't installed"))
			end
		end)
	end
end

cli:parse()
