-------------------------------------------------------------------------------
-- KEYBINDINGS & EDITING LOGIC
-------------------------------------------------------------------------------
-- This file defines how you interact with the editor. It emphasizes a strict
-- "no-mouse" workflow, utilizing custom mappings to speed up common tasks.
-- Remember: The Leader key is Space.
-------------------------------------------------------------------------------

local keymap = vim.keymap

-- 1. NAVIGATION & GENERAL
-- Open the built-in file explorer (Netrw) to browse the project tree quickly.
keymap.set("n", "<leader>pv", vim.cmd.Ex, { desc = "Project View (Netrw)" })

-- Center the screen when jumping half-pages (Ctrl-d / Ctrl-u).
-- Why: This keeps your eyes focused on the middle of the screen rather than
-- forcing you to track the cursor as it jumps to the top or bottom edges.
keymap.set("n", "<C-d>", "<C-d>zz")
keymap.set("n", "<C-u>", "<C-u>zz")

-- Center the screen when searching through terms (n / N).
-- Why: Similar to page jumps, this ensures the search match you just jumped to
-- is always comfortably centered in your viewport.
keymap.set("n", "n", "nzzzv")
keymap.set("n", "N", "Nzzzv")

-- 2. SMART TEXT MOVEMENT (Visual Mode)
-- Move the highlighted block of text down (J) or up (K).
-- Why: This is vastly superior to cutting and pasting lines. It auto-indents
-- the block as it moves and re-selects it so you can keep moving it fluidly.
keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move block down" })
keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move block up" })

-- 3. CLIPBOARD & REGISTERS
-- "No-overwrite" Paste: In Visual mode, paste over highlighted text without 
-- replacing your current clipboard contents with the deleted text.
-- Why: Standard vim behavior replaces your clipboard when you paste over text,
-- meaning you can't paste the same thing twice. This fixes that.
keymap.set("x", "p", function()
    vim.cmd('normal! "_dP')
    highlight_paste() -- See visual feedback logic below
end, { desc = "Paste without overwriting register" })

-- Yank to System Clipboard: Explicitly use leader to interact with the OS clipboard.
-- Why: This separates Neovim's internal clipboard ('y') from your system clipboard
-- ('<leader>y'), preventing your OS clipboard from being cluttered with random vim yanks.
keymap.set({"n", "v"}, "<leader>y", [["+y]], { desc = "Yank to system clipboard" })
keymap.set("n", "<leader>Y", [["+Y]], { desc = "Yank line to system clipboard" })

-- Safe Delete: Use leader+d to delete text without yanking it (sends to the "void").
-- Why: Prevents standard deletions from overriding what you currently have ready to paste.
keymap.set({"n", "v"}, "<leader>d", [["_d]], { desc = "Delete without yanking" })

-- 4. UTILITIES
-- Quick Escape: Map Ctrl-c in Insert mode to act exactly like the Escape key.
-- Why: Ctrl-c is often easier to reach than Esc and doesn't trigger InsertLeave autocmds
-- incorrectly like some alternative mappings might.
keymap.set("i", "<C-c>", "<Esc>")

-- Clear Search Highlights: Pressing Escape in Normal mode will clear search highlights.
-- Why: This is a modern, native alternative to installing an "auto-hlsearch" plugin.
keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Fast Formatting: Triggers the active LSP to re-indent and clean up your code.
keymap.set("n", "<leader>f", vim.lsp.buf.format, { desc = "LSP Format" })

-- Granular Auto-Commenting:
-- Vim's formatoptions flag 'o' applies to both lowercase 'o' and uppercase 'O'.
-- Why: You want 'O' (insert line above) to auto-comment, but 'o' (insert line below)
-- to be completely clean. We keep the native behavior for 'O', but map 'o' to immediately
-- clear the line (<C-u>) if a comment leader was inserted.
keymap.set('n', 'o', 'o<C-u>', { desc = 'Insert line below (without auto-commenting)' })

-- 5. PASTE HIGHLIGHTING LOGIC
-- Since Neovim doesn't have "on-paste" highlighting built-in (only on-yank),
-- we use marks to identify the pasted range and apply a temporary visual highlight.
-- Why: This provides immediate visual confirmation of exactly what text was just inserted.
local paste_ns = vim.api.nvim_create_namespace("highlight_paste")

local function highlight_paste()
    -- '[' and ']' marks are automatically set to the start/end of changed text.
    local start_pos = vim.api.nvim_buf_get_mark(0, "[")
    local end_pos = vim.api.nvim_buf_get_mark(0, "]")

    local start_row, start_col = start_pos[1] - 1, start_pos[2]
    local end_row, end_col = end_pos[1] - 1, end_pos[2]

    if start_row < 0 or end_row < 0 then return end

    -- Apply highlight for 300ms using the standard search highlight group
    vim.hl.range(0, paste_ns, "IncSearch", { start_row, start_col }, { end_row, end_col + 1 })
    vim.defer_fn(function()
        if vim.api.nvim_buf_is_valid(0) then
            vim.api.nvim_buf_clear_namespace(0, paste_ns, 0, -1)
        end
    end, 300)
end

-- Hook Normal mode paste commands to trigger the highlight
keymap.set("n", "p", function()
    vim.cmd('normal! p')
    highlight_paste()
end, { desc = "Paste and highlight" })

keymap.set("n", "P", function()
    vim.cmd('normal! P')
    highlight_paste()
end, { desc = "Paste before and highlight" })

-- Hook Terminal/External paste (e.g., pasting from the OS via Ctrl-Shift-V in the terminal)
local default_paste = vim.paste
vim.paste = function(lines, phase)
    local res = default_paste(lines, phase)
    -- Trigger highlight at the end of the paste operation
    if res and (phase == -1 or phase == 3) then
        vim.schedule(highlight_paste)
    end
    return res
end

-- 6. NAVIGATION & OVERVIEW
-- Minimap Navigation: Toggle focus to the code minimap on the right side of the screen.
keymap.set('n', '<leader>mf', function() require('mini.map').toggle_focus() end, { desc = 'MiniMap: Focus' })
