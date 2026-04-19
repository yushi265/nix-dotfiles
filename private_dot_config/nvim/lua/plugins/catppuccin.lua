return {
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "catppuccin" },
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = false,
      term_colors = true,
      integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        treesitter = true,
        notify = true,
        mini = true,
        telescope = { enabled = true },
        native_lsp = { enabled = true },
      },
      custom_highlights = function(colors)
        return {
          Normal = { bg = "#000000" },
          NonText = { bg = "#000000" },
          NormalFloat = { bg = "#000000" },
        }
      end,
    },
  },
}
