require('mini.tabline').setup({
    show_icons = false,
    set_vim_settings = true,
})
vim.api.nvim_set_hl(0, "MiniTablineModifiedHidden", { link = 'DiffChange' })
vim.api.nvim_create_autocmd('BufEnter', {
  callback = vim.schedule_wrap(function()
    local n_listed_bufs = 0
    for _, buf_id in ipairs(vim.api.nvim_list_bufs()) do
      if vim.fn.buflisted(buf_id) == 1 then n_listed_bufs = n_listed_bufs + 1 end
    end

    vim.o.tabline = n_listed_bufs > 1 and '%!v:lua.MiniTabline.make_tabline_string()' or ' '
  end),
  desc = 'Update tabline based on the number of listed buffers',
})
