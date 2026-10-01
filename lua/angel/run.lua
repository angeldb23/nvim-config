-- Runner: compilar/ejecutar el archivo actual en la terminal integrada
local runners = {
	cpp = function(file)
		local out = "/tmp/" .. vim.fn.fnamemodify(file, ":t:r")
		return "g++ -std=c++17 -Wall '" .. file .. "' -o '" .. out .. "' && '" .. out .. "'"
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
