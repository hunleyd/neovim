-- https://github.com/ThePrimeagen/init.lua/blob/master/lua/theprimeagen/init.lua
-- but not really
require("hunleyd.lazy")
require("hunleyd.remap")
require("hunleyd.set")
require("hunleyd.autocmd")

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
local yank_group = augroup('HighlightYank', {})
autocmd('TextYankPost', {
    group = yank_group,
    pattern = '*',
    callback = function()
        vim.highlight.on_yank({
            higroup = 'IncSearch',
            timeout = 40,
        })
    end,
})

vim.diagnostic.config({
  virtual_text = true,
  virtual_lines = { current_line = true },
  underline = true,
  update_in_insert = false
})

vim.cmd.colorscheme [[glowbeam]]
