-------------------------------------------------------------------------------
-- PLUGIN MANAGEMENT & CONFIGURATION
-------------------------------------------------------------------------------
-- Why a custom plugin manager? 
-- While tools like lazy.nvim are popular, this config is designed to be
-- entirely self-contained, predictable, and immune to the churn of third-party
-- package managers. By implementing our own minimal git-based updater using
-- Neovim's native 'pack/' system, we maintain absolute control over the load 
-- order, ensure lightning-fast synchronous startups, and guarantee the config
-- will never break due to an external manager's API update.
-------------------------------------------------------------------------------

local M = {}

-- 1. PLUGIN LIST
-- Define all desired plugins here. Key is folder name, value is GitHub URL.
local plugins = {
    ["lush.nvim"] = "https://github.com/rktjmp/lush.nvim", -- Dependency for Meowsoot
    ["meowsoot.nvim"] = "https://github.com/marekh19/meowsoot.nvim", -- Colorscheme
    ["nui.nvim"] = "https://github.com/MunifTanjim/nui.nvim", -- UI component library
    ["nvim-treesitter"] = "https://github.com/nvim-treesitter/nvim-treesitter", -- Syntax highlighting
    ["nvim-treesitter-textobjects"] = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
    ["nvim-lspconfig"] = "https://github.com/neovim/nvim-lspconfig", -- Native LSP configs
    ["mini.nvim"] = "https://github.com/echasnovski/mini.nvim", -- Library of modules
    ["mason.nvim"] = "https://github.com/williamboman/mason.nvim", -- LSP installer
    ["mason-lspconfig.nvim"] = "https://github.com/williamboman/mason-lspconfig.nvim", -- Bridge
    ["hardtime.nvim"] = "https://github.com/m4xshen/hardtime.nvim", -- Habit breaker
    ["demicolon.nvim"] = "https://github.com/mawkler/demicolon.nvim", -- Repeatable jumps
    ["nvim-various-textobjs"] = "https://github.com/chrisgrieser/nvim-various-textobjs", -- Extra motions
    ["statuscol.nvim"] = "https://github.com/luukvbaal/statuscol.nvim", -- Enhanced gutter
    ["vim-dirtytalk"] = "https://github.com/psliwka/vim-dirtytalk", -- Programming-aware spellchecker
    ["render-markdown.nvim"] = "https://github.com/MeanderingProgrammer/render-markdown.nvim", -- Pretty markdown
    ["ansible-vim"] = "https://github.com/pearofducks/ansible-vim", -- Ansible filetype detection & syntax
    ["nvim-ansible"] = "https://github.com/mfussenegger/nvim-ansible", -- Ansible workflow utilities
    ["yaml-revealer"] = "https://github.com/Einenlum/yaml-revealer", -- YAML path breadcrumbs
    ["sqlite.lua"] = "https://github.com/kkharji/sqlite.lua", -- Dependency for persistence
    ["yankbank-nvim"] = "https://github.com/ptdewey/yankbank-nvim", -- Clipboard manager
    ["minuet-ai.nvim"] = "https://github.com/milanglacier/minuet-ai.nvim", -- AI completion (Gemini)
    ["tiny-cmdline.nvim"] = "https://github.com/rachartier/tiny-cmdline.nvim", -- Centered command line
}

local pack_path = vim.fn.stdpath("config") .. "/pack/plugins/start"
local state_path = vim.fn.stdpath("data") .. "/plugin_update_state"

-- 1. MANAGEMENT LOGIC

-- Custom fix for vim-dirtytalk to compile its word list silently.
function M.dirtytalk_update_fix()
    local wordlists_dir = vim.fn.stdpath('config') .. '/pack/plugins/start/vim-dirtytalk/wordlists/'
    local wordlists_files = vim.fn.glob(wordlists_dir .. '*.words', true, true)
    local blacklist = vim.g.dirtytalk_blacklist or {}
    local wordlist_full = {}

    for _, filename in ipairs(wordlists_files) do
        local name = vim.fn.fnamemodify(filename, ':t:r')
        local is_blacklisted = false
        for _, b in ipairs(blacklist) do
            if b == name then is_blacklisted = true break end
        end

        if not is_blacklisted then
            local lines = vim.fn.readfile(filename)
            for _, line in ipairs(lines) do
                table.insert(wordlist_full, line)
            end
        end
    end

    local wordlist_output_file = vim.fn.tempname()
    vim.fn.writefile(wordlist_full, wordlist_output_file)
    local spell_dir = vim.fn.stdpath('config') .. '/spell'
    if vim.fn.isdirectory(spell_dir) == 0 then
        vim.fn.mkdir(spell_dir, 'p')
    end

    vim.notify("Dirtytalk: Compiling programming dictionary...")
    -- Run mkspell! silently to avoid pager
    vim.cmd('silent! mkspell! ' .. spell_dir .. '/programming ' .. wordlist_output_file)
    vim.notify("Dirtytalk: Programming dictionary updated.")
end

-- Automatically clone any plugins that are in our list but not on disk.
function M.install_missing()
    local missing_plugins = false
    for name, url in pairs(plugins) do
        local path = pack_path .. "/" .. name
        
        -- Check if it exists AND is a valid git repository
        local is_git_repo = vim.fn.isdirectory(path) == 1 and 
                            vim.fn.system({ "git", "-C", path, "rev-parse", "--is-inside-work-tree" }):match("true")

        if not is_git_repo then
            if vim.fn.isdirectory(path) == 1 then
                vim.notify("Repairing corrupted plugin: " .. name .. "...")
                vim.fn.delete(path, "rf")
            end
            
            missing_plugins = true
            vim.notify("Installing " .. name .. "...")
            vim.fn.system({ "git", "clone", "--depth", "1", "--quiet", url, path })

            -- Special Case: vim-dirtytalk needs to compile its word list after installation.
            if name == "vim-dirtytalk" then
                vim.schedule(function()
                    M.dirtytalk_update_fix()
                end)
            end
        end
    end
    return missing_plugins
end

-- Delete folders in the 'pack/' directory that are no longer in our 'plugins' list.
function M.cleanup_unused()
    local handle = vim.loop.fs_scandir(pack_path)
    if not handle then return end

    while true do
        local name, type = vim.loop.fs_scandir_next(handle)
        if not name then break end
        if type == "directory" and not plugins[name] then
            vim.notify("Cleaning up unused plugin: " .. name)
            vim.fn.delete(pack_path .. "/" .. name, "rf")
        end
    end
end

