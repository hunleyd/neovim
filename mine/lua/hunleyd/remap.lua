-- https://github.com/ThePrimeagen/init.lua/blob/master/lua/theprimeagen/remap.lua

-- leader moved to lazy.lua
-- vim.keymap.set("n", "<leader>cd", vim.cmd.Ex) -- is <leader>pv upstream

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- greatest remap ever (paste w/o overwriting the paste buffer)
vim.keymap.set("x", "<leader>p", [["_dP]])

-- next greatest remap ever : (y to yank to vim, leader-Y to yank to system)
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])

-- This is going to get me canceled
vim.keymap.set("i", "<C-c>", "<Esc>")

vim.keymap.set("n", "Q", "<nop>")
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)

vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

-- my shit
vim.keymap.set("n", "\\\\", ":term<CR>")
vim.keymap.set("n", "cd", ":lua MiniFiles.open()<CR>")
vim.keymap.set("n", "ycc", "yygccp", { remap = true })


-- lsp diagnostics
local opts = { noremap = true, silent = true }
vim.keymap.set(
	"n",
	"gl",
	vim.diagnostic.setloclist,
	vim.tbl_extend("force", opts, { desc = "send diagnostics to loc list" })
)

-- YankBank
vim.keymap.set("n", "<leader>y", "<cmd>YankBank<CR>", { noremap = true })

-- Atone
vim.keymap.set("n", "<leader>u", "<cmd>Atone toggle<CR>", { noremap = true })
