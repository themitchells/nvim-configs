-- Keymaps
-- Single source of truth for all keybindings.
-- Returns sections table used by lua/utils/help.lua to generate the help window.
--
-- EXCEPTIONS (defined elsewhere for technical reasons):
--   LSP keymaps     → lua/plugins/lsp.lua     (buffer-local, must be set on LspAttach)
--   Session keymaps → lua/sessions/manager.lua (F10/F11/F12, set by session plugin)
--
-- Entry format: { mode, lhs, rhs, desc }
--           or: { mode, lhs, rhs, desc, { extra_opts } }

local sections = {

    { name = "Search", maps = {
        { "n", "<Space>",       "/",                    "Search forward" },
        { "n", "<C-Space>",     "?",                    "Search backward" },
        { "n", "<leader><CR>",  ":noh<CR>",             "Clear search highlight",   { silent = true } },
        { "n", "*",             "/<C-r><C-w><CR>",      "Search word under cursor (no word boundaries)" },
        { "n", "#",             "?<C-r><C-w><CR>",      "Search word under cursor backward (no word boundaries)" },
    }},

    { name = "File Navigation", maps = {
        { "n", "<F4>",         "<cmd>NvimTreeToggle<CR>",   "Toggle file explorer" },
        { "n", "<leader>nn",   "<cmd>NvimTreeToggle<CR>",   "Toggle file explorer" },
        { "n", "<leader>nf",   "<cmd>NvimTreeFindFile<CR>", "Find current file in tree" },
        { "n", "<leader>nc",   "<cmd>NvimTreeCollapse<CR>", "Collapse tree" },
        { "n", "<F3>",         "<cmd>BuffergatorToggle<CR>","Toggle buffer sidebar" },
        { "n", "<leader>bb",   "<cmd>BuffergatorToggle<CR>","Toggle buffer sidebar" },
        { "n", "<S-Tab>",      "<C-W>w",                    "Cycle windows" },
        { "n", "<C-w>+",       ":resize +5<CR>",            "Increase window height" },
        { "n", "<C-w>-",       ":resize -5<CR>",            "Decrease window height" },
        { "n", "<C-w>>",       ":vertical resize +5<CR>",   "Increase window width" },
        { "n", "<C-w><",       ":vertical resize -5<CR>",   "Decrease window width" },
    }},

    { name = "Telescope", maps = {
        { "n", "<leader>ff",   "<cmd>Telescope find_files<CR>",  "Find files" },
        { "n", "<leader>fg",   "<cmd>Telescope live_grep<CR>",   "Live grep" },
        { "n", "<leader>fs",   "<cmd>Telescope grep_string<CR>", "Grep word under cursor" },
        { "n", "<leader>fb",   "<cmd>Telescope buffers<CR>",     "Find buffers" },
        { "n", "<leader>fo",   "<cmd>Telescope oldfiles<CR>",    "Recent files" },
        { "n", "<leader>fh",   "<cmd>Telescope help_tags<CR>",   "Help tags" },
        { "n", "<leader>fc",   "<cmd>Telescope commands<CR>",    "Commands" },
        { "n", "<leader>fk",   "<cmd>Telescope keymaps<CR>",     "Keymaps" },
        { "n", "<leader>fr",   "<cmd>Telescope resume<CR>",      "Resume last search" },
    }},

    { name = "Buffer Management", maps = {
        { "n", "<leader>bd",   ':lua require("utils.buffer").buf_close()<CR>', "Close buffer" },
        { "n", "<leader>bn",   ":bnext<CR>",     "Next buffer" },
        { "n", "<leader>bp",   ":bprevious<CR>", "Previous buffer" },
        { "n", "<leader>bf",   ":bfirst<CR>",    "First buffer" },
        { "n", "<leader>bl",   ":blast<CR>",     "Last buffer" },
    }},

    { name = "Tabs", maps = {
        { "n", "<leader>tn",   ":tabnew<CR>",   "New tab" },
        { "n", "<leader>to",   ":tabonly<CR>",  "Close other tabs" },
        { "n", "<leader>tc",   ":tabclose<CR>", "Close tab" },
        { "n", "<leader>tm",   ":tabmove ",     "Move tab" },
    }},

    { name = "Quickfix", maps = {
        { "n", "<leader>cn",   ":cnext<CR>",     "Next quickfix" },
        { "n", "<leader>cp",   ":cprevious<CR>", "Previous quickfix" },
        { "n", "<leader>co",   ":copen<CR>",     "Open quickfix" },
        { "n", "<leader>cc",   ":cclose<CR>",    "Close quickfix" },
    }},

    { name = "Git", maps = {
        { "n", "<F5>",         ':lua require("utils.helpers").git_diff()<CR>',               "Git diff current file" },
        { "n", "<F6>",         function() require('gitsigns').toggle_word_diff() end,        "Toggle word diff" },
        { "n", "]c",           function() require('gitsigns').next_hunk() end,               "Next git hunk" },
        { "n", "[c",           function() require('gitsigns').prev_hunk() end,               "Previous git hunk" },
        { "n", "<leader>hs",   function() require('gitsigns').stage_hunk() end,              "Stage hunk" },
        { "n", "<leader>hu",   function() require('gitsigns').undo_stage_hunk() end,         "Undo stage hunk" },
        { "n", "<leader>hr",   function() require('gitsigns').reset_hunk() end,              "Reset hunk" },
        { "n", "<leader>hp",   function() require('gitsigns').preview_hunk() end,            "Preview hunk" },
        { "n", "<leader>hb",   function() require('gitsigns').blame_line({ full = true }) end, "Blame line (popup)" },
    }},

    { name = "UI Toggles", maps = {
        { "n", "<F2>",         ":set wrap!<CR>",                                                     "Toggle line wrap" },
        { "n", "<leader>ui",   "<cmd>IBLToggle<CR>",                                                 "Toggle indent lines" },
        { "n", "<leader>ub",   function() require('gitsigns').toggle_current_line_blame() end,       "Toggle git blame" },
        { "n", "<leader>uc",   function() require('treesitter-context').toggle() end,                "Toggle context header" },
        { "n", "<leader>ud",   function() vim.diagnostic.enable(not vim.diagnostic.is_enabled()) end,"Toggle diagnostics" },
        { "n", "<leader>un",   function() vim.wo.relativenumber = not vim.wo.relativenumber end,     "Toggle relative numbers" },
        { "n", "<leader>us",   function() vim.wo.spell = not vim.wo.spell end,                       "Toggle spell check" },
    }},

    { name = "Verilog", maps = {
        { "n", "<F8>", function()
            local ok, fmt = pcall(require, 'verilog.format')
            if ok then fmt.format_to_instance()
            else vim.notify("Failed to load verilog.format", vim.log.levels.ERROR) end
        end, "Format Verilog instance" },
        { "n", "<F9>", function()
            local ok, fmt = pcall(require, 'verilog.format')
            if ok then fmt.format_to_instance_line()
            else vim.notify("Failed to load verilog.format", vim.log.levels.ERROR) end
        end, "Format Verilog line" },
        { "n", "<leader>vg", function() require('verilog.format').goto_instance_start() end,
            "Goto Verilog instance start", { silent = true } },
        { "n", "<leader>u",  function() require('verilog.format').goto_instance_start() end,
            "Goto Verilog instance start", { silent = true } },
    }},

    { name = "Navigation", maps = {
        -- [C uppercase avoids conflict with [c (git prev hunk)
        { "n", "[C",   function() require('treesitter-context').go_to_context() end, "Jump to scope start", { silent = true } },
    }},

    { name = "Editing", maps = {
        { "n", "<F7>",         ":!chmod a+x %<CR>",                      "Make file executable" },
        { "n", "<C-p>",        '"_cw<C-r>0<Esc>',                        "Paste over word",           { silent = true } },
        { "v", "<C-p>",        '"_c<C-r>0<Esc>',                         "Paste over selection",      { silent = true } },
        { "n", "<C-q>",        "@q",                                      "Run macro @q" },
        { "n", "<Leader>m",    "mmHmt:%s/<C-V><CR>//ge<CR>'tzt'm",        "Remove Windows ^M" },
        { "n", "<leader>p",    '"+p',                                     "Paste from system clipboard" },
        { "v", "<leader>y",    '"+y',                                     "Copy to system clipboard" },
        { "x", "p",            "<cmd>call setreg(v:register, getreg(v:register), 'v')<cr>p", "Paste as characterwise (no leading newline)", { silent = true } },
        { "v", "<leader>si",   ':lua require("utils.helpers").incr()<CR>',"Auto increment numbers" },
        { "n", "<leader>rr",   function()
            for name, _ in pairs(package.loaded) do
                if name:match('^core') or name:match('^utils') or name:match('^verilog') then
                    package.loaded[name] = nil
                end
            end
            dofile(vim.env.MYVIMRC)
            vim.notify("Config reloaded! (Restart for plugin changes)", vim.log.levels.INFO)
        end, "Reload config" },
    }},

    { name = "Command Mode", maps = {
        { "c", "$h",    "e ~/",           "Edit home directory" },
        { "c", "$d",    "e ~/Desktop/",   "Edit Desktop directory" },
        { "c", "$j",    "e ./",           "Edit current directory" },
        { "c", "$c",    "e <C-\\>eCurrentFileDir('e')<CR>", "Edit current file directory" },
        { "c", "$q",    "<C-\\>eDeleteTillSlash()<CR>",      "Delete back to last slash" },
        { "c", "<C-A>", "<Home>",  "Beginning of line" },
        { "c", "<C-E>", "<End>",   "End of line" },
        { "c", "<C-K>", "<C-U>",   "Delete to end of line" },
        { "c", "<C-P>", "<Up>",    "Previous command" },
        { "c", "<C-N>", "<Down>",  "Next command" },
    }},

    { name = "Help", maps = {
        { "n", "<leader>?", function() require('utils.help').show_help() end, "Show keybindings help" },
    }},

}

-- Register all keymaps
for _, section in ipairs(sections) do
    for _, map in ipairs(section.maps) do
        local mode, lhs, rhs, desc, extra = map[1], map[2], map[3], map[4], map[5] or {}
        vim.keymap.set(mode, lhs, rhs, vim.tbl_extend('force', { desc = desc }, extra))
    end
end

return { sections = sections }
