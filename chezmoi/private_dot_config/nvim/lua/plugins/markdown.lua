return {
  -- marksman のみ使用
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        marksman = {},
        -- 他のMarkdown関連LSPを無効化
        ltex = { enabled = false },
      },
    },
  },
  -- mason で marksman を自動インストール
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = { "marksman" },
    },
  },
  -- nvim-lint の markdown 関連を無効化
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        markdown = {},
      },
    },
  },
  -- none-ls の markdown 関連を無効化
  {
    "nvimtools/none-ls.nvim",
    optional = true,
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      -- markdownlint などを除外
    end,
  },
  -- ブラウザでMarkdownプレビュー
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = "cd app && npm install",
    keys = {
      { "<leader>cp", "<cmd>MarkdownPreviewToggle<cr>", desc = "Markdown Preview" },
    },
  },
}
