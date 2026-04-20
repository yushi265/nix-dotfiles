-- カスタムキーマップはここに追加

-- AstroVim風 Git キーマッピング

-- Hunk移動（AstroVim風の追加キー）
vim.keymap.set("n", "<leader>gj", function()
  require("gitsigns").next_hunk()
end, { desc = "Next Hunk" })
vim.keymap.set("n", "<leader>gk", function()
  require("gitsigns").prev_hunk()
end, { desc = "Prev Hunk" })

-- fzf-lua git pickers
vim.keymap.set("n", "<leader>gb", "<cmd>FzfLua git_branches<cr>", { desc = "Git Branches" })
vim.keymap.set("n", "<leader>gc", "<cmd>FzfLua git_commits<cr>", { desc = "Git Commits" })
vim.keymap.set("n", "<leader>gC", "<cmd>FzfLua git_bcommits<cr>", { desc = "Git Commits (Buffer)" })
vim.keymap.set("n", "<leader>gt", "<cmd>FzfLua git_status<cr>", { desc = "Git Status" })
