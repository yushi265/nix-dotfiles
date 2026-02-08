require("lazy").setup({
  spec = {
    { "AstroNvim/AstroNvim", version = "^5", import = "astronvim.plugins" },
    { import = "community" },
    { import = "plugins" },
  },
  defaults = { lazy = false },
  install = { colorscheme = { "catppuccin", "astrodark", "habamax" } },
  checker = { enabled = true },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip", "netrwPlugin", "tarPlugin", "tohtml", "zipPlugin",
      },
    },
  },
}, {
  lockfile = vim.fn.stdpath "data" .. "/lazy-lock.json",
})
