-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local opt = vim.opt

opt.relativenumber = true -- relative line numbers, easier motions (5j, 3dd)
opt.scrolloff = 8 -- keep context visible when scrolling
opt.wrap = false -- no soft-wrap on long lines
