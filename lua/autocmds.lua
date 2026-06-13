-------------------------------------------------------------------------------
-- AUTOMATIC COMMANDS (AUTOCMDS)
-------------------------------------------------------------------------------
-- This file defines event-driven logic that triggers automatically in the background.
-------------------------------------------------------------------------------

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- 1. PERSISTENCE
-- When re-opening a file, jump back to the exact cursor position you were at 
-- when you last closed it. This creates a seamless editing experience.
autocmd('BufReadPost', {
    group = augroup('ReturnToLastLocation', { clear = true }),
    callback = function()
        local mark = vim.api.nvim_buf_get_mark(0, '"')
        local lcount = vim.api.nvim_buf_line_count(0)
        -- Only jump if the mark exists and is within current file bounds
        if mark[1] > 0 and mark[1] <= lcount then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})

-- 2. LANGUAGE-SPECIFIC LOGIC
-- Ansible Detection: By default, Neovim might treat .yml as generic YAML.
-- We force it to 'yaml.ansible' to trigger specialized Treesitter highlighting,
-- Ansible-specific LSP features, and enable 'ansible-doc' via the 'K' mapping.
autocmd({ 'BufNewFile', 'BufReadPost' }, {
    group = augroup('AnsibleFiletype', { clear = true }),
    pattern = '*.yml',
    callback = function()
        vim.bo.filetype = 'yaml.ansible'
        vim.bo.keywordprg = 'ansible-doc'
    end,
})

-- Ansible Formatting: YAML/Ansible strictly requires 2-space indentation.
-- This ensures we don't accidentally use 4 spaces (our global default) and break playbooks.
autocmd('FileType', {
    group = augroup('AnsibleSettings', { clear = true }),
    pattern = 'yaml.ansible',
    callback = function()
        vim.bo.shiftwidth = 2
        vim.bo.tabstop = 2
        vim.bo.softtabstop = 2
        vim.bo.expandtab = true
    end,
})

-- JSON Enforcement: Ensure .json files always use the correct filetype,
-- preventing edge cases where they might be misinterpreted as JavaScript.
autocmd({ 'BufNewFile', 'BufReadPost' }, {
    group = augroup('JsonFiletype', { clear = true }),
    pattern = '*.json',
    command = 'set filetype=json',
})

-- 3. SMART LINE NUMBERS
-- This logic implements "number toggling" without needing an external plugin.
-- Why? Relative numbers are best for fast movement (e.g., '5j') in Normal mode.
-- Absolute numbers are better for reading/reference when actively typing in Insert mode,
-- or when the window loses focus.
local number_toggle_group = augroup('SmartNumbers', { clear = true })

-- Switch to absolute numbers when entering Insert mode or losing focus.
autocmd({ 'BufLeave', 'FocusLost', 'InsertEnter', 'WinLeave' }, {
    group = number_toggle_group,
    pattern = '*',
    callback = function()
        if vim.o.number then
            vim.opt_local.relativenumber = false
        end
    end,
})

-- Switch back to relative numbers when entering Normal mode or gaining focus.
autocmd({ 'BufEnter', 'FocusGained', 'InsertLeave', 'WinEnter' }, {
    group = number_toggle_group,
    pattern = '*',
    callback = function()
        if vim.o.number and vim.api.nvim_get_mode().mode ~= 'i' then
            vim.opt_local.relativenumber = true
        end
    end,
})

-- 4. FLOATING WINDOWS FOR UTILITIES
-- The Treesitter installer usually opens as an ugly split window at the bottom.
-- We intercept the creation of this specific buffer and force it into a centered,
-- rounded floating window to maintain our modern "UI2" aesthetic.
autocmd('BufWinEnter', {
    group = augroup('UtilityFloats', { clear = true }),
    pattern = '__TS_INSTALLER_OUTPUT__',
    callback = function()
        vim.api.nvim_win_set_config(0, {
            relative = 'editor',
            width = math.floor(vim.o.columns * 0.8),
            height = math.floor(vim.o.lines * 0.8),
            row = math.floor(vim.o.lines * 0.1),
            col = math.floor(vim.o.columns * 0.1),
            border = 'rounded',
            title = ' Treesitter Installation ',
            title_pos = 'center',
        })
    end,
})

-- 7. LSP AUTO-ATTACHMENT
-- Automatically attach relevant LSP servers based on filetype.
local lsp_augroup = augroup('LspAutoAttach', { clear = true })

autocmd({'FileType', 'BufEnter'}, {
    group = lsp_augroup,
    pattern = 'lua',
    callback = function() vim.lsp.enable('lua_ls') end,
})

autocmd({'FileType', 'BufEnter'}, {
    group = lsp_augroup,
    pattern = {'sh', 'bash', 'zsh'},
    callback = function()
        if vim.bo.filetype == 'sh' or vim.bo.filetype == 'bash' or vim.bo.filetype == 'zsh' then
            vim.lsp.start({
                name = 'bashls',
                cmd = {'bash-language-server', 'start'},
                root_dir = vim.fs.dirname(vim.fs.find({'.git'}, {upward=true})[1] or vim.fn.expand('%:p:h'))
            })
        end
    end,
})

-------------------------------------------------------------------------------
-- HANDLED BY MINI.BASICS (autocommands.basic = true):
-------------------------------------------------------------------------------
-- For reference, 'mini.basics' is silently handling these essential autocmds:
-- highlight_yank: Briefly highlights text when you copy it.
-- startinsert_terminal: Automatically enters Insert mode when switching to a terminal window.
-- auto_resize: Automatically redistributes window splits when the terminal is resized.
-- auto_create_dir: Automatically creates missing parent folders when saving a new file.
-------------------------------------------------------------------------------
