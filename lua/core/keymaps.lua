-- Additional Keymaps
-- Migrated from ~/.vim/vimrcs/extended.vim

-- Map <Space> to / (search) and Ctrl-<Space> to ? (backwards search)
vim.keymap.set('n', '<space>', '/', { desc = "Search forward" })
vim.keymap.set('n', '<C-space>', '?', { desc = "Search backward" })

-- Disable search highlighting with <leader><cr>
vim.keymap.set('n', '<silent> <leader><cr>', ':noh<cr>', { silent = true, desc = "Clear search highlight" })

-- Window cycling with Shift-Tab
vim.keymap.set('n', '<S-Tab>', '<C-W>w', { desc = "Cycle windows" })

-- Close current buffer intelligently
vim.keymap.set('n', '<leader>bd', ':lua require("utils.buffer").buf_close()<cr>', { desc = "Close buffer intelligently" })

-- Function key mappings
vim.keymap.set('n', '<F5>', ':lua require("utils.helpers").git_diff()<cr>', { desc = "Git diff current file" })
vim.keymap.set('n', '<F7>', ':!chmod a+x %<cr>', { desc = "Make file executable" })

-- Paste over word without yanking it (Ctrl-p)
-- This was to fix issue when pasting to a word at the end of a line
vim.keymap.set('n', '<C-p>', '"_cw<C-r>0<Esc>', { silent = true, desc = "Paste over word" })
vim.keymap.set('v', '<C-p>', '"_c<C-r>0<Esc>', { silent = true, desc = "Paste over selection" })

-- Macro replay with Ctrl-q (alternative to q)
vim.keymap.set('n', '<C-q>', 'q', { desc = "Start/stop macro recording" })

-- Command-line mode helpers
vim.keymap.set('c', '$h', 'e ~/')
vim.keymap.set('c', '$d', 'e ~/Desktop/')
vim.keymap.set('c', '$j', 'e ./')
vim.keymap.set('c', '$c', 'e <C-\\>eCurrentFileDir("e")<cr>')

-- $q is super useful when browsing on the command line
-- it deletes everything until the last slash
vim.keymap.set('c', '$q', '<C-\\>eDeleteTillSlash()<cr>')

-- Bash-like keys for the command line
vim.keymap.set('c', '<C-A>', '<Home>')
vim.keymap.set('c', '<C-E>', '<End>')
vim.keymap.set('c', '<C-K>', '<C-U>')
vim.keymap.set('c', '<C-P>', '<Up>')
vim.keymap.set('c', '<C-N>', '<Down>')

-- Useful mappings for managing tabs
vim.keymap.set('n', '<leader>tn', ':tabnew<cr>', { desc = "New tab" })
vim.keymap.set('n', '<leader>to', ':tabonly<cr>', { desc = "Close other tabs" })
vim.keymap.set('n', '<leader>tc', ':tabclose<cr>', { desc = "Close tab" })
vim.keymap.set('n', '<leader>tm', ':tabmove ', { desc = "Move tab" })

-- Remove the Windows ^M - when encodings get messed up
vim.keymap.set('n', '<Leader>m', 'mmHmt:%s/<C-V><cr>//ge<cr>\'tzt\'m', { desc = "Remove Windows ^M" })

-- Visual mode auto-increment for duplicated lines
vim.keymap.set('v', '<leader>si', ':lua require("utils.helpers").incr()<cr>', { desc = "Auto increment numbers" })

-- Copy/paste helpers
vim.keymap.set('v', '<leader>y', '"+y', { desc = "Copy to system clipboard" })
vim.keymap.set('n', '<leader>p', '"+p', { desc = "Paste from system clipboard" })

-- Buffer navigation
vim.keymap.set('n', '<leader>bn', ':bnext<cr>', { desc = "Next buffer" })
vim.keymap.set('n', '<leader>bp', ':bprevious<cr>', { desc = "Previous buffer" })
vim.keymap.set('n', '<leader>bf', ':bfirst<cr>', { desc = "First buffer" })
vim.keymap.set('n', '<leader>bl', ':blast<cr>', { desc = "Last buffer" })

-- Quick fix list
vim.keymap.set('n', '<leader>cn', ':cnext<cr>', { desc = "Next quickfix" })
vim.keymap.set('n', '<leader>cp', ':cprevious<cr>', { desc = "Previous quickfix" })
vim.keymap.set('n', '<leader>co', ':copen<cr>', { desc = "Open quickfix" })
vim.keymap.set('n', '<leader>cc', ':cclose<cr>', { desc = "Close quickfix" })

-- Reload configuration (for simple changes only - restart for plugins)
vim.keymap.set('n', '<leader>rr', function()
    -- Clear lua module cache
    for name, _ in pairs(package.loaded) do
        if name:match('^core') or name:match('^utils') or name:match('^verilog') then
            package.loaded[name] = nil
        end
    end
    -- Reload config
    dofile(vim.env.MYVIMRC)
    vim.notify("Config reloaded! (Restart for plugin changes)", vim.log.levels.INFO)
end, { desc = "Reload config" })

-- Easier window resizing
vim.keymap.set('n', '<C-w>+', ':resize +5<cr>', { desc = "Increase window height" })
vim.keymap.set('n', '<C-w>-', ':resize -5<cr>', { desc = "Decrease window height" })
vim.keymap.set('n', '<C-w>>', ':vertical resize +5<cr>', { desc = "Increase window width" })
vim.keymap.set('n', '<C-w><', ':vertical resize -5<cr>', { desc = "Decrease window width" })
