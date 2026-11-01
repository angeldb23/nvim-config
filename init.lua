require("angel")
if vim.g.vscode then return end
pcall(require, "angel.transparent")

-- Si arranca en ~ o /, ir directo a tu carpeta de proyectos
vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        local cwd = vim.uv.cwd()
        if cwd == vim.uv.os_homedir() or cwd == "/" then
            vim.cmd("cd " .. vim.fn.expand("~/Documents/Coding"))
        end
    end,
})

-- Al entrar a un archivo, ir a la raíz de su proyecto
vim.api.nvim_create_autocmd("BufEnter", {
    callback = function(args)
        if vim.bo[args.buf].buftype ~= "" then return end
        local name = vim.api.nvim_buf_get_name(args.buf)
        if name == "" or not vim.uv.fs_stat(name) then return end
        local ok, root = pcall(vim.fs.root, name, { ".git", "package.json", "Makefile", "pyproject.toml", "Cargo.toml" })
        if not ok then return end
        if root and root ~= vim.uv.cwd() then
            vim.cmd("cd " .. vim.fn.fnameescape(root))
        end
    end,
})

-- minimap sixel: tira angosta estilo VSCode (letra 2x4, 12 columnas de ancho)
vim.g.sixel_minimap = { preset = "vscode", cols = 12 }

-- Minimap Sixel: preset legible en tira angosta
vim.g.sixel_minimap = {
  preset = 'medio',
  cols = 14,
}
