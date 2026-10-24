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
        local root = vim.fs.root(args.buf, { ".git", "package.json", "Makefile", "pyproject.toml", "Cargo.toml" })
        if root and root ~= vim.uv.cwd() then
            vim.cmd("cd " .. vim.fn.fnameescape(root))
        end
    end,
})
