require('mini.pairs').setup({
    mappings = {
        [' '] = { action = 'open', pair = '  ', neigh_pattern = '[%(%[{][%)%]}]' },
        ['%'] = { action = 'open', pair = '%%', neigh_pattern = '[{][}]' },
        ['<'] = { action = 'open', pair = '<>', neigh_pattern = '[{][}]' },
        ['>'] = { action = 'close', pair = '<>', neigh_pattern = '[{][}]' },
    },
})
