require('mini.tabline').setup({
    show_icons = false,
    set_vim_settings = true,
})
vim.api.nvim_set_hl(0, "MiniTablineModifiedHidden", { link = 'DiffChange' })
