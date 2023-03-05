require("lsp_lines").setup()

-- remove the default vtext
vim.diagnostic.config({
  virtual_text = false,
})

-- set keymap
vim.keymap.set(
  "",
  "<Leader>l",
  require("lsp_lines").toggle,
  { desc = "Toggle lsp_lines" }
)
