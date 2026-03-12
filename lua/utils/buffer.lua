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

-- ── Rename ────────────────────────────────────────────────────────────────────
-- Rename (and optionally move) the current buffer's file.
-- Uses nvim_buf_set_name to rename in-place (same bufnr), so the
-- undo history is fully preserved and no ghost buffer is left behind.
-- The on-disk undofile is migrated so persistent undo also survives.
--
-- Two calling modes (both invoke the same logic):
--   :Rename            → vim.ui.input prompt, pre-filled with current path
--   :Rename new/path   → rename directly, no prompt
--   :Rename %<Tab>     → % is expanded to current path by Vim's file
--                        completion; edit on the command line, then Enter

local function do_rename(old_path, new_path)
    new_path = vim.fn.expand(new_path)

    if new_path == "" or new_path == old_path then return end

    if vim.fn.filereadable(new_path) == 1 then
        vim.notify("Rename: destination already exists: " .. new_path, vim.log.levels.ERROR)
        return
    end

    -- Create parent directories as needed
    local new_dir = vim.fn.fnamemodify(new_path, ":h")
    if vim.fn.isdirectory(new_dir) == 0 then
        vim.fn.mkdir(new_dir, "p")
    end

    local old_undo   = vim.o.undofile and vim.fn.undofile(old_path) or nil
    local new_undo   = vim.o.undofile and vim.fn.undofile(new_path) or nil
    local bufnr      = vim.api.nvim_get_current_buf()
    local old_exists = vim.fn.filereadable(old_path) == 1

    if old_exists then
        -- Flush unsaved changes before moving the file
        if vim.bo[bufnr].modified then
            local ok, err = pcall(vim.cmd, "write")
            if not ok then
                vim.notify("Rename: could not save buffer: " .. tostring(err), vim.log.levels.ERROR)
                return
            end
        end
        -- Move the existing file on disk
        if vim.fn.rename(old_path, new_path) ~= 0 then
            vim.notify("Rename: failed to move file on disk", vim.log.levels.ERROR)
            return
        end
    end

    -- Rename buffer in-place: same bufnr, undo history intact, no ghost buffer
    vim.api.nvim_buf_set_name(bufnr, new_path)

    -- Sync buffer write-state with the new path. write! is needed in both cases:
    -- for existing files, nvim_buf_set_name resets write-tracking so Neovim would
    -- otherwise report "file exists" on the next :w; for new buffers it creates the file.
    local ok, err = pcall(vim.cmd, "silent write!")
    if not ok then
        vim.notify("Rename: could not write to new path: " .. tostring(err), vim.log.levels.ERROR)
        return
    end

    -- Re-detect filetype if the extension changed
    if vim.fn.fnamemodify(old_path, ":e") ~= vim.fn.fnamemodify(new_path, ":e") then
        vim.cmd("filetype detect")
    end

    -- Migrate the on-disk undofile so persistent undo works under the new name
    if old_undo and new_undo and vim.fn.filereadable(old_undo) == 1 then
        local undo_dir = vim.fn.fnamemodify(new_undo, ":h")
        if vim.fn.isdirectory(undo_dir) == 0 then
            vim.fn.mkdir(undo_dir, "p")
        end
        vim.fn.rename(old_undo, new_undo)
    end

    vim.notify(string.format("Renamed: %s → %s",
        vim.fn.fnamemodify(old_path, ":~:."),
        vim.fn.fnamemodify(new_path, ":~:.")),
        vim.log.levels.INFO)
end

function M.rename(new_path_arg)
    local old_path = vim.api.nvim_buf_get_name(0)
    if old_path == "" then
        vim.notify("Rename: buffer has no file name", vim.log.levels.WARN)
        return
    end
    if new_path_arg and new_path_arg ~= "" then
        -- Command-line argument supplied (e.g. :Rename new_name or :Rename %<Tab>)
        do_rename(old_path, new_path_arg)
    else
        -- Interactive prompt with current path pre-filled
        vim.ui.input({
            prompt     = "Rename to: ",
            default    = old_path,
            completion = "file",
        }, function(new_path)
            if new_path then do_rename(old_path, new_path) end
        end)
    end
end

-- Create user commands
vim.api.nvim_create_user_command('Bclose', function()
    M.buf_close()
end, { desc = "Close buffer without closing window" })

vim.api.nvim_create_user_command('Bd', function()
    M.bd()
end, { desc = "Close buffer without closing split" })

vim.api.nvim_create_user_command('Rename', function(opts)
    M.rename(opts.args ~= "" and opts.args or nil)
end, {
    nargs    = "?",
    complete = "file",
    desc     = "Rename/move current buffer file, preserving undo history",
})

return M
