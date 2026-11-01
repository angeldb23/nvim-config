if vim.g.vscode then return end
vim.api.nvim_create_autocmd("FileType", {
  callback = function(ev) pcall(vim.treesitter.start, ev.buf) end,
})
