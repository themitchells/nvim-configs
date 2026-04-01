-- Autocommands
-- Migrated from ~/.vim/vimrcs/extended.vim

-- File cleanup on save
local cleanup_group = vim.api.nvim_create_augroup('FileCleanup', { clear = true })
vim.api.nvim_create_autocmd('BufWrite', {
    group = cleanup_group,
    pattern = '*',
    callback = function()
        require('utils.helpers').cleanup_file()
    end,
})

-- Filetype-specific settings
local filetype_group = vim.api.nvim_create_augroup('FiletypeSettings', { clear = true })

-- Make files should use real tabs
vim.api.nvim_create_autocmd('FileType', {
    group = filetype_group,
    pattern = 'make',
    callback = function()
        vim.opt_local.expandtab = false
    end,
})

-- Verilog files should not use smartindent (conflicts with indent file)
vim.api.nvim_create_autocmd('FileType', {
    group = filetype_group,
    pattern = 'systemverilog',
    callback = function()
        vim.opt_local.smartindent = false
        vim.opt_local.autoindent = true
    end,
})

-- YAML files use 2-space indentation
vim.api.nvim_create_autocmd('FileType', {
    group = filetype_group,
    pattern = 'yaml',
    callback = function()
        vim.opt_local.tabstop = 2
        vim.opt_local.shiftwidth = 2
        vim.opt_local.softtabstop = 2
        vim.opt_local.expandtab = true
    end,
})

-- Python files
vim.api.nvim_create_autocmd('FileType', {
    group = filetype_group,
    pattern = 'python',
    callback = function()
        vim.opt_local.tabstop = 4
        vim.opt_local.shiftwidth = 4
        vim.opt_local.softtabstop = 4
        vim.opt_local.expandtab = true
    end,
})

-- Disable sign column in sidebar/tool windows
vim.api.nvim_create_autocmd('FileType', {
    group = filetype_group,
    pattern = { 'buffergator', 'NvimTree' },
    callback = function()
        vim.opt_local.signcolumn = 'no'
    end,
})

-- Custom filetype overrides for PHP-preprocessed project files
local custom_ft_group = vim.api.nvim_create_augroup('CustomFiletype', { clear = true })
local custom_ft_map = {
    ['*.prj.php']     = 'tcl',
    ['*.sta.xdc.php'] = 'sdc',
    ['*.tcl.php']     = 'tcl',
}
for pattern, ft in pairs(custom_ft_map) do
    vim.api.nvim_create_autocmd({'BufNewFile', 'BufRead'}, {
        group = custom_ft_group,
        pattern = pattern,
        callback = function() vim.bo.filetype = ft end,
    })
end

-- Detect filetype from shebang line.  Returns a filetype string or nil.
local function ft_from_shebang(bufnr)
    local line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] or ''
    if not line:match('^#!') then return nil end
    local interp = line:match('^#!/usr/bin/env%s+(%S+)')
                or line:match('^#!.*/(%S+)%s*$')
    if not interp then return nil end
    interp = interp:match('^(%a+)')  -- strip version suffix (python3 → python)
    local map = {
        bash=  'bash',   sh=    'sh',   zsh=  'zsh',
        python='python', perl=  'perl', ruby= 'ruby',
        lua=   'lua',    node=  'javascript',
        tclsh= 'tcl',    wish=  'tcl',
    }
    return map[interp]
end

-- Verilog/SystemVerilog filetype detection
-- All extensions map to 'systemverilog'
vim.filetype.add({
    -- jbuild is normally detected as 'dune' by filename, but if it has a
    -- shebang it's a plain script — check shebang first.
    filename = {
        jbuild = function(_, bufnr)
            return ft_from_shebang(bufnr) or 'dune'
        end,
    },
    extension = {
        v   = 'systemverilog',
        vh  = 'systemverilog',
        vp  = 'systemverilog',
        sv  = 'systemverilog',
        svi = 'systemverilog',
        svh = 'systemverilog',
        svp = 'systemverilog',
        sva = 'systemverilog',
    },
})

-- Window title updates
local title_group = vim.api.nvim_create_augroup('WindowTitle', { clear = true })
vim.api.nvim_create_autocmd('BufEnter', {
    group = title_group,
    callback = function()
        require('utils.helpers').set_window_name()
    end,
})

-- Window view preservation
local view_group = vim.api.nvim_create_augroup('PreserveView', { clear = true })
vim.api.nvim_create_autocmd('BufLeave', {
    group = view_group,
    pattern = '*',
    callback = function()
        require('utils.helpers').auto_save_win_view()
    end,
})

vim.api.nvim_create_autocmd('BufEnter', {
    group = view_group,
    pattern = '*',
    callback = function()
        require('utils.helpers').auto_restore_win_view()
    end,
})


-- Return to last edit position when opening files
vim.api.nvim_create_autocmd('BufReadPost', {
    callback = function()
        local mark = vim.api.nvim_buf_get_mark(0, '"')
        local lcount = vim.api.nvim_buf_line_count(0)
        if mark[1] > 0 and mark[1] <= lcount then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})

-- Config reload on save
local vimrc_group = vim.api.nvim_create_augroup('VimrcReload', { clear = true })
vim.api.nvim_create_autocmd('BufWritePost', {
    group = vimrc_group,
    pattern = vim.fn.expand('~/.config/nvim/init.lua'),
    callback = function()
        vim.cmd('source ' .. vim.fn.expand('~/.config/nvim/init.lua'))
    end,
})

-- Colorscheme customization
local colorscheme_group = vim.api.nvim_create_augroup('ColorschemeCustomization', { clear = true })

vim.api.nvim_create_autocmd('ColorScheme', {
    group = colorscheme_group,
    callback = function()
        -- Will be implemented when colorscheme module exists
        local ok, tinted = pcall(require, 'colorscheme.tinted')
        if ok then
            tinted.customize_highlights()
        end
    end,
})

vim.api.nvim_create_autocmd('FocusGained', {
    group = colorscheme_group,
    callback = function()
        local ok, tinted = pcall(require, 'colorscheme.tinted')
        if ok then
            tinted.setup()
        end
    end,
})

-- Session management
local session_group = vim.api.nvim_create_augroup('SessionManagement', { clear = true })

vim.api.nvim_create_autocmd('VimLeave', {
    group = session_group,
    callback = function()
        local ok, session = pcall(require, 'sessions.manager')
        if ok then
            session.save_session_on_close()
        end
    end,
})

vim.api.nvim_create_autocmd('VimEnter', {
    group = session_group,
    nested = true,
    callback = function()
        local ok, session = pcall(require, 'sessions.manager')
        if ok then
            session.load_session_servername()
        end
    end,
})
