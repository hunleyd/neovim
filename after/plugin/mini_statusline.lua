require('mini.statusline').setup({
    content = {
        active = function()
            -- stylua: ignore start
            local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
            local spell         = vim.wo.spell and (MiniStatusline.is_truncated(120) and 'S' or 'SPELL') or ''
            local wrap          = require('wrapping').get_current_mode()
            -- local wrap          = vim.wo.wrap and (MiniStatusline.is_truncated(120) and 'W' or 'WRAP') or ''
            local git           = MiniStatusline.section_git({ trunc_width = 75 })
            -- Default diagnstics icon has some problems displaying in Kitty terminal
            local diagnostics   = MiniStatusline.section_diagnostics({ trunc_width = 75 })
            local filename      = MiniStatusline.section_filename({ trunc_width = 140 })
            local fileinfo      = MiniStatusline.section_fileinfo({ trunc_width = 120 })
            local searchcount   = MiniStatusline.section_searchcount({ trunc_width = 75 })
            local location      = MiniStatusline.section_location({ trunc_width = 75 })

            -- Usage of `MiniStatusline.combine_groups()` ensures highlighting and
            -- correct padding with spaces between groups (accounts for 'missing'
            -- sections, etc.)
            return MiniStatusline.combine_groups({
                { hl = mode_hl, strings = { mode } },
                { hl = mode_hl, strings = { wrap } },
                --        { hl = 'MiniStatuslineDevinfo', strings = { diagnostics } },
                '%<', -- Mark general truncate point
                { hl = mode_hl, strings = { filename } },
                '%=', -- End left alignment
                { hl = 'MiniStatuslineFileinfo', strings = { fileinfo } },
                { hl = mode_hl, strings = { searchcount, location } },
            })
            -- stylua: ignore end
        end,
    },
    set_vim_settings = false,
    use_icons = false,
})
vim.api.nvim_set_hl(0, "MiniStatuslineModeNormal", { link = 'Noise' })