-- Update all plugins via 'git pull' and refresh Mason packages.
function M.update_plugins()
    vim.notify("Checking for plugin updates...")
    local total = 0
    for _ in pairs(plugins) do total = total + 1 end
    local current = 0

    local on_done = function()
        -- Record current time to state file
        local f = io.open(state_path, "w")
        if f then f:write(os.time()) f:close() end
        
        -- Update Mason registry and packages
        local status_mason, registry = pcall(require, "mason-registry")
        if status_mason then
            vim.notify("Updating Mason registry...")
            registry.update(function(success, updated_registry)
                if success then
                    vim.notify("Mason registry updated. Checking for package updates...")
                    local installed_packages = registry.get_installed_packages()
                    for _, pkg in ipairs(installed_packages) do
                        vim.notify("Updating Mason package: " .. pkg.name .. "...")
                        pkg:install()
                    end
                else
                    vim.notify("Failed to update Mason registry: " .. updated_registry, vim.log.levels.ERROR)
                end
            end)
        end
        vim.notify("Updates initiated. Check :Mason and :TSUpdate for progress.")
        -- Update Treesitter parsers
        pcall(vim.cmd, "TSUpdate")
    end

    for name, _ in pairs(plugins) do
        local path = pack_path .. "/" .. name
        if vim.fn.empty(vim.fn.glob(path)) == 0 then
            vim.system({ "git", "-C", path, "fetch", "origin" }, { text = true }, function(obj)
                if obj.code ~= 0 then
                    vim.notify("Failed to fetch " .. name .. ": " .. (obj.stderr or ""), vim.log.levels.ERROR)
                    return
                end
                vim.system({ "git", "-C", path, "reset", "--hard", "origin/HEAD" }, { text = true }, function(obj)
                    current = current + 1
                    vim.schedule(function()
                        if obj.code == 0 then
                            vim.notify("Updated " .. name)
                            if name == "vim-dirtytalk" then
                                M.dirtytalk_update_fix()
                            end
                        else
                            vim.notify("Failed to reset " .. name .. ": " .. (obj.stderr or ""), vim.log.levels.ERROR)
                        end
                        if current == total then on_done() end
                    end)
                end)
            end)
        else
            current = current + 1
            if current == total then on_done() end
        end
    end
end

-- Prompt for a full update if it's been more than 7 days.
function M.check_for_weekly_update()
    local f = io.open(state_path, "r")
    local last_update = 0
    if f then
        last_update = tonumber(f:read("*all")) or 0
        f:close()
    end

    local week_in_seconds = 7 * 24 * 60 * 60
    if os.time() - last_update > week_in_seconds then
        vim.schedule(function()
            vim.ui.input({ prompt = "Plugins haven't been updated in a week. Update now? (y/n) " }, function(input)
                if input == "y" then M.update_plugins()
                else
                    -- Postpone reminder for 1 day
                    local f_post = io.open(state_path, "w")
                    if f_post then
                        f_post:write(os.time() - (week_in_seconds - 86400))
                        f_post:close()
                    end
                end
            end)
        end)
    end
end

-- 3. SETUP & CONFIGURATION

