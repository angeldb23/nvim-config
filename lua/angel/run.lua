-- Runner: compilar/ejecutar el archivo actual en la terminal integrada
local runners = {
	cpp = function(file)
		local out = "/tmp/" .. vim.fn.fnamemodify(file, ":t:r")
		return "g++ -std=c++23 -Wall '" .. file .. "' -o '" .. out .. "' && '" .. out .. "'"
	end,
	c = function(file)
		local out = "/tmp/" .. vim.fn.fnamemodify(file, ":t:r")
		return "gcc -std=c11 -Wall '" .. file .. "' -o '" .. out .. "' && '" .. out .. "'"
	end,
	python = function(file)
		return "python3 '" .. file .. "'"
	end,
	lua = function(file)
		return "nvim -l '" .. file .. "'"
	end,
	sh = function(file)
		return "bash '" .. file .. "'"
	end,
}

local function run()
	local file = vim.fn.expand("%:p")
	if file ~= "" and require("angel.cmake").try_run(file) then return end
	local ft = vim.bo.filetype
	local build = runners[ft]
	if not build then
		vim.notify("Sin runner para el filetype: " .. (ft == "" and "(vacío)" or ft), vim.log.levels.WARN)
		return
	end
	vim.cmd("silent! write")
	require("angel.terminal").run_cmd(build(file))
end

vim.keymap.set("n", "<leader>r", run, { desc = "Run / Compile current file" })

vim.keymap.set("n", "<leader>b", function()
	local file = vim.fn.expand("%:p")
	if file ~= "" and require("angel.cmake").build_existing(file) then return end
	vim.notify("No encontré un proyecto CMake en este archivo.", vim.log.levels.INFO)
end, { desc = "Build CMake project" })

-- Handler del boton Run (el boton vive en la winbar de lualine, plugins/ui.lua)
function _G.AngelRunClick()
	run()
end
