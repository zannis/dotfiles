-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.wrap = false
vim.opt.sidescroll = 1
vim.opt.sidescrolloff = 8
vim.opt.mousescroll = "ver:3,hor:6"

-- Give the terminal enough time to deliver multi-byte chords like <A-1> = \x1b1
-- before nvim splits ESC and 1 into separate keystrokes.
vim.opt.ttimeoutlen = 50
