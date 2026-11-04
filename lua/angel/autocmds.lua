-- Reglas de navegación y directorio de trabajo.

local group = vim.api.nvim_create_augroup("AngelProjectNavigation", { clear = true })

-- Si arranca en ~ o /, ir directo a la carpeta de proyectos.
vim.api.nvim_create_autocmd("VimEnter", {
	group = group,
	callback = function()
		local cwd = vim.uv.cwd()
		if cwd == vim.uv.os_homedir() or cwd == "/" then
			vim.cmd("cd " .. vim.fn.fnameescape(vim.fn.expand("~/Documents/Coding")))
		end
	end,
})

-- Al entrar a un archivo, usar la raíz del proyecto como cwd.
vim.api.nvim_create_autocmd("BufEnter", {
	group = group,
	callback = function(args)
		if vim.bo[args.buf].buftype ~= "" then return end
		local name = vim.api.nvim_buf_get_name(args.buf)
		if name == "" or not vim.uv.fs_stat(name) then return end

		local ok, root = pcall(vim.fs.root, name, {
			".git",
			"package.json",
			"Makefile",
			"pyproject.toml",
			"Cargo.toml",
		})
		if ok and root and root ~= vim.uv.cwd() then
			vim.cmd("cd " .. vim.fn.fnameescape(root))
		end
	end,
})
