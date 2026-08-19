return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = {
      flavour = "mocha",
      term_colors = true,
      integrations = {
        blink_cmp = true,
        gitsigns = true,
        mason = true,
        noice = true,
        notify = true,
        treesitter = true,
        which_key = true,
      },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "system-theme",
    },
  },
}
