return {
  "Isrothy/neominimap.nvim",
  version = "v3.x.x",
  lazy = false,
  keys = {
    { "<leader>nm", "<cmd>Neominimap Toggle<cr>", desc = "Neominimap toggle" },
    { "<leader>nf", "<cmd>Neominimap ToggleFocus<cr>", desc = "Neominimap focus" },
    { "<leader>nr", "<cmd>Neominimap Refresh<cr>", desc = "Neominimap refresh" },
  },
  init = function()
    vim.opt.sidescrolloff = 24
    vim.g.neominimap = {
      auto_enable = false,
      layout = "float",
      float = {
        minimap_width = 20,
        window_border = "none",
      },
      x_multiplier = 2,
      delay = 400,
      click = { enabled = true },
      diagnostic = { enabled = false },
      git = { enabled = false },
    }
  end,
}
