-- Custom Help Display
-- Shows keybindings cheat sheet in a floating window

local M = {}

function M.show_help()
    -- Get the help file path
    local help_file = vim.fn.stdpath("config") .. "/KEYBINDINGS.md"

    -- Check if file exists
    if vim.fn.filereadable(help_file) == 0 then
        vim.notify("Help file not found: " .. help_file, vim.log.levels.ERROR)
        return
    end

    -- Read the file
    local lines = {}
    for line in io.lines(help_file) do
        table.insert(lines, line)
    end

    -- Calculate window size (80% of screen)
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.8)

    -- Calculate position (centered)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    -- Create a buffer
    local buf = vim.api.nvim_create_buf(false, true)

    -- Set buffer options
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)

    -- Set buffer content
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)

    -- Window options
    local opts = {
        relative = 'editor',
        width = width,
        height = height,
        row = row,
        col = col,
        style = 'minimal',
        border = 'rounded',
        title = ' Keybindings Help ',
        title_pos = 'center',
    }

    -- Open the window
    local win = vim.api.nvim_open_win(buf, true, opts)

    -- Window-local options
    vim.api.nvim_win_set_option(win, 'wrap', true)
    vim.api.nvim_win_set_option(win, 'linebreak', true)
    vim.api.nvim_win_set_option(win, 'cursorline', true)

    -- Keybindings to close the window
    local close_keys = {'q', '<Esc>', '<CR>'}
    for _, key in ipairs(close_keys) do
        vim.api.nvim_buf_set_keymap(buf, 'n', key, ':close<CR>',
            { silent = true, noremap = true })
    end

    -- Enable scrolling
    vim.api.nvim_buf_set_keymap(buf, 'n', 'j', 'j', { silent = true, noremap = true })
    vim.api.nvim_buf_set_keymap(buf, 'n', 'k', 'k', { silent = true, noremap = true })
    vim.api.nvim_buf_set_keymap(buf, 'n', '<C-d>', '<C-d>', { silent = true, noremap = true })
    vim.api.nvim_buf_set_keymap(buf, 'n', '<C-u>', '<C-u>', { silent = true, noremap = true })
end

return M
