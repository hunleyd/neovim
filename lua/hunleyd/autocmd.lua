-- Taken from https://github.com/norcalli/nvim_utils
local function nvim_create_augroups(definitions)
    for group_name, definition in pairs(definitions) do
        vim.api.nvim_command('augroup ' .. group_name)
        vim.api.nvim_command('autocmd!')
        for _, def in ipairs(definition) do
            local command = table.concat(vim.tbl_flatten { 'autocmd', def }, ' ')
            vim.api.nvim_command(command)
        end
        vim.api.nvim_command('augroup END')
    end
end

local autocmds = {
    set_formatoptions = {
        { "BufEnter", "*", "setlocal formatoptions-=o" };
    };
    ansible_filetype = {
        { "BufNewFile,BufReadPost", "*.yml", "set filetype=yaml.ansible" };
    };
    ansible_modeline = {
        { "FileType", "yaml.ansible", "setlocal ts=2 sts=2 sw=2 expandtab" };
    };
    ansible_keyword = {
        { "FileType", "yaml.ansible", "setlocal iskeyword-=." };
    };
    css_filetype = {
        { "BufRead,BufNewFile", "*.{css,scss}", "setf css" };
    };
    css_modeline = {
        { "FileType", "css", "set sts=2 ts=2 sw=2 tw=79" };
    };
    markdown_filetype = {
        { "BufRead,BufNewFile", "*.{md,markdown,mdown,mkd,mkdn}", "setf markdown" };
    };
    enable_spellcheck = {
        { "BufEnter", "*", "set spell" };
    };
    autoinsert_on_terminal = {
        { "TermOpen", "*", "setlocal nonumber norelativenumber | startinsert" };
    };
    json_filetype = {
        { "BufNewFile,BufReadPost", "*.json", "set filetype=json" };
    };
    ansible_doc = {
        { "BufNewFile,BufRead", "*.yml", "set keywordprg=ansible-doc" };
    };
    templates = {
        { "BufNewFile", "*.*", "silent! execute '0r ~/.config/nvim/skeletons/skeleton.'.expand('<afile>:e')" };
    };
    autocenter = {
        { "BufEnter,WinEnter,WinNew,VimResized", "*,*.*", "let &scrolloff=winheight(win_getid())/2" };
    };
    screenkey = {
        { "BufEnter", "*", "Screenkey toggle" };
    };
}

nvim_create_augroups(autocmds)

-- return to last location in file when re-opening
vim.api.nvim_create_autocmd('BufReadPost', {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

