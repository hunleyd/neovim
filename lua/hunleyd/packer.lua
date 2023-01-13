-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
    -- Packer can manage itself
    use 'wbthomason/packer.nvim'

    -- undotree
    use 'mbbill/undotree'

    -- theme
    use { 'kvrohit/mellow.nvim', as = 'mellow' }

    -- apply window dressing
    use 'stevearc/dressing.nvim'

    -- load mini plugin collection
    use { 'echasnovski/mini.nvim', branch = 'main' }

    -- show indent levels
    use 'nathanaelkane/vim-indent-guides'

    -- take me to where i was when last editing this file
    -- use 'farmergreg/vim-lastplace'

    -- git-related plugins
    use 'lewis6991/gitsigns.nvim'
    use 'sindrets/diffview.nvim'

    -- additional spellcheck lists, updated on every pull
    use({ 'psliwka/vim-dirtytalk', run = ':DirtytalkUpdate' })

    -- language packs
    use 'sheerun/vim-polyglot'

    -- ansible syntax highlighting
    use 'pearofducks/ansible-vim'

    -- where in the YAML structure are we
    use 'Einenlum/yaml-revealer'

    -- automatic mgmt of hlsearch
    use 'asiryk/auto-hlsearch.nvim'

    -- automatic mgmt of soft/hard wrap
    use 'andrewferrier/wrapping.nvim'

    -- telescope
    use {
        'nvim-telescope/telescope.nvim', tag = '0.1.0',
        -- or                            , branch = '0.1.x',
        requires = { { 'nvim-lua/plenary.nvim' } }
    }

    -- tree sitter
    use({ 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' })

    -- LSP (via lsp-zero / mason)
    use {
        'VonHeikemen/lsp-zero.nvim',
        requires = {
            -- LSP Support
            { 'neovim/nvim-lspconfig' },
            { 'williamboman/mason.nvim' },
            { 'williamboman/mason-lspconfig.nvim' },

            -- Autocompletion
            { 'hrsh7th/nvim-cmp' },
            { 'hrsh7th/cmp-buffer' },
            { 'hrsh7th/cmp-path' },
            { 'saadparwaiz1/cmp_luasnip' },
            { 'hrsh7th/cmp-nvim-lsp' },
            { 'hrsh7th/cmp-nvim-lua' },
            { 'tzachar/cmp-tabnine', run = './install.sh' },

            -- Snippets
            { 'L3MON4D3/LuaSnip' },
            { 'rafamadriz/friendly-snippets' },
        }
    }
end)
