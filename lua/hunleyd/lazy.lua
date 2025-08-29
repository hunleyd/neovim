local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- lazy needs leader set before loading plugins
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

return require('lazy').setup({
    -- auto-star whatever plugins we use
    { 'jsongerber/thanks.nvim',
        config = function()
            require('thanks').setup({
                star_on_install = true,
                star_on_startup = true,
                ignore_repos = {},
                ignore_authors = {},
                unstar_on_uninstall = false,
                ask_before_unstarring = false,
            })
        end },

    -- undotree
    { 'mbbill/undotree' },

    -- theme
    { 'cooperuser/glowbeam.nvim' },

    -- make Jim better at vi
    { 'm4xshen/hardtime.nvim',
        opts = {},
        event = 'BufEnter',
        config = function()
            require('hardtime').setup()
	end,
    },

    -- make t/T/f/F repeatable with ; and '
    { 'mawkler/demicolon.nvim',
        keys = { ';', ',', 't', 'f', 'T', 'F', ']', '[', ']d', '[d' },
        dependencies = {
            'nvim-treesitter/nvim-treesitter',
            'nvim-treesitter/nvim-treesitter-textobjects',
        },
        opts = {
            integrations = {
                gitsigns = {
                    enabled = false,
                },
            },
        },
    },

    -- additional text objects
    { 'chrisgrieser/nvim-various-textobjs',
        event = 'UIEnter',
        opts = {
            keymaps = {
                useDefaults = true
            }
        },
    },

    -- statuscol
    { 'luukvbaal/statuscol.nvim', config = function()
      require('statuscol').setup({
      })
      end,
    },

    -- noice for msgs/cmdline/popup menu dressing
    { 'folke/noice.nvim',
        event = 'VeryLazy',
        opts = {},
        dependencies = {
            'MunifTanjim/nui.nvim',
            'rcarriga/nvim-notify',
        },
        config = function()
        require('noice').setup({
                lsp = {
                    override = {
                        ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
                        ['vim.lsp.util.stylize_markdown'] = true,
--                        ['cmp.entry.get_documentation'] = true,
                    },
                },
                presets = {
                    bottom_search = true,
                    command_palette = true,
                    long_message_to_split = true,
                    inc_rename = false,
                    lsp_doc_border = false,
                },
        })
        end,
    },

    -- use color for the different modes
    { 'mvllow/modes.nvim',
        tag = 'v0.2.0',
        config = function()
            require('modes').setup()
        end
    },

    -- load mini plugin collection
    { 'nvim-mini/mini.nvim',
        version = false,
        config = function()
            require('mini.basics').setup({
                -- Options. Set to `false` to disable.
                options = {
                    -- Basic options ('termguicolors', 'number', 'ignorecase', and many more)
                    basic = true,
                    -- Extra UI features ('winblend', 'cmdheight=0', ...)
                    extra_ui = true,
                    -- Presets for window borders ('single', 'double', ...)
                    win_borders = 'default',
                },
                -- Mappings. Set to `false` to disable.
                mappings = {
                    -- Basic mappings (better 'jk', save with Ctrl+S, ...)
                    basic = true,
                    -- Prefix for mappings that toggle common options ('wrap', 'spell', ...)
                    -- Supply empty string to not create these mappings
                    option_toggle_prefix = [[\]],
                    -- Window navigation with <C-hjkl>, resize with <C-arrow>
                    windows = false,
                    -- Move cursor in Insert, Command, and Terminal mode with <M-hjkl>
                    move_with_alt = false,
                },
                -- Autocommands. Set to `false` to disable
                autocommands = {
                    -- Basic autocommands (highlight on yank, start Insert in terminal, ...)
                    basic = true,
                    -- Set 'relativenumber' only in linewise and blockwise Visual mode
                    relnum_in_visual_mode = false,
                },
            })
            require('mini.bracketed').setup()
            local miniclue = require('mini.clue')
            miniclue.setup({
                triggers = {
                    -- Leader triggers
                    { mode = 'n', keys = '<Leader>' },
                    { mode = 'x', keys = '<Leader>' },
                    -- Built-in completion
                    { mode = 'i', keys = '<C-x>' },
                    -- `g` key
                    { mode = 'n', keys = 'g' },
                    { mode = 'x', keys = 'g' },
                    -- Marks
                    { mode = 'n', keys = "'" },
                    { mode = 'n', keys = '`' },
                    { mode = 'x', keys = "'" },
                    { mode = 'x', keys = '`' },
                    -- Registers
                    { mode = 'n', keys = '"' },
                    { mode = 'x', keys = '"' },
                    { mode = 'i', keys = '<C-r>' },
                    { mode = 'c', keys = '<C-r>' },
                    -- Window commands
                    { mode = 'n', keys = '<C-w>' },
                    -- `z` key
                    { mode = 'n', keys = 'z' },
                    { mode = 'x', keys = 'z' },
                },
                clues = {
                    -- Enhance this by adding descriptions for <Leader> mapping groups
                    miniclue.gen_clues.builtin_completion(),
                    miniclue.gen_clues.g(),
                    miniclue.gen_clues.marks(),
                    miniclue.gen_clues.registers(),
                    miniclue.gen_clues.windows(),
                    miniclue.gen_clues.z(),
                },
            })
            require('mini.comment').setup()
            require('mini.diff').setup({})
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
                }
            })
            local hipatterns = require('mini.hipatterns')
            hipatterns.setup({
                highlighters = {
                    -- Highlight standalone 'FIXME', 'HACK', 'TODO', 'NOTE'
                    fixme = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'MiniHipatternsFixme' },
                    hack  = { pattern = '%f[%w]()HACK()%f[%W]',  group = 'MiniHipatternsHack'  },
                    todo  = { pattern = '%f[%w]()TODO()%f[%W]',  group = 'MiniHipatternsTodo'  },
                    note  = { pattern = '%f[%w]()NOTE()%f[%W]',  group = 'MiniHipatternsNote'  },
                    -- Highlight hex color strings (`#rrggbb`) using that color
                    hex_color = hipatterns.gen_highlighter.hex_color(),
                },
            })
            require('mini.git').setup({})
            require('mini.indentscope').setup({})
            require('mini.jump').setup({})
            require('mini.pairs').setup({
                mappings = {
                    [' '] = { action = 'open', pair = '  ', neigh_pattern = '[%(%[{][%)%]}]' },
                    ['%'] = { action = 'open', pair = '%%', neigh_pattern = '[{][}]' },
                    ['<'] = { action = 'open', pair = '<>', neigh_pattern = '[{][}]' },
                    ['>'] = { action = 'close', pair = '<>', neigh_pattern = '[{][}]' },
                },
            })
            require('mini.splitjoin').setup({})
            require('mini.statusline').setup({})
            require('mini.surround').setup({})
            require('mini.tabline').setup({})
            vim.api.nvim_set_hl(0, 'MiniTablineModifiedHidden', { link = 'DiffChange' })
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
            require('mini.trailspace').setup({})
        end },
     { "nvim-mini/mini.icons", opts = {}, lazy = true, specs = { { "nvim-tree/nvim-web-devicons", enabled = false, optional = true }, }, init = function() package.preload["nvim-web-devicons"] = function() require("mini.icons").mock_nvim_web_devicons() return package.loaded["nvim-web-devicons"] end end, },

    -- additional spellcheck lists, updated on every pull
    { 'psliwka/vim-dirtytalk', build = ':DirtytalkUpdate' },

    -- language packs
    { 'sheerun/vim-polyglot' },

    -- markdown rendering
    { 'MeanderingProgrammer/markdown.nvim',
        dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.nvim' },
        config = function()
            require('render-markdown').setup({})
        end,
    },

    -- ansible syntax highlighting
    { 'pearofducks/ansible-vim' },
    { 'mfussenegger/nvim-ansible' },

    -- where in the YAML structure are we
    { 'Einenlum/yaml-revealer' },

    -- automatic mgmt of hlsearch
    { 'asiryk/auto-hlsearch.nvim',
      config = function()
        require('auto-hlsearch').setup()
      end },

    -- use a yank buffer
    { 'ptdewey/yankbank-nvim',
        dependencies = 'kkharji/sqlite.lua',
        config = function()
            require('yankbank').setup({
                persist_type = "sqlite",
            })
        end,
    },

    -- scrollbar since i can't get mini.map scrollbar to work
    { 'ojroques/nvim-scrollbar',
        config = function()
            require('scrollbar').setup()
        end },

    -- automatic handling of relativenumber
    { 'sitiom/nvim-numbertoggle' },

    -- automatic restoration of view when switching buffers
    { 'BranimirE/fix-auto-scroll.nvim', config = true, event = 'VeryLazy' },

    -- make misspellings diag errors
    { 'ravibrock/spellwarn.nvim', event = 'VeryLazy', config = true, },

    -- telescope
    -- see after/plugin/telescope.lua for config
    { 'nvim-telescope/telescope.nvim',
        branch = '0.1.x',
        dependencies = { 'nvim-lua/plenary.nvim' },
    },

    -- tree sitter
    -- see after/plugin/treesitter.lua for config
    { 'nvim-treesitter/nvim-treesitter',
        build = function()
            local ts_update = require('nvim-treesitter.install').update({ with_sync = true })
            ts_update()
        end,
        dependencies = {
            {'VonHeikemen/lsp-zero.nvim', branch = 'v4.x'},
            {'neovim/nvim-lspconfig'},
            {'williamboman/mason.nvim'},
            {'williamboman/mason-lspconfig.nvim'},
            {'hrsh7th/nvim-cmp'},
            {'hrsh7th/cmp-buffer'},
            {'hrsh7th/cmp-cmdline'},
            {'hrsh7th/cmp-path'},
            {'hrsh7th/cmp-nvim-lsp'},
            {'tzachar/cmp-tabnine', build = './install.sh'},
            {'L3MON4D3/LuaSnip',
                dependencies = {'rafamadriz/friendly-snippets'},
            },
            {'saadparwaiz1/cmp_luasnip'},
        },
    },
})