function M.setup()
    vim.fn.mkdir(pack_path, "p")
    
    -- Sync disk state with our plugin list
    M.cleanup_unused()

    -- If we had to clone anything, stop here so Neovim can load them next time.
    if M.install_missing() then
        vim.notify("Plugins installed. Please restart Neovim.")
        return
    end

    -- Create :PackUpdate command for manual use
    vim.api.nvim_create_user_command("PackUpdate", function() M.update_plugins() end, {})
    vim.api.nvim_create_user_command("PackTSUpdate", function()
        pcall(require, "nvim-treesitter")
        vim.cmd("TSUpdate")
    end, {})
    M.check_for_weekly_update()

    -- 4. PLUGIN-SPECIFIC CONFIGURATIONS

    -- Colorscheme: Apply Meowsoot
    pcall(vim.cmd.colorscheme, "meowsoot")

    M.colors = {
        bg = '#171616',
        bg_1 = '#201f1d',
        bg_2 = '#282625',
        bg_3 = '#353331',
        bg_4 = '#454240',
        fg = '#e2e0df',
        fg_mute = '#b1ada9',
        fg_faint = '#85807a',
        blue = '#96bddf',
        green = '#98cdaa',
        magenta = '#eaa4c9',
        red = '#e99696',
        yellow = '#dfd286',
        peach = '#e3b096',
    }
    local c = M.colors

    -- Treesitter: Structural code understanding and highlighting
    local status_ts, ts_configs = pcall(require, 'nvim-treesitter.configs')
    if status_ts then
        ts_configs.setup {
            -- A list of parser names, or "all"
            ensure_installed = { 
                -- Neovim Basics
                "lua", "vim", "vimdoc", "query",

                -- Automation & Devops
                "bash", "dockerfile", "yaml", "toml", "json",

                -- Scripting & Logic
                "python", "jinja", "jinja_inline",

                -- Documentation & Web
                "markdown", "markdown_inline", "html", "css"
            },
            
            -- Automatically install missing parsers when entering a buffer
            auto_install = true,
            
            -- Enable the advanced syntax highlighting engine
            highlight = { enable = true },
            textobjects = {
                select = {
                    enable = true,
                    lookahead = true, -- Automatically jump to next text object
                    keymaps = {
                        ["af"] = "@function.outer",
                        ["if"] = "@function.inner",
                        ["ac"] = "@class.outer",
                        ["ic"] = "@class.inner",
                    },
                },
                move = {
                    enable = true,
                    set_jumps = true, -- Track jumps in jumplist (Ctrl-o / Ctrl-i)
                    goto_next_start     = { ["]f"] = "@function.outer", ["]c"] = "@class.outer" },
                    goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer" },
                },
            },
        }
        -- Map jinja2 filetype to jinja parser
        vim.treesitter.language.register('jinja', 'jinja2')
    end

    -- Mini.nvim suite: Lightweight modular enhancements
    local status_mini, _ = pcall(require, 'mini.completion')
    if status_mini then
        -- Mini.Ai: Advanced text objects (e.g., 'a(' for around parens, 'ie' for entire buffer).
        local ai = require('mini.ai')
        ai.setup({
            n_lines = 500, -- Look further for matching text objects
            custom_textobjects = {
                -- Treesitter objects: functions, classes, and blocks
                o = ai.gen_spec.treesitter({
                    a = { '@block.outer', '@conditional.outer', '@loop.outer' },
                    i = { '@block.inner', '@conditional.inner', '@loop.inner' },
                }, {}),
                f = ai.gen_spec.treesitter({ a = '@function.outer', i = '@function.inner' }, {}),
                c = ai.gen_spec.treesitter({ a = '@class.outer', i = '@class.inner' }, {}),
            },
        })
        require('mini.align').setup()     -- Text alignment
        require('mini.comment').setup()   -- Line commenting (gcc)
        require('mini.completion').setup({ -- Lightweight autocompletion
            delay = { completion = 100, info = 100 },
            window = { 
                info = { border = 'double' }, 
                signature = { border = 'double' } 
            },
        })

        -- Neovim 0.12 Fuzzy Completion: Enable native fuzzy matching for the popup menu.
        vim.o.completeopt = 'menuone,noselect,fuzzy'

        -- Better CR handling for mini.completion and mini.pairs
        local keymap_cr = function()
            if vim.fn.pumvisible() ~= 0 then
                local item_selected = vim.fn.complete_info({'selected'}).selected ~= -1
                return item_selected and '<C-y>' or '<C-e><CR>'
            end
            return require('mini.pairs').cr()
        end
        vim.keymap.set('i', '<CR>', keymap_cr, { expr = true, replace_keycodes = true })
        require('mini.move').setup()      -- Move selection
        require('mini.operators').setup() -- New text operators
        -- Mini.Pairs: Autopairs for brackets, quotes, and custom patterns.
        require('mini.pairs').setup({
            -- Custom mappings to handle more advanced pairing logic.
            mappings = {
                -- 1. Space Pairing: Pressing space inside (), [], or {} 
                -- will automatically add a second space and keep the cursor in the middle.
                [' '] = { action = 'open', pair = '  ', neigh_pattern = '[%(%[{][%)%]}]' },

                -- 2. Percentage Pairing: Useful for Lua (%%) or LaTeX (%) environments.
                -- Only triggers when inside curly braces {}.
                ['%'] = { action = 'open', pair = '%%', neigh_pattern = '[{][}]' },

                -- 3. Angle Bracket Pairing: Smart handling for HTML tags or Generics.
                -- '<' will only pair to '<>' if it's placed inside curly braces {}.
                ['<'] = { action = 'open', pair = '<>', neigh_pattern = '[{][}]' },
                
                -- '>' will act as a close trigger for the above angle bracket pairing.
                ['>'] = { action = 'close', pair = '<>', neigh_pattern = '[{][}]' },
            },
        })
        require('mini.splitjoin').setup() -- Split/join arguments
        require('mini.surround').setup()  -- Manage surroundings (sa/sd/sr)

        -- Basic settings and sanity mappings
        require('mini.basics').setup({
            options = { basic = true, extra_ui = false, win_borders = 'default' },
            mappings = { basic = true, option_toggle_prefix = [[\]], windows = false, move_with_alt = false },
            autocommands = { basic = true, relnum_in_visual_mode = false },
        })

        require('mini.bracketed').setup() -- [ and ] navigation
        require('mini.bufremove').setup() -- Delete buffers safely
        require('mini.diff').setup()      -- Git sign indicators
        require('mini.extra').setup()     -- Misc extras
        -- Mini.Files: A buffer-based file explorer that allows file manipulation
        -- using standard text editing commands.
        require('mini.files').setup({
            -- Custom mappings for navigation and manipulation within the explorer.
            -- These use familiar 'h/j/k/l' movements for intuitive navigation.
            mappings = {
                close       = 'q',    -- Close the explorer
                go_in       = 'l',    -- Enter the directory or open the file under cursor
                go_in_plus  = '<CR>', -- Enter directory/open file and stay in explorer
                go_out      = 'h',    -- Go up one directory level
                go_out_plus = 'H',    -- Go up one level and stay in explorer
                reset       = '<BS>', -- Reset the view to the current working directory
                show_help   = 'g?',   -- Show available mappings
                synchronize = '=',    -- Apply file system changes (rename, delete, etc.)
                trim_left   = '<',    -- Hide columns to the left
                trim_right  = '>',    -- Hide columns to the right
            },
        })

        -- Custom mini.files mappings for vsplit and CWD
        vim.api.nvim_create_autocmd('User', {
            pattern = 'MiniFilesBufferCreate',
            callback = function(args)
                local buf_id = args.data.buf_id
                -- Open in vertical split with <C-v>
                vim.keymap.set('n', '<C-v>', function()
                    local fs_entry = require('mini.files').get_fs_entry()
                    require('mini.files').close()
                    vim.cmd('vsplit ' .. fs_entry.path)
                end, { buffer = buf_id, desc = 'Open in vsplit' })

                -- Set CWD to current directory in explorer with g.
                vim.keymap.set('n', 'g.', function()
                    local path = (require('mini.files').get_fs_entry() or {}).path
                    if path == nil then return end
                    local dir = vim.fs.dirname(path)
                    vim.fn.chdir(dir)
                    vim.notify("CWD set to: " .. dir)
                end, { buffer = buf_id, desc = 'Set CWD' })
            end,
        })
        require('mini.git').setup()       -- Git integration
        require('mini.jump').setup()      -- Single character jump

        -- Mini.Jump2d: Fast, EasyMotion-style movement across the screen.
        require('mini.jump2d').setup({
            mappings = {
                -- Remap from the default <CR> (Enter) to avoid breaking standard Enter behavior
                start_jumping = '<leader>j', 
            },
        })

        -- Mini.Map: A code minimap and scrollbar.
        -- We configure it to show Git changes, LSP diagnostics, and a scrollbar.
        local minimap = require('mini.map')
        minimap.setup({
            -- Integrations define what symbols are shown on the map
            integrations = {
                minimap.gen_integration.builtin_search(), -- Highlight search results
                minimap.gen_integration.diff(),          -- Highlight Git changes (requires mini.diff)
                minimap.gen_integration.diagnostic(),    -- Highlight LSP diagnostics
            },
            -- Symbols used for the map and scrollbar
            symbols = {
                encode = minimap.gen_encode_symbols.dot('4x2'), -- Use dots for a clean look
                scroll_line = '█', -- Solid block for the scrollbar
                scroll_view = '▒', -- Shaded block for the current view
            },
            -- Window configuration
            window = {
                focusable = false, -- Don't let cursor jump into the map
                side = 'right',    -- Show on the right side
                width = 20,        -- Set map width
            },
        })

        require('mini.misc').setup()      -- Misc utilities

        -- Smart Minimap: Auto-open for real files, but keep the dashboard clean.
        vim.api.nvim_create_autocmd('BufWinEnter', {
            callback = function()
                local ft = vim.bo.filetype
                -- If we're on the dashboard, ensure map is closed
                if ft == 'ministarter' then
                    pcall(require('mini.map').close)
                -- If it's a "real" file buffer, open the map
                elseif ft ~= '' and vim.bo.buftype == '' then
                    pcall(require('mini.map').open)
                end
            end,
        })
        
        -- Mini.Pick: A lightweight and extremely fast fuzzy picker.
        -- This replaces Telescope for all search and navigation tasks.
        local minipick = require('mini.pick')
        minipick.setup({
            -- Use the mini icon provider we configured earlier
            use_icons = true,
            -- Window configuration
            window = {
                config = { border = 'double' },
            },
        })
        
        require('mini.snippets').setup()  -- Code snippets
        require('mini.visits').setup()    -- Track frequent files
        -- Dashboard (mini.starter): A highly customized, tabbed-box dashboard.
        -- Why: We leverage starter.setup() and content_hooks to create a complex, 
        -- professional TUI layout that native dashboard plugins can't easily replicate.
        local starter = require('mini.starter')
        local version = 'NEOVIM ' .. vim.version().major .. '.' .. vim.version().minor .. '.' .. vim.version().patch
        local user = os.getenv('USER') or os.getenv('LOGNAME') or 'user'
        local welcome = '  Welcome to ' .. version .. ', ' .. user

        local function get_last_update_text()
            local last_update = 0
            local f = io.open(state_path, "r")
            if f then
                last_update = tonumber(f:read("*all")) or 0
                f:close()
            end
            if last_update == 0 then return " (Never)" end
            local diff = os.time() - last_update
            if diff < 60 then return " (Just now)" end
            if diff < 3600 then return string.format(" (%d mins ago)", math.floor(diff / 60)) end
            if diff < 86400 then return string.format(" (%d hrs ago)", math.floor(diff / 3600)) end
            return string.format(" (%d days ago)", math.floor(diff / 86400))
        end

        starter.setup({
            evaluate_single = true,
            items = {
                function()
                    local items = starter.sections.recent_files(9, false)()
                    for _, item in ipairs(items) do
                        item.section = 'Recent files:'
                        -- Extract path from 'filename (path)' format
                        local path = item.name:match("%((.*)%)")
                        if path then
                            item.name = vim.fn.fnamemodify(path, ":~:.")
                        end
                    end
                    return items
                end,
                { name = 'Edit new buffer', action = 'enew', section = 'Actions:' },
                { name = 'Update Plugins' .. get_last_update_text(), action = 'PackUpdate', section = 'Actions:' },
                { name = 'Update Treesitter', action = 'PackTSUpdate', section = 'Actions:' },
                { name = 'Quit Neovim', action = 'qall', section = 'Actions:' },
            },
            header = table.concat({
                '│ ╲ ││',
                '││╲╲││' .. welcome,
                '││ ╲ │',
            }, '\n'),
            footer = '',
            content_hooks = {
                -- Insert a blank line before 'Quit Neovim'
                function(content)
                    for i, line in ipairs(content) do
                        for _, unit in ipairs(line) do
                            if unit.string == 'Quit Neovim' then
                                table.insert(content, i, { { string = '', type = 'empty' } })
                                return content
                            end
                        end
                    end
                    return content
                end,
                starter.gen_hook.indexing('all', { 'Actions:' }),
                -- Apply consistent highlighting and format triggers as 'index - '
                function(content)
                    local coords = starter.content_coords(content, 'item')

                    for i = #coords, 1, -1 do
                        local c = coords[i]
                        local line = content[c.line]
                        local unit = line[c.unit]
                        local item = unit.item
                        local index_str, rest

                        if item.section == 'Actions:' then
                            local shortcut = '?'
                            if item.name:match('^Edit new buffer') then shortcut = 'e'
                            elseif item.name:match('^Update Plugins') then shortcut = 'p'
                            elseif item.name:match('^Update Treesitter') then shortcut = 't'
                            elseif item.name:match('^Quit Neovim') then shortcut = 'q'
                            end
                            index_str = shortcut:upper() .. ' - '
                            rest = item.name
                        else
                            local index, filename = unit.string:match("^(%d+)%. (.*)$")
                            if index then
                                index_str = string.format("%d - ", tonumber(index))
                                rest = filename
                            end
                        end

                        if index_str then
                            -- Keep as a single unit to ensure the entire line is treated as one 'item'.
                            -- This ensures the blue selection bar (MiniStarterCurrent) covers the whole text.
                            unit.string = index_str .. rest
                        end
                    end
                    return content
                end,
                -- Draw boxes around sections
                function(content)
                    local get_line_width = function(line)
                        local w = 0
                        for _, u in ipairs(line) do w = w + vim.fn.strdisplaywidth(u.string) end
                        return w
                    end
                    
                    -- First pass: find global max width and group lines into sections
                    local max_w_all = 0
                    local sections = {}
                    local i = 1
                    while i <= #content do
                        local line = content[i]
                        local section_name = nil
                        for _, u in ipairs(line) do
                            if u.type == 'section' then section_name = u.string break end
                        end
                        
                        if section_name then
                            local sec = { name = section_name, lines = { line } }
                            i = i + 1
                            while i <= #content do
                                local next_line = content[i]
                                local next_has_section = false
                                for _, u in ipairs(next_line) do
                                    if u.type == 'section' then next_has_section = true break end
                                end
                                if next_has_section or (#next_line == 0 and i < #content) then break end
                                table.insert(sec.lines, next_line)
                                i = i + 1
                            end
                            for _, l in ipairs(sec.lines) do max_w_all = math.max(max_w_all, get_line_width(l)) end
                            table.insert(sections, sec)
                        else
                            table.insert(sections, line)
                            i = i + 1
                        end
                    end

                    -- Second pass: render with uniform box widths
                    local res = {}
                    local border_hl = 'MiniStarterItemBullet'
                    for _, entry in ipairs(sections) do
                        if entry.name then
                            local sec_name = entry.name
                            local sec_lines = entry.lines
                            local header_w = vim.fn.strdisplaywidth(sec_name)
                            
                            -- Ensure the item box is at least as wide as the header tab
                            local box_content_w = math.max(max_w_all, header_w - 1)
                            -- Total width of the item box (including │ and internal padding)
                            local total_w = box_content_w + 4

                            -- 1. Top of the tab
                            table.insert(res, { { string = '┌' .. string.rep('─', header_w) .. '┐', type = 'empty', hl = border_hl } })
                            
                            -- 2. Header line with junction to the main box
                            local junction_dashes = total_w - (header_w + 2) - 1
                            table.insert(res, { 
                                { string = '│' .. sec_name .. '└' .. string.rep('─', math.max(0, junction_dashes)) .. '┐', type = 'empty', hl = border_hl } 
                            })

                            -- 3. Spacer line inside the box
                            table.insert(res, {
                                { string = '│ ' .. string.rep(' ', box_content_w) .. ' │', type = 'empty', hl = border_hl }
                            })

                            -- 4. Render the items
                            for j = 2, #sec_lines do
                                local l = sec_lines[j]
                                local w = get_line_width(l)
                                local padding = string.rep(' ', box_content_w - w)
                                local new_l = { { string = '│ ', type = 'empty', hl = border_hl } }
                                vim.list_extend(new_l, l)
                                table.insert(new_l, { string = padding .. ' │', type = 'empty', hl = border_hl })
                                table.insert(res, new_l)
                            end

                            -- 5. Bottom of the box
                            table.insert(res, { { string = '└' .. string.rep('─', total_w - 2) .. '┘', type = 'empty', hl = border_hl } })
                        else
                            table.insert(res, entry)
                        end
                    end
                    return res
                end,
                starter.gen_hook.padding(3, 2),
                starter.gen_hook.aligning('center', 'center'),
            },
        })

        -- Startup Screen Highlights: Match Meowsoot palette
        vim.api.nvim_set_hl(0, 'MiniStarterHeader', { fg = c.blue }) -- Blue header
        vim.api.nvim_set_hl(0, 'MiniStarterItemIndex', { fg = c.peach }) -- Peach index
        vim.api.nvim_set_hl(0, 'MiniStarterItemBullet', { fg = c.blue }) -- Blue bullet
        -- Full line highlight on selection
        vim.api.nvim_set_hl(0, 'MiniStarterCurrent', { bg = c.blue, fg = c.bg, bold = true })

        -- Enable cursorline and custom trigger highlights in starter buffer
        vim.api.nvim_create_autocmd('FileType', {
            group = vim.api.nvim_create_augroup('StarterCursorLine', { clear = true }),
            pattern = 'starter',
            callback = function()
                vim.wo.cursorline = true
                vim.wo.winhighlight = 'CursorLine:MiniStarterCurrent'
                -- Manually highlight the trigger (number or letter) as orange
                vim.fn.matchadd('MiniStarterItemIndex', '[0-9A-Z] - ')
            end,
        })

        -- Robustly hide statusline on dashboard using mini.starter's native event
        vim.api.nvim_create_autocmd('User', {
            group = vim.api.nvim_create_augroup('StarterStatusline', { clear = true }),
            pattern = 'MiniStarterOpened',
            callback = function()
                local old_laststatus = vim.o.laststatus
                vim.o.laststatus = 0
                -- Restore when leaving the starter buffer
                vim.api.nvim_create_autocmd('BufLeave', {
                    buffer = 0,
                    once = true,
                    callback = function()
                        vim.o.laststatus = old_laststatus
                    end,
                })
            end,
        })

        require('mini.animate').setup()   -- UI animations
        require('mini.cursorword').setup()-- Highlight current word
        
        -- Mini.Icons: Provide high-quality UI icons.
        -- We also "mock" nvim-web-devicons here so that other plugins 
        -- (like Telescope) can use mini.icons seamlessly without needing
        -- the old nvim-web-devicons plugin installed.
        local mini_icons = require('mini.icons')
        mini_icons.setup()
        mini_icons.mock_nvim_web_devicons()
        mini_icons.tweak_lsp_kind()
        
        require('mini.indentscope').setup()-- Indent guides
        require('mini.notify').setup()    -- Notification system
        vim.notify = require('mini.notify').make_notify() -- Route notifications to floating window
        
        require('mini.statusline').setup()-- Bottom status line
        -- Statusline Tweaks:
        -- We give the entire statusline a subtle background so it looks like a "bar".
        -- The mode indicators use colored text on this dark background for a clean, modern look.
        local status_bg = c.bg_1
        vim.api.nvim_set_hl(0, 'StatusLine', { fg = c.fg, bg = status_bg })
        vim.api.nvim_set_hl(0, 'StatusLineNC', { fg = c.fg_faint, bg = status_bg })
        
        vim.api.nvim_set_hl(0, 'MiniStatuslineModeNormal',  { fg = c.green, bg = status_bg, bold = true })
        vim.api.nvim_set_hl(0, 'MiniStatuslineModeInsert',  { fg = c.blue, bg = status_bg, bold = true })
        vim.api.nvim_set_hl(0, 'MiniStatuslineModeVisual',  { fg = c.magenta, bg = status_bg, bold = true })
        vim.api.nvim_set_hl(0, 'MiniStatuslineModeReplace', { fg = c.red, bg = status_bg, bold = true })
        vim.api.nvim_set_hl(0, 'MiniStatuslineModeCommand', { fg = c.red, bg = status_bg, bold = true })
        
        vim.api.nvim_set_hl(0, 'MiniStatuslineDevinfo', { fg = c.fg_mute, bg = status_bg })
        vim.api.nvim_set_hl(0, 'MiniStatuslineFilename', { fg = c.fg, bg = status_bg, bold = true })
        vim.api.nvim_set_hl(0, 'MiniStatuslineFileinfo', { fg = c.fg_mute, bg = status_bg })

        -- GUI-Style Tabline: A custom tabline that looks like physical tabs.
        -- Why: We use a from-scratch function rather than mini.tabline because
        -- this is the only way to independently color the vertical separators (│) 
        -- without them inheriting the active tab's background color. This gives us
        -- the precise, high-fidelity Glowbeam aesthetic we want.
        function _G.MyTabLine()
            local s = ""
            local c = M.colors
            -- Active tab: Uses the main background, blue text, and a blue underline
            vim.api.nvim_set_hl(0, "TabLineSel", { fg = c.blue, bg = c.bg, bold = true, underline = true, sp = c.blue })
            -- Inactive tab: Uses a darker background
            vim.api.nvim_set_hl(0, "TabLine", { fg = c.fg_mute, bg = c.bg_2 })
            -- Fill space and separators: Darker background, subdued text color
            vim.api.nvim_set_hl(0, "TabLineFill", { bg = c.bg_2 })
            vim.api.nvim_set_hl(0, "TabSeparator", { fg = c.bg_4, bg = c.bg_2 })
            vim.api.nvim_set_hl(0, "TabLineHiddenMod", { fg = c.yellow, bg = c.bg_2 })

            local active_buf = vim.api.nvim_get_current_buf()
            local n_listed_bufs = 0
            
            for _, buf_id in ipairs(vim.api.nvim_list_bufs()) do
                if vim.fn.buflisted(buf_id) == 1 then
                    n_listed_bufs = n_listed_bufs + 1
                    local is_active = (buf_id == active_buf)
                    local name = vim.fn.bufname(buf_id)
                    name = name ~= "" and vim.fn.fnamemodify(name, ":t") or "[No Name]"

                    -- Check if modified
                    if vim.bo[buf_id].modified then
                        name = name .. " ●"
                    end

                    -- Every tab draws a single separator on its left side
                    s = s .. "%#TabSeparator#│"

                    -- Draw the actual tab content
                    if is_active then
                        s = s .. "%#TabLineSel#  " .. name .. "  "
                    elseif vim.bo[buf_id].modified then
                        s = s .. "%#TabLineHiddenMod#  " .. name .. "  "
                    else
                        s = s .. "%#TabLine#  " .. name .. "  "
                    end
                end
            end

            -- Cap the entire list of tabs with one final right separator
            if n_listed_bufs > 0 then
                s = s .. "%#TabSeparator#│"
            end

            -- Fill the rest of the line
            s = s .. "%#TabLineFill#%T"
            return s
        end

        vim.o.tabline = "%!v:lua.MyTabLine()"
        
        -- Auto-hide tabline if only 1 buffer is open
        vim.api.nvim_create_autocmd({'BufEnter', 'BufAdd', 'BufDelete'}, {
            callback = vim.schedule_wrap(function()
                local n_listed_bufs = 0
                for _, buf_id in ipairs(vim.api.nvim_list_bufs()) do
                    if vim.fn.buflisted(buf_id) == 1 then
                        n_listed_bufs = n_listed_bufs + 1
                    end
                end
                -- 2 = always show, 0 = never show
                vim.o.showtabline = n_listed_bufs > 1 and 2 or 0
            end),
        })

        require('mini.trailspace').setup()-- Clear trailing whitespace

        -- Render-Markdown: Make Markdown files look beautiful directly in the buffer.
        -- It uses Tree-sitter to render headings, tables, and code blocks.
        local status_markdown, render_markdown = pcall(require, 'render-markdown')
        if status_markdown then
            render_markdown.setup({
                -- Use your existing mini.icons provider for filetype icons
                preset = 'mini',
                
                -- Enable completions for tasks, callouts, etc.
                completions = { lsp = { enabled = true } },

                -- Better table rendering
                pipe_table = { preset = 'round' },

                -- Display icons for headings, tasks, etc.
                enabled = true,
                
                -- What to render
                heading = {
                    enabled = true,
                    sign = true,      -- Show icons in the sign column
                    position = 'overlay', -- Render over the '#' characters
                    icons = { '󰲡 ', '󰲣 ', '󰲥 ', '󰲧 ', '󰲩 ', '󰲫 ' },
                },
                
                code = {
                    enabled = true,
                    style = 'normal', -- Use backgrounds for code blocks
                    width = 'full',   -- Background spans the full window width
                    left_pad = 2,
                    right_pad = 2,
                },

                -- Reveal the raw markdown syntax on the current line while editing
                anti_conceal = {
                    enabled = true,
                },
            })
        end

        -- Ansible Tools: Enhancements for automation development.
        -- We resolve a naming conflict between 'ansible-vim' and 'nvim-ansible'
        -- by calling setup() for Tree-sitter and using 'ansible_runner' for execution.
        local status_ansible_vim, ansible_vim = pcall(require, 'ansible')
        if status_ansible_vim and ansible_vim.setup then
            ansible_vim.setup() -- Enable Tree-sitter highlighting for Ansible
        end

        local status_ansible_runner, ansible_runner = pcall(require, 'ansible_runner')
        if status_ansible_runner then
            -- Run the current playbook using leader+a+r
            vim.keymap.set('n', '<leader>ar', function() ansible_runner.run() end, { desc = 'Ansible: Run Playbook' })
        end

        -- YAML Revealer: Show current YAML path and enable path-based search.
        -- We configure it to show the path as virtual text at the end of the line.
        vim.g.yaml_revealer_display_mode = 'virtual' -- Show path as virtual text
        vim.g.yaml_revealer_max_width = 80           -- Prevent "Press ENTER" prompts
        -- Keymap to search for a specific YAML key by path
        vim.keymap.set('n', '<leader>ay', ':SearchYamlKey ', { desc = 'Ansible: Search YAML Path' })

        -- YankBank: A clipboard manager with persistent history.
        -- We enable SQLite persistence so your yank history survives restarts.
        local status_yb, yankbank = pcall(require, 'yankbank')
        if status_yb then
            yankbank.setup({
                persist_type = 'sqlite', -- Use sqlite.lua for persistent storage
            })
            vim.keymap.set('n', '<leader>yb', '<cmd>YankBank<CR>', { desc = 'YankBank: Open History' })
        end

        -- Tiny-cmdline: Centers the native UI2 command line.
        -- This gives a modern floating command palette without the bloat of Noice.nvim.
        local status_cmdline, cmdline = pcall(require, 'tiny-cmdline')
        if status_cmdline then
            cmdline.setup({
                title = {
                    enabled = true, -- Show current mode (:, /, ?) in the border
                    pos = "center",
                },
            })
        end

        -- Native Diagnostics: Configure how Neovim displays errors and warnings.
        -- We define signs explicitly so they show up in the gutter.
        -- local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
        -- for type, icon in pairs(signs) do
        --     local hl = "DiagnosticSign" .. type
        --     vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
        -- end

        vim.diagnostic.config({
            virtual_text = {
                prefix = '●', -- Use a clean dot instead of standard text
                source = "if_many", -- Show source (e.g., 'spell') if there are multiple
                current_line = true, -- Only show virtual text for the active line
            },
            signs = true,
            underline = true,
            update_in_insert = false,
        })

        -- Minuet-AI: Gemini-powered AI completions integrated with mini.completion.
        -- It acts as an in-process LSP server to provide high-quality suggestions.
        local status_minuet, minuet = pcall(require, 'minuet')
        if status_minuet then
            minuet.setup({
                provider = 'gemini',
                provider_options = {
                    gemini = {
                        model = 'gemini-2.0-flash', -- Faster 2.0 Flash model
                        system = "You are a senior software engineer. Provide only code snippets without explanation.",
                    },
                },
                -- Virtual text (Ghost text) configuration
                virtualtext = {
                    enabled = true,
                    keymap = {
                        accept = '<S-Tab>',    -- Shift-Tab to accept full suggestion
                        accept_line = '<A-l>', -- Alt-l to accept next line (keeping as fallback)
                        accept_word = '<Tab>',  -- Tab to accept next word
                        prev = '<A-q>',        -- Alt-q for previous suggestion
                        next = '<A-e>',        -- Alt-e for next suggestion
                        dismiss = '<A-c>',     -- Alt-c to clear suggestion (Esc breaks Insert mode)
                    },
                },
                throttle = 2000, -- Wait 2s between requests to save quota
                debounce = 400,  -- Wait 400ms after typing stops before requesting
            })
            
            -- Enable Minuet's LSP-based completion
            -- mini.completion will automatically pick up suggestions from this internal client.
            vim.api.nvim_create_autocmd('LspAttach', {
                callback = function(args)
                    vim.lsp.completion.enable(true, args.data.client_id)
                end,
            })

            -- Global toggle for AI suggestions
            vim.keymap.set('n', '<leader>at', function() 
                local current = require('minuet.config').options.virtualtext.enabled
                require('minuet').setup({ virtualtext = { enabled = not current } })
                vim.notify("AI Ghost Text: " .. (not current and "Enabled" or "Disabled"))
            end, { desc = 'AI: Toggle Suggestions' })
        end

        -- 1. SHIMS & COMPATIBILITY
        -- vim-dirtytalk depends on spellfile#WritableSpellDir, which is missing 
        -- in some environments. We provide a custom global update function to fix this.
        vim.api.nvim_create_user_command("DirtytalkUpdate", function() M.dirtytalk_update_fix() end, {})

        -- 2. MINI MODULES (Standard)
        local keymap = vim.keymap
        keymap.set('n', '<leader>e', function() require('mini.files').open() end, { desc = 'Open Mini.Files' })
        keymap.set('n', '<leader>bd', function() require('mini.bufremove').delete(0, false) end, { desc = 'Delete Buffer' })

        -- Mini.Pick & Mini.Extra: Fuzzy finding replacements for Telescope.
        -- These provide a unified and fast interface for all search tasks.
        keymap.set('n', '<leader>ff', function() require('mini.pick').builtin.files() end, { desc = 'Find Files' })
        keymap.set('n', '<leader>fg', function() require('mini.pick').builtin.grep_live() end, { desc = 'Live Grep' })
        keymap.set('n', '<leader>fb', function() require('mini.pick').builtin.buffers() end, { desc = 'Find Buffers' })
        keymap.set('n', '<leader>fh', function() require('mini.extra').pickers.help() end, { desc = 'Help Tags' })
        keymap.set('n', '<leader>fd', function() require('mini.extra').pickers.diagnostic() end, { desc = 'Diagnostics' })
        keymap.set('n', '<leader>fr', function() require('mini.extra').pickers.oldfiles() end, { desc = 'Recent Files' })
        keymap.set('n', '<leader>fv', function() require('mini.extra').pickers.visit_paths() end, { desc = 'Visit Paths' })
        keymap.set('n', '<leader>f/', function() require('mini.pick').builtin.grep({ pattern = vim.fn.expand('<cword>') }) end, { desc = 'Grep Cword' })

        -- Mini.Map Keymaps: Toggle the minimap
        keymap.set('n', '<leader>mc', function() require('mini.map').toggle() end, { desc = 'Map: Toggle Minimap' })
        keymap.set('n', '<leader>mf', function() require('mini.map').toggle_focus() end, { desc = 'Map: Toggle Focus' })
        
        -- Mini.Clue: Configure the 'mini.clue' module to show available keybindings in a popup.
        -- This provides a "Which-Key" like experience for Neovim.
        local miniclue = require('mini.clue')
        miniclue.setup({
            -- Triggers define which keys will activate the clue window.
            triggers = {
                -- Leader key triggers for Normal and Visual modes
                { mode = 'n', keys = '<leader>' },
                { mode = 'x', keys = '<leader>' },

                -- Built-in completion triggers in Insert mode
                { mode = 'i', keys = '<C-x>' },

                -- 'g' key triggers (e.g., 'gd' for definition, 'gg' for top of file)
                { mode = 'n', keys = 'g' },
                { mode = 'x', keys = 'g' },

                -- Mark triggers for jumping to marks
                { mode = 'n', keys = "'" },
                { mode = 'n', keys = '`' },
                { mode = 'x', keys = "'" },
                { mode = 'x', keys = '`' },

                -- Register triggers for pasting/deleting into specific registers
                { mode = 'n', keys = '"' },
                { mode = 'x', keys = '"' },
                { mode = 'i', keys = '<C-r>' },
                { mode = 'c', keys = '<C-r>' },

                -- Window command triggers (Ctrl-W prefix)
                { mode = 'n', keys = '<C-w>' },

                -- 'z' key triggers (e.g., 'zz' to center screen, 'za' to toggle fold)
                { mode = 'n', keys = 'z' },
                { mode = 'x', keys = 'z' },
            },

            -- Clues define the descriptions shown in the popup window.
            clues = {
                -- Use built-in clue generators for standard Neovim features
                miniclue.gen_clues.builtin_completion(), -- Describe Insert mode completion keys
                miniclue.gen_clues.g(),                  -- Describe 'g' prefix commands
                miniclue.gen_clues.marks(),              -- Describe mark-related keys
                miniclue.gen_clues.registers(),          -- Describe register-related keys
                miniclue.gen_clues.windows(),            -- Describe window management keys
                miniclue.gen_clues.z(),                  -- Describe 'z' prefix commands

                -- Custom descriptions for <Leader> mapping groups.
                -- These help categorize your own custom keybindings.
                { mode = 'n', keys = '<leader>b', desc = '+Buffers' },       -- Buffer management
                { mode = 'n', keys = '<leader>f', desc = '+Find/Format' },   -- Fuzzy finding and formatting
                { mode = 'n', keys = '<leader>p', desc = '+Project' },       -- Project-level actions
                { mode = 'n', keys = '<leader>y', desc = '+Yank (System)' }, -- System clipboard yanking
                { mode = 'n', keys = '<leader>yb', desc = 'YankBank History' }, -- Open clipboard history
                { mode = 'n', keys = '<leader>d', desc = '+Delete (Void)' }, -- Deleting without yanking
                { mode = 'n', keys = '<leader>r', desc = '+Rename' },        -- LSP Rename
                { mode = 'n', keys = '<leader>c', desc = '+Code Action' },   -- LSP Code Action
                { mode = 'n', keys = '<leader>a', desc = '+Ansible/AI' },    -- Ansible & AI tools
                { mode = 'n', keys = '<leader>at', desc = 'Toggle Gemini' }, -- Toggle Minuet-AI
                { mode = 'n', keys = '<leader>j', desc = 'Jump (2D)' },      -- Trigger mini.jump2d
                { mode = 'n', keys = '<leader>m', desc = '+Map' },           -- Minimap tools
            },
        })

        -- Advanced Hipatterns: Vibrant comment tags and hex colors
        local hipatterns = require('mini.hipatterns')
        hipatterns.setup({
            highlighters = {
                fixme       = { pattern = "()FIXME():",   group = "MiniHipatternsFixme" },
                hack        = { pattern = "()HACK():",    group = "MiniHipatternsHack" },
                todo        = { pattern = "()TODO():",    group = "MiniHipatternsTodo" },
                note        = { pattern = "()NOTE():",    group = "MiniHipatternsNote" },
                fixme_colon = { pattern = "FIXME():()",   group = "MiniHipatternsFixmeColon" },
                hack_colon  = { pattern = "HACK():()",    group = "MiniHipatternsHackColon" },
                todo_colon  = { pattern = "TODO():()",    group = "MiniHipatternsTodoColon" },
                note_colon  = { pattern = "NOTE():()",    group = "MiniHipatternsNoteColon" },
                fixme_body  = { pattern = "FIXME:().*()", group = "MiniHipatternsFixmeBody" },
                hack_body   = { pattern = "HACK:().*()",  group = "MiniHipatternsHackBody" },
                todo_body   = { pattern = "TODO:().*()",  group = "MiniHipatternsTodoBody" },
                note_body   = { pattern = "NOTE:().*()",  group = "MiniHipatternsNoteBody" },
                hex_color = hipatterns.gen_highlighter.hex_color(),
            },
        })
    end

    -- Hardtime (Strict Mode): Break bad habit of spamming keys
    local status_hardtime, hardtime = pcall(require, 'hardtime')
    if status_hardtime then
        hardtime.setup({
            force_exit_insert_mode = true, -- Exit Insert mode if inactive for 10s
        })
    end

    -- Demicolon: Make ; and , repeat ANY jump (diagnostic, git hunk, etc.)
    local status_demicolon, demicolon = pcall(require, 'demicolon')
    if status_demicolon then
        demicolon.setup({ 
            keymaps = { 
                horizontal_motions = true,
                repeat_motions = 'stateless',
            } 
        })
    end

    -- Various Textobjs: Precision editing targets (subword, indentation, etc.)
    local status_various, various = pcall(require, 'various-textobjs')
    if status_various then
        various.setup({ useDefaultKeymaps = false })
        local keymap = vim.keymap
        keymap.set({ "o", "x" }, "iS", function() various.subword("inner") end)
        keymap.set({ "o", "x" }, "aS", function() various.subword("outer") end)
        keymap.set({ "o", "x" }, "ii", function() various.indentation("inner", "inner") end)
        keymap.set({ "o", "x" }, "ai", function() various.indentation("outer", "inner") end)
        keymap.set({ "o", "x" }, "iv", function() various.value("inner") end)
        keymap.set({ "o", "x" }, "av", function() various.value("outer") end)
        keymap.set({ "o", "x" }, "ig", function() various.entireBuffer() end)
        keymap.set({ "o", "x" }, "R",  function() various.restOfParagraph() end)
        keymap.set({ "o", "x" }, "i_", function() various.subword("inner") end) -- Another way for subword
        keymap.set({ "o", "x" }, "a_", function() various.subword("outer") end)
        keymap.set({ "o", "x" }, "in", function() various.number("inner") end)
        keymap.set({ "o", "x" }, "an", function() various.number("outer") end)
        keymap.set({ "o", "x" }, "id", function() various.diagnostic() end)
        keymap.set({ "o", "x" }, "iu", function() various.url() end)
    end

    -- Status Column: Modern gutter with side-by-side icons
    local status_col, statuscol = pcall(require, 'statuscol')
    if status_col then
        local builtin = require("statuscol.builtin")
        statuscol.setup({
            relculright = true,
            segments = {
                { text = { builtin.foldfunc }, click = "v:lua.ScFa" },
                { text = { "%s" }, click = "v:lua.ScSa" },
                { text = { builtin.lnumfunc, " " }, click = "v:lua.ScLa" },
            },
        })
    end

    -- 5. MASON & LSP (Neovim 0.12 Native Style)
    local mason_path = vim.fn.stdpath("data") .. "/mason/bin"
    vim.env.PATH = mason_path .. ":" .. vim.env.PATH
    
    local status_mason, mason = pcall(require, 'mason')
    local status_mason_lsp, mason_lsp = pcall(require, 'mason-lspconfig')

    if status_mason and status_mason_lsp then
        -- Native LSP configuration: merges with nvim-lspconfig defaults
        vim.lsp.config('lua_ls', { 
            root_markers = { '.luarc.json', '.git' },
            root_dir = vim.loop.cwd()
        })
        
        -- Safe blocks for common servers to prevent crashes (explicit settings object required)
        vim.lsp.config('harper_ls', { settings = {} })
        vim.lsp.config('pyright', { settings = {} })
        vim.lsp.config('ts_ls', { settings = {} })
        vim.lsp.config('yamlls', { settings = {} })
        vim.lsp.config('bashls', { settings = {} })

        mason.setup()
        mason_lsp.setup({
            ensure_installed = { "lua_ls", "pyright", "ts_ls", "yamlls", "bashls", "harper_ls" },
            automatic_enable = false, -- Enable manually to ensure our configs are applied
        })

        -- Default LSP keymaps using the native LspAttach event
        vim.api.nvim_create_autocmd('LspAttach', {
            callback = function(event)
                local opts = { buffer = event.buf }
                vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
                vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
                vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
                vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
                vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
            end,
        })

        -- LSP Configuration: Use FileType autocommands to automatically
        -- enable LSP servers for relevant filetypes.
        vim.api.nvim_create_autocmd('FileType', {
            pattern = 'lua',
            callback = function() vim.lsp.enable('lua_ls') end,
        })
        vim.api.nvim_create_autocmd('FileType', {
            pattern = {'sh', 'bash', 'zsh'},
            callback = function() vim.lsp.enable('bashls') end,
        })
        vim.api.nvim_create_autocmd('FileType', {
            pattern = 'python',
            callback = function() vim.lsp.enable('pyright') end,
        })
        vim.api.nvim_create_autocmd('FileType', {
            pattern = 'yaml',
            callback = function() vim.lsp.enable('yamlls') end,
        })
        vim.api.nvim_create_autocmd('FileType', {
            pattern = {'typescript', 'javascript', 'typescriptreact'},
            callback = function() vim.lsp.enable('ts_ls') end,
        })
        -- Harper-ls is a general-purpose linting tool, attach to all text-based files
        vim.api.nvim_create_autocmd('FileType', {
            pattern = {'lua', 'python', 'sh', 'bash', 'zsh', 'yaml', 'typescript', 'javascript', 'markdown', 'gitcommit'},
            callback = function() vim.lsp.enable('harper_ls') end,
        })
    end
end

return M
