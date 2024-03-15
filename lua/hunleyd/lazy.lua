local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- lazy needs leader set before loading plugins
vim.g.mapleader = " "
vim.g.maplocalleader = " "

return require('lazy').setup({
    -- undotree
    'mbbill/undotree',

    -- theme
    { "miikanissi/modus-themes.nvim", priority = 1000, as = 'modus' },

    -- make Jim better at vi
    'm4xshen/hardtime.nvim',

    -- statusline
    'bluz71/nvim-linefly',

    -- statuscol
    { "luukvbaal/statuscol.nvim", config = function()
      -- local builtin = require("statuscol.builtin")
      require("statuscol").setup({
        -- configuration goes here, for example:
        -- relculright = true,
        -- segments = {
        --   { text = { builtin.foldfunc }, click = "v:lua.ScFa" },
        --   {
        --     sign = { name = { "Diagnostic" }, maxwidth = 2, auto = true },
        --     click = "v:lua.ScSa"
        --   },
        --   { text = { builtin.lnumfunc }, click = "v:lua.ScLa", },
        --   {
        --     sign = { name = { ".*" }, maxwidth = 2, colwidth = 1, auto = true, wrap = true },
        --     click = "v:lua.ScSa"
        --   },
        -- }
      })
      end,
    },

    -- apply window dressing
    'stevearc/dressing.nvim',

    -- visual highlight entire line
    { '0xAdk/full_visual_line.nvim', keys = 'V', opts = {}, },

    -- load mini plugin collection
    { 'echasnovski/mini.nvim', version = false },

    -- show indent levels
    'nathanaelkane/vim-indent-guides',

    -- git-related plugins
    'lewis6991/gitsigns.nvim',
    'sindrets/diffview.nvim',

    -- additional spellcheck lists, updated on every pull
    { 'psliwka/vim-dirtytalk', build = ':DirtytalkUpdate' },

    -- language packs
    'sheerun/vim-polyglot',

    -- ansible syntax highlighting
    'pearofducks/ansible-vim',
    'mfussenegger/nvim-ansible',

    -- where in the YAML structure are we
    'Einenlum/yaml-revealer',

    -- auto-create toc in md with :TOC
    'richardbizik/nvim-toc',

    -- automatic mgmt of hlsearch
    'asiryk/auto-hlsearch.nvim',

    -- put diags into top-right corner
    'dgagn/diagflow.nvim',

    -- telescope
    {
        'nvim-telescope/telescope.nvim', branch = '0.1.x',
        dependencies = { { 'nvim-lua/plenary.nvim' } },
    },

    -- tree sitter
    {
            'nvim-treesitter/nvim-treesitter',
            build = function()
                local ts_update = require('nvim-treesitter.install').update({ with_sync = true })
                ts_update()
            end,
    },
--    { 'nvim-treesitter/nvim-treesitter', build = ':TSUpdate' },

    -- LSP (via lsp-zero / mason)
    {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v2.x',
        dependencies = {
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
            { 'tzachar/cmp-tabnine', build = './install.sh' },

            -- Snippets
            { 'L3MON4D3/LuaSnip' , tag = "v2.1.1", build = "make install_jsregexp" },
            { 'rafamadriz/friendly-snippets' },
        },
    },
})
