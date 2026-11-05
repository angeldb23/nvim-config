if vim.g.vscode then return end

-- Búsqueda: ignora mayúsculas salvo que escribas una
vim.o.ignorecase = true
vim.o.smartcase = true

-- Resaltar lo copiado
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function() vim.hl.on_yank({ timeout = 150 }) end,
})

-- Volver a la última posición al reabrir un archivo
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function(ev)
    if vim.bo[ev.buf].buftype ~= "" then return end
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(ev.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Esc limpia el resaltado de búsqueda
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- < y > en visual mantienen la selección
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- Fix: Ctrl+A en insert escribía "ggVG" como texto
vim.keymap.set("i", "<C-a>", "<Esc>ggVG", { desc = "Select All" })

