-- Integrated Terminal (nativa, cero plugins)
-- <leader>tt horizontal abajo | <leader>tv vertical a la derecha

local term = { buf = nil, win = nil, vertical = false }

local function terminal_open(vertical)
	if vertical then
		vim.cmd("belowright vsplit")
		vim.api.nvim_win_set_width(vim.api.nvim_get_current_win(), math.max(40, math.floor(vim.o.columns * 0.35)))
	else
		vim.cmd("belowright split")
		vim.api.nvim_win_set_height(vim.api.nvim_get_current_win(), 15)
	end
	if term.buf and vim.api.nvim_buf_is_valid(term.buf) then
		vim.api.nvim_win_set_buf(vim.api.nvim_get_current_win(), term.buf)
	else
		vim.cmd("terminal")
		term.buf = vim.api.nvim_get_current_buf()
		vim.bo[term.buf].buflisted = false
	end
	term.win = vim.api.nvim_get_current_win()
	vim.cmd("startinsert")
end

local function terminal_toggle(vertical)
	if term.win and vim.api.nvim_win_is_valid(term.win) then
		vim.api.nvim_win_close(term.win, false)
		term.win = nil
		if term.vertical == vertical then
			return
		end
	end
	term.vertical = vertical
	terminal_open(vertical)
end

vim.keymap.set("n", "<leader>tt", function()
	terminal_toggle(false)
end, { desc = "Toggle Terminal (horizontal)" })

vim.keymap.set("n", "<leader>tv", function()
	terminal_toggle(true)
end, { desc = "Toggle Terminal (vertical)" })

vim.api.nvim_create_autocmd("TermOpen", {
	callback = function(ev)
		vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { buffer = ev.buf })
	end,
})

local M = {}

function M.run_cmd(cmd)
	if not (term.win and vim.api.nvim_win_is_valid(term.win)) then
		terminal_open(false)
	end
	vim.api.nvim_chan_send(vim.bo[term.buf].channel, cmd .. "\n")
end

return M
