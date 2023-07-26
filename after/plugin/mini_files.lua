require('mini.files').setup({
    mappings = {
        close       = 'q',
        go_in       = 'l',
        go_in_plus  = '<CR>',
        go_out      = 'h',
        go_out_plus = 'H',
        reset       = '<BS>',
        show_help   = 'g?',
        synchronize = '=',
        trim_left   = '<',
        trim_right  = '>',
    },
})

local minifiles_toggle = function(...)
  if not MiniFiles.close() then MiniFiles.open(...) end
end
vim.keymap.set("n", "<leader>cd", minifiles_toggle)
