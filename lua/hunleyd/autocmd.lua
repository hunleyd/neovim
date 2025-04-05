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

-- Ensure that the binary spl file is up-to-date with the source add file
vim.api.nvim_create_autocmd("FocusGained", {
  pattern = "*",
  callback = function()
    local config_path = vim.fn.stdpath("config") -- Get Neovim's config path
    local add_file = config_path .. "/spell/en.utf-8.add"
    local spl_file = config_path .. "/spell/en.utf-8.add.spl"

    if vim.fn.filereadable(add_file) == 1 then
      local add_mtime = vim.fn.getftime(add_file) -- Get modification time of .add file
      local spl_mtime = vim.fn.getftime(spl_file) -- Get modification time of .add.spl file

      -- Run mkspell! only if .add is newer than .add.spl or .add.spl doesn't exist
      if add_mtime > spl_mtime or spl_mtime == -1 then
        vim.cmd("silent! mkspell! " .. spl_file .. " " .. add_file)
      end
    end
  end,
})

-- use vtext for diags and stuff
local og_virt_text
local og_virt_line
vim.api.nvim_create_autocmd({ 'CursorMoved', 'DiagnosticChanged' }, {
  group = vim.api.nvim_create_augroup('diagnostic_only_virtlines', {}),
  callback = function()
    if og_virt_line == nil then
      og_virt_line = vim.diagnostic.config().virtual_lines
    end

    -- ignore if virtual_lines.current_line is disabled
    if not (og_virt_line and og_virt_line.current_line) then
      if og_virt_text then
        vim.diagnostic.config({ virtual_text = og_virt_text })
        og_virt_text = nil
      end
      return
    end

    if og_virt_text == nil then
      og_virt_text = vim.diagnostic.config().virtual_text
    end

    local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1

    if vim.tbl_isempty(vim.diagnostic.get(0, { lnum = lnum })) then
      vim.diagnostic.config({ virtual_text = og_virt_text })
    else
      vim.diagnostic.config({ virtual_text = false })
    end
  end
})
