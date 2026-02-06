-- Buffer Management Utilities
-- Migrated from ~/.vim/vimrcs/extended.vim

local M = {}

-- Bclose command - close buffer without closing window
function M.buf_close()
    local current_buf = vim.fn.bufnr("%")
    local alternate_buf = vim.fn.bufnr("#")

    if vim.fn.buflisted(alternate_buf) == 1 then
        vim.cmd("buffer #")
    else
        vim.cmd("bnext")
    end

    if vim.fn.bufnr("%") == current_buf then
        vim.cmd("new")
    end

    if vim.fn.buflisted(current_buf) == 1 then
        vim.cmd("bdelete! " .. current_buf)
    end
end

-- Bd command - close buffer without closing split
function M.bd()
    vim.cmd("b#|bd #")
end

-- Create user commands
vim.api.nvim_create_user_command('Bclose', function()
    M.buf_close()
end, { desc = "Close buffer without closing window" })

vim.api.nvim_create_user_command('Bd', function()
    M.bd()
end, { desc = "Close buffer without closing split" })

return M
