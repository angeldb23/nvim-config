return {
  { "nvim-telescope/telescope.nvim", cmd = "Telescope" },
  { "nvim-neo-tree/neo-tree.nvim", cmd = "Neotree" },
  { "lewis6991/gitsigns.nvim", event = { "BufReadPre", "BufNewFile" } },
  { "stevearc/conform.nvim", event = "BufWritePre", cmd = "ConformInfo" },
}
