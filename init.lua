-- Neovim Configuration Entry Point
-- Migrated from Vim to Lua by Claude Code
-- Migration Date: 2026-02-04

-- Set leader keys early (before any mappings)
vim.g.mapleader = ","
vim.g.maplocalleader = ","

-- Load core configuration
require("core")

-- Bootstrap and load plugins (lazy.nvim)
require("plugins")

-- Load colorscheme
local ok, tinted = pcall(require, 'colorscheme.tinted')
if ok then
    pcall(tinted.setup)
end

