-- https://github.com/ThePrimeagen/init.lua/blob/master/after/plugin/telescope.lua
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<C-p>f', builtin.git_files, {})
vim.keymap.set('n', '<leader>gr', function()
	builtin.grep_string({ search = vim.fn.input("Grep > ") });
end)
vim.keymap.set('n', '<leader>vh', builtin.help_tags, {})
