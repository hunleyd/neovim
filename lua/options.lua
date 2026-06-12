-------------------------------------------------------------------------------
-- EDITOR OPTIONS
-------------------------------------------------------------------------------
-- This file defines the core behavior and aesthetics of Neovim.
-- Note: Many "sane defaults" (like syntax on, smartindent, etc.) are implicitly
-- handled by 'mini.basics' over in plugins.lua.
-------------------------------------------------------------------------------

local opt = vim.opt

-- 1. CURSOR & MOUSE
-- Keep the cursor as a solid block (or terminal default) in all modes.
-- Why: Prevents the cursor from shifting to a thin line in Insert mode,
-- which some users find jarring or difficult to track.
opt.guicursor = ""
-- Disable mouse usage entirely.
-- Why: This is a strict enforcement mechanism to build "no-mouse" keyboard habits,
-- which ultimately leads to faster and more ergonomic editing.
opt.mouse = ""

-- 2. EDITING BEHAVIOR
-- When you press backspace over 4 spaces that act as a tab, delete all 4.
-- Why: Ensures that even when using spaces for indentation, backspacing feels
-- exactly like deleting a single tab character.
opt.softtabstop = 4
-- Persistent Undo: Save undo history to a file so it survives Neovim restarts.
-- Why: You can close a file, turn off your computer, come back the next day,
-- and still press 'u' to undo changes made yesterday.
opt.undodir = os.getenv("HOME") .. "/.local/state/nvim/undo"

-- 3. SEARCH
-- Enable search highlighting. 
-- Why: Makes it obvious where all matches are in the document.
-- We also load the native 'nohlsearch' package which automatically clears
-- these highlights after a timeout or when entering Insert mode, preventing
-- the screen from staying permanently yellow.
opt.hlsearch = true
vim.cmd('packadd nohlsearch')

-- Load native 'matchit' package.
-- Why: Enhances the '%' key to jump between matching HTML tags, if/endif
-- blocks, and other language-specific pairs, rather than just basic brackets.
vim.cmd('packadd matchit')

-- Load native 'justify' package.
-- Why: Enables native text alignment commands (:Justify, :Center, :Right)
-- which are extremely useful for formatting documentation or comments.
vim.cmd('packadd justify')

-- 4. DISPLAY & UI
-- scrolloff: Keep 8 lines of context above/below the cursor when scrolling.
-- Why: Prevents you from ever typing at the absolute top or bottom edge of 
-- the screen, giving you visual context of what's coming up.
opt.scrolloff = 8
-- winborder: Apply modern rounded borders to all native floating windows.
-- Why: Creates a softer, more modern aesthetic (e.g., for LSP hover docs).
opt.winborder = "rounded"
-- isfname: Include '@' in what Neovim considers a "filename".
-- Why: Allows you to use 'gf' (goto file) on paths that include the '@' symbol,
-- which is common in modern JavaScript/TypeScript project imports.
opt.isfname:append("@-@")
-- laststatus: Use a single global statusline spanning the entire bottom of the screen.
-- Why: Cleaner than having a separate statusline for every vertical split window.
opt.laststatus = 3
-- cmdheight: Set to 0 to completely hide the traditional command line at the bottom.
-- Why: We use 'tiny-cmdline' and 'ui2' to put commands in floating windows.
-- Hiding the native cmdline reclaims screen real estate and looks much cleaner.
opt.cmdheight = 0

-- 5. PERFORMANCE & LIMITS
-- How often (in ms) to write the swap file and trigger the 'CursorHold' event.
-- Why: A low value (50ms) ensures UI plugins (like hover diagnostics or Git signs)
-- feel instantaneous rather than waiting for standard 4-second delay.
opt.updatetime = 50
-- Draw a vertical line at 80 characters.
-- Why: Acts as a soft visual guide to encourage keeping line lengths manageable.
opt.colorcolumn = "80"
-- jumpoptions: Use "view" to preserve the scroll position when jumping around.
-- Why: When you use `<C-o>` to jump back to a previous file, the screen won't
-- jarringly recenter itself; it will look exactly as you left it.
opt.jumpoptions = "view"

-- 6. SPELLCHECKING
-- Enable built-in spellchecking.
-- We include 'en_us' for standard English and 'programming' (from vim-dirtytalk).
-- Why: The 'programming' dictionary prevents common code terms (like 'bufnr', 
-- 'cmd', 'alloc') from being incorrectly flagged as spelling errors.
opt.spell = true
opt.spelllang = { "en_us", "programming" }

-------------------------------------------------------------------------------
-- HANDLED BY MINI.BASICS (options.basic = true):
-------------------------------------------------------------------------------
-- For transparency, these settings are active but managed by the plugin:
-- number/relativenumber: Line numbers.
-- tabstop/shiftwidth: Indentation size (4).
-- expandtab: Use spaces instead of tabs.
-- smartindent: Logic-aware indentation.
-- wrap: Wrap long lines.
-- swapfile/backup/undofile: File safety and history.
-- incsearch: Show matches as you type.
-- termguicolors: Support 24-bit colors.
-- signcolumn: The left gutter for git/LSP icons.
-------------------------------------------------------------------------------
