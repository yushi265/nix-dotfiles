vim.opt.termguicolors = true
vim.opt.background = "dark"
vim.opt.encoding = "utf-8"
vim.opt.fileencodings = "utf-8,iso-2022-jp,euc-jp,sjis"

-- スペルチェック（cjkで日本語を除外）
local opt = vim.opt
opt.spelllang = { "en", "cjk" }
