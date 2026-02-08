return {
  -- yazi.nvim (use <leader>y to open)
  {
    "mikavilpas/yazi.nvim",
    event = "VeryLazy",
    keys = {
      { "<leader>y", "<cmd>Yazi<cr>", desc = "Open yazi at current file" },
      { "<leader>Y", "<cmd>Yazi cwd<cr>", desc = "Open yazi in cwd" },
    },
    opts = {
      open_for_directories = false,
    },
  },
}
