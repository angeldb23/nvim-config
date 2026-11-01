return {
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      indent = { char = "│" },
      scope = { show_start = false, show_end = false },
    },
  },

  {
    "folke/flash.nvim",
    keys = {
      {
        "<leader>j",
        function() require("flash").jump() end,
        mode = { "n", "x", "o" },
        desc = "Flash jump",
      },
    },
    opts = {},
  },

  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "make",
    dependencies = { "nvim-telescope/telescope.nvim" },
    event = "VeryLazy",
    config = function()
      pcall(require("telescope").load_extension, "fzf")
    end,
  },
}
