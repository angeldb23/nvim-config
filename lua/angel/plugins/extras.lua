return {
  {
    "tiagovla/scope.nvim",
    lazy = false,
    config = true,
  },

  {
    "nvim-mini/mini.indentscope",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local indentscope = require("mini.indentscope")
      indentscope.setup({
        draw = {
          delay = 20,
          animation = indentscope.gen_animation.quadratic({ easing = "out", duration = 100, unit = "total" }),
        },
        mappings = {
          object_scope = "",
          object_scope_with_border = "",
          goto_top = "",
          goto_bottom = "",
        },
        options = { border = "both", indent_at_cursor = false, try_as_border = true },
        symbol = "│",
      })
    end,
  },

  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      indent = { char = "│" },
      scope = {
        enabled = false,
      },
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
