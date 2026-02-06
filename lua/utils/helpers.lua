-- Utility Helper Functions
-- Migrated from ~/.vim/vimrcs/extended.vim

local M = {}

-- HasPaste function for status line
function M.has_paste()
    if vim.o.paste then
        return 'PASTE MODE  '
    end
    return ''
end

-- Visual selection helper
function M.visual_selection(direction, extra_filter)
    local saved_reg = vim.fn.getreg('"')
    local saved_reg2 = vim.fn.getreg('+')

    vim.cmd('normal! vgvy')

    local pattern = vim.fn.escape(vim.fn.getreg('"'), '\\/.*$^~[]')
    pattern = vim.fn.substitute(pattern, "\n$", "", "")

    if direction == 'b' then
        vim.cmd('normal! ?' .. pattern)
    elseif direction == 'gv' then
        vim.fn.execute("vimgrep /" .. pattern .. "/ **/*." .. extra_filter)
    elseif direction == 'replace' then
        vim.fn.execute("%s/" .. pattern .. "/")
    elseif direction == 'f' then
        vim.cmd('normal! /' .. pattern)
    end

    vim.fn.setreg('/', pattern)
    vim.fn.setreg('"', saved_reg)
    vim.fn.setreg('+', saved_reg2)
end

-- Delete till slash (command-line helper)
function M.delete_till_slash()
    local cmd = vim.fn.getcmdline()
    local cmd_edited

    if vim.fn.has("win32") == 1 then
        cmd_edited = vim.fn.substitute(cmd, "\\(.*[\\\\]\\).*", "\\1", "")
    else
        cmd_edited = vim.fn.substitute(cmd, "\\(.*[/]\\).*", "\\1", "")
    end

    if cmd == cmd_edited then
        if vim.fn.has("win32") == 1 then
            cmd_edited = vim.fn.substitute(cmd, "\\(.*[\\\\\\\\]\\).*[\\\\\\\\]", "\\1", "")
        else
            cmd_edited = vim.fn.substitute(cmd, "\\(.*[/]\\).*/", "\\1", "")
        end
    end

    return cmd_edited
end

-- Current file directory helper
function M.current_file_dir(cmd)
    return cmd .. " " .. vim.fn.expand("%:p:h") .. "/"
end

-- Auto increment numbers in visual selection
function M.incr()
    local a = vim.fn.line('.') - vim.fn.line("'<")
    local c = vim.fn.virtcol("'<")
    if a > 0 then
        vim.cmd('normal! ' .. c .. '|' .. a .. "\x01") -- \x01 is Ctrl-A
    end
    vim.cmd("normal! `<")
end

-- Set window name/title
function M.set_window_name()
    local filename = vim.fn.expand("%:t")
    local filepath = vim.fn.expand("%:p")
    local modified = vim.bo.modified and "[+] " or ""

    -- Extract view name from ClearCase-style path
    local viewname = vim.fn.substitute(filepath, ".*/\\([^/]*\\)/vobs/.*", "\\1", "")

    if viewname == filepath then
        -- Not a ClearCase path
        vim.o.titlestring = modified .. vim.v.servername .. " - " .. filepath
    else
        -- ClearCase path
        vim.o.titlestring = modified .. vim.v.servername .. " - <" .. viewname .. "> - " .. filepath
    end
end

-- Auto save/restore window view
M.saved_buf_view = {}

function M.auto_save_win_view()
    local buf = vim.fn.bufnr("%")
    M.saved_buf_view[buf] = vim.fn.winsaveview()
end

function M.auto_restore_win_view()
    local buf = vim.fn.bufnr("%")
    if M.saved_buf_view[buf] then
        local v = vim.fn.winsaveview()
        local at_start = v.lnum == 1 and v.col == 0
        if at_start and not vim.wo.diff then
            vim.fn.winrestview(M.saved_buf_view[buf])
        end
        M.saved_buf_view[buf] = nil
    end
end

-- Git diff current file
function M.git_diff()
    vim.fn.mkdir(vim.fn.expand("~/.tmp"), "p")
    vim.cmd('!git diff --no-ext-diff % 2>&1 | tee ~/.tmp/git_diff_output.log')
end

-- Clean up file (remove trailing whitespace, fix line endings, convert tabs)
function M.cleanup_file()
    local pos = vim.fn.getpos('.')

    -- Convert to Unix line endings
    vim.bo.fileformat = 'unix'

    -- Remove Windows carriage returns
    vim.cmd([[silent! %s/\r//g]])

    -- Convert tabs to spaces (except in filetypes that use tabs by convention)
    local tab_filetypes = {
        'make',      -- Makefiles require tabs
        'go',        -- Go uses tabs by convention
        'tsv',       -- Tab-separated values
        'gitconfig', -- Git config uses tabs
        'diff',      -- Diff/patch files
        'snippets',  -- Snippet files may use tabs for indentation markers
    }

    if not vim.tbl_contains(tab_filetypes, vim.bo.filetype) then
        vim.cmd([[silent! %s/\t/    /g]])
    end

    -- Remove trailing whitespace
    vim.cmd([[silent! %s/\s\+$//ge]])

    -- Restore cursor position
    vim.fn.setpos('.', pos)
end

-- Make global functions available for command-line mappings
_G.DeleteTillSlash = M.delete_till_slash
_G.CurrentFileDir = M.current_file_dir
_G.HasPaste = M.has_paste

return M
