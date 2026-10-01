-- LSP Configuration
vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			runtime = {
				version = "LuaJIT",
			},
			diagnostics = {
				globals = {
					"vim",
				},
			},
			workspace = {
				checkThirdParty = false,
				library = {
					vim.env.VIMRUNTIME,
				},
			},
			telemetry = {
				enable = false,
			},
			hint = {
				arrayIndex = "Disable",
			},
		},
	},
})

-- NOTA: no hay vim.lsp.enable() fijo.
-- Los servidores se habilitan solos según el filetype (sección de abajo).

-- Diagnostics
vim.diagnostic.config({
	virtual_text = {
		spacing = 4,
		source = "if_many",
	},
	signs = {
		text = {
			ERROR = "󰅚",
			WARN = "󰀪",
			INFO = "󰋽",
			HINT = "",
		},
	},
	underline = true,
	update_in_insert = false,
	severity_sort = true,
	float = {
		border = "rounded",
		source = "if_many",
		header = "",
		prefix = "",
	},
	jump = {
		on_jump = function(diagnostic, bufnr)
			if not diagnostic then
				return
			end
			vim.diagnostic.open_float(bufnr, {
				border = "rounded",
				source = "if_many",
				focus = false,
			})
		end,
	},
})

--------------------------------------------------------
-- Auto-instalación y habilitación de LSP por filetype
--------------------------------------------------------
local servers_by_ft = {
	lua = { mason = "lua-language-server", lsp = "lua_ls" },
	python = { mason = "pyright", lsp = "pyright" },
	c = { mason = "clangd", lsp = "clangd" },
	cpp = { mason = "clangd", lsp = "clangd" },
	java = { mason = "jdtls", lsp = "jdtls" },
	sh = { mason = "bash-language-server", lsp = "bashls" },
	json = { mason = "json-lsp", lsp = "jsonls" },
	html = { mason = "html-lsp", lsp = "html" },
	css = { mason = "css-lsp", lsp = "cssls" },
	markdown = { mason = "marksman", lsp = "marksman" },
	-- cs = { mason = "csharp-language-server", lsp = "csharp_ls" }, -- roto upstream
}

local enabled = {}

vim.api.nvim_create_autocmd("FileType", {
	callback = function(ev)
		local entry = servers_by_ft[ev.match]
		if not entry or enabled[entry.lsp] then
			return
		end
		enabled[entry.lsp] = true

		local ok, registry = pcall(require, "mason-registry")
		if not ok then
			vim.lsp.enable(entry.lsp)
			return
		end

		local ok_pkg, pkg = pcall(registry.get_package, entry.mason)
		if not ok_pkg then
			vim.lsp.enable(entry.lsp)
			return
		end

		if pkg:is_installed() then
			vim.lsp.enable(entry.lsp)
			return
		end

		vim.notify("LSP: instalando " .. entry.mason .. " en segundo plano…", vim.log.levels.INFO)
		pkg:install()
		pkg:once("installed", function()
			vim.schedule(function()
				vim.lsp.enable(entry.lsp)
				vim.notify("LSP: " .. entry.lsp .. " listo (" .. ev.match .. ")", vim.log.levels.INFO)
			end)
		end)
		pkg:once("failed", function()
			vim.schedule(function()
				enabled[entry.lsp] = nil
				vim.notify("LSP: falló la instalación de " .. entry.mason, vim.log.levels.ERROR)
			end)
		end)
	end,
})

-- LSP Attach
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(event)
		local bufnr = event.buf
		local client = vim.lsp.get_client_by_id(event.data.client_id)
		if not client then
			return
		end

		local opts = function(desc)
			return {
				buffer = bufnr,
				silent = true,
				desc = desc,
			}
		end

		vim.keymap.set("n", "K", function()
			vim.lsp.buf.hover({
				border = "rounded",
			})
		end, opts("Hover"))

		vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts("Go to Definition"))
		vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts("Go to Declaration"))
		vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts("Go to Implementation"))
		vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, opts("Go to Type Definition"))
		vim.keymap.set("n", "gr", vim.lsp.buf.references, opts("References"))

		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts("Rename"))
		vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts("Code Action"))
		vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, opts("Signature Help"))

		-- Inlay hints: apagados por defecto. <leader>lh los activa cuando quieras.
		if client:supports_method("textDocument/documentHighlight") then
			vim.api.nvim_create_autocmd({
				"CursorHold",
				"CursorHoldI",
			}, {
				buffer = bufnr,
				callback = function()
					vim.lsp.buf.document_highlight()
				end,
			})
			vim.api.nvim_create_autocmd({
				"CursorMoved",
				"CursorMovedI",
			}, {
				buffer = bufnr,
				callback = function()
					vim.lsp.buf.clear_references()
				end,
			})
		end
	end,
})

-- Diagnostic Navigation
vim.keymap.set("n", "[d", function()
	vim.diagnostic.jump({
		count = -1,
	})
end, {
	desc = "Previous Diagnostic",
})
vim.keymap.set("n", "]d", function()
	vim.diagnostic.jump({
		count = 1,
	})
end, {
	desc = "Next Diagnostic",
})

-- Diagnostic Float
vim.keymap.set("n", "<leader>ld", function()
	vim.diagnostic.open_float(nil, {
		border = "rounded",
		source = "if_many",
		focus = true,
	})
end, {
	desc = "Line Diagnostics",
})

-- Toggle Inlay Hints
vim.keymap.set("n", "<leader>lh", function()
	if not vim.lsp.inlay_hint then
		return
	end
	vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, {
	desc = "Toggle Inlay Hints",
})

-- LSP Information
vim.keymap.set("n", "<leader>li", "<cmd>LspInfo<cr>", {
	desc = "LSP Info",
})
