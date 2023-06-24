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

    -- statusline
    use 'bluz71/nvim-linefly'

    -- apply window dressing
    use 'stevearc/dressing.nvim'

    -- fancy notifications
    use 'rcarriga/nvim-notify'

    -- lsp progress ui
    use 'j-hui/fidget.nvim'

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

    -- where in the YAML structure are we
    use 'Einenlum/yaml-revealer'

    -- automatic mgmt of hlsearch
    use 'asiryk/auto-hlsearch.nvim'

    -- put diags into virtual lines
    use 'https://git.sr.ht/~whynothugo/lsp_lines.nvim'

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
        branch = 'v2.x',
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
