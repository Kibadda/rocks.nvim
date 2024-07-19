--  _  __ _  _               _     _
-- | |/ /(_)| |__   __ _  __| | __| | __ _
-- | ' / | || ´_ \ / _` |/ _` |/ _` |/ _` |
-- | . \ | || |_) | (_| | (_| | (_| | (_| |
-- |_|\_\|_||_⹁__/ \__,_|\__,_|\__,_|\__,_|

vim.g.mapleader = vim.keycode "<Space>"

vim.loader.enable()

vim.cmd.colorscheme "gruvbox"

local set = vim.keymap.set
---@diagnostic disable-next-line:duplicate-set-field
function vim.keymap.set(mode, lhs, rhs, opts)
  opts = opts or {}
  opts.silent = opts.silent ~= false
  set(mode, lhs, rhs, opts)
end

vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0

require "me.lazy"
