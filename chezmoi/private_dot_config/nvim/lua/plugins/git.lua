return {
  -- Gitsigns設定をオーバーライド
  {
    "lewis6991/gitsigns.nvim",
    opts = function(_, opts)
      -- LazyVimデフォルトのon_attachをオーバーライド
      opts.on_attach = function(buffer)
        local gs = require("gitsigns")

        local function map(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
        end

        -- AstroVim風のキーマッピング（<leader>g* 直下）
        map("n", "<leader>gs", gs.stage_hunk, "Stage Hunk")
        map("n", "<leader>gr", gs.reset_hunk, "Reset Hunk")
        map("n", "<leader>gS", gs.stage_buffer, "Stage Buffer")
        map("n", "<leader>gu", gs.undo_stage_hunk, "Undo Stage Hunk")
        map("n", "<leader>gR", gs.reset_buffer, "Reset Buffer")
        map("n", "<leader>gp", gs.preview_hunk_inline, "Preview Hunk")
        map("n", "<leader>gl", function()
          gs.blame_line({ full = true })
        end, "Blame Line")
        map("n", "<leader>gL", gs.blame, "Blame Buffer")
        map("n", "<leader>gd", gs.diffthis, "Diff This")
        map("n", "<leader>gD", function()
          gs.diffthis("~")
        end, "Diff This ~")

        -- ビジュアルモード
        map("v", "<leader>gs", function()
          gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Stage Hunk")
        map("v", "<leader>gr", function()
          gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Reset Hunk")

        -- Hunk移動（]h/[hは維持）
        map("n", "]h", function()
          if vim.wo.diff then
            return "]c"
          end
          vim.schedule(function()
            gs.next_hunk()
          end)
          return "<Ignore>"
        end, "Next Hunk")
        map("n", "[h", function()
          if vim.wo.diff then
            return "[c"
          end
          vim.schedule(function()
            gs.prev_hunk()
          end)
          return "<Ignore>"
        end, "Prev Hunk")

        -- テキストオブジェクト
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
      end
    end,
  },

  -- LazyVimのデフォルトgitキーを無効化（競合防止）
  {
    "folke/snacks.nvim",
    keys = {
      -- <leader>gbを無効化してTelescope用に解放
      { "<leader>gb", false },
      -- Git Browseを<leader>gBに移動
      { "<leader>gB", function() Snacks.gitbrowse() end, desc = "Git Browse", mode = { "n", "v" } },
    },
  },
}
