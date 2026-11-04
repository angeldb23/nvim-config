if vim.loader then
	vim.loader.enable()
end

require("angel")
if vim.g.vscode then return end
pcall(require, "angel.transparent")
