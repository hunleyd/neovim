-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd.packadd('packer.nvim')

return require('packer').startup(function(use)
    -- Packer can manage itself
    use 'wbthomason/packer.nvim'

    -- undotree
    use 'mbbill/undotree'

    -- theme
    use { 'dasupradyumna/midnight.nvim', as = 'midnight' }

    -- make Jim better at vi
    use 'm4xshen/hardtime.nvim'

    -- statusline
    use 'bluz71/nvim-linefly'

    -- apply window dressing
    use 'stevearc/dressing.nvim'

    -- fancy notifications
    use 'rcarriga/nvim-notify'

    -- lsp progress ui
    use { 'j-hui/fidget.nvim', tag = 'legacy' }

    -- load mini plugin collection
    use { 'echasnovski/mini.nvim', branch = 'main' }

    -- show indent levels
    use 'nathanaelkane/vim-indent-guides'

    -- git-related plugins
    use 'lewis6991/gitsigns.nvim'
    use 'sindrets/diffview.nvim'

    -- additional spellcheck lists, updated on every pull
    use({ 'psliwka/vim-dirtytalk', run = ':DirtytalkUpdate' })

    -- language packs
    use 'sheerun/vim-polyglot'

    -- ansible syntax highlighting
    use 'pearofducks/ansible-vim'
    use 'mfussenegger/nvim-ansible'

    -- where in the YAML structure are we
    use 'Einenlum/yaml-revealer'

    -- auto-create toc in md with :TOC
    use 'richardbizik/nvim-toc'

    -- automatic mgmt of hlsearch
    use 'asiryk/auto-hlsearch.nvim'

    -- put diags into top-right corner
    use 'dgagn/diagflow.nvim'

    -- telescope
    use {
        'nvim-telescope/telescope.nvim', branch = '0.1.x',
        requires = { { 'nvim-lua/plenary.nvim' } }
    }

    -- tree sitter
    use {
            'nvim-treesitter/nvim-treesitter',
            run = function()
                local ts_update = require('nvim-treesitter.install').update({ with_sync = true })
                ts_update()
            end,}
--    use({ 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' })

    -- LSP (via lsp-zero / mason)
    use {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v2.x',
        requires = {
            -- LSP Support
            { 'neovim/nvim-lspconfig' },
            { 'williamboman/mason.nvim' },
            { 'williamboman/mason-lspconfig.nvim' },

            -- Autocompletion
            { 'hrsh7th/nvim-cmp',
            config = function ()
              require'cmp'.setup {
                  snippet = {
                      expand = function(args)
                          require'luasnip'.lsp_expand(args.body)
                      end
                  },
              }
          end
              },
            { 'hrsh7th/cmp-buffer' },
            { 'hrsh7th/cmp-path' },
            { 'saadparwaiz1/cmp_luasnip' },
            { 'hrsh7th/cmp-nvim-lsp' },
            { 'hrsh7th/cmp-nvim-lua' },
            { 'tzachar/cmp-tabnine',              run = './install.sh' },

            -- Snippets
            { 'L3MON4D3/LuaSnip' },
            { 'rafamadriz/friendly-snippets' },
        }
    }
end)
