require("lsp_lines").setup()

-- remove the default vtext
vim.diagnostic.config({
  virtual_text = false,
})

vim.diagnostic.disable()
vim.cmd [[autocmd CursorHold,CursorHoldI * lua vim.diagnostic.open_float(nil, {focus=false, scope='cursor'})]]

-- set keymap
vim.keymap.set(
  "",
  "<Leader>l",
  require("lsp_lines").toggle,
  { desc = "Toggle lsp_lines" }
)
