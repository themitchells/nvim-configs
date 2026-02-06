-- gitsigns.nvim Configuration
-- Replaces vim-gitgutter

return {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    keys = {
        { "<F6>", function() require('gitsigns').toggle_word_diff() end, desc = "Toggle word diff" },
        { "]c", function() require('gitsigns').next_hunk() end, desc = "Next git hunk" },
        { "[c", function() require('gitsigns').prev_hunk() end, desc = "Previous git hunk" },
        { "<leader>hs", function() require('gitsigns').stage_hunk() end, desc = "Stage hunk" },
        { "<leader>hu", function() require('gitsigns').undo_stage_hunk() end, desc = "Undo stage hunk" },
        { "<leader>hr", function() require('gitsigns').reset_hunk() end, desc = "Reset hunk" },
        { "<leader>hp", function() require('gitsigns').preview_hunk() end, desc = "Preview hunk" },
        { "<leader>hb", function() require('gitsigns').blame_line({full=true}) end, desc = "Blame line" },
    },
    opts = {
        signs = {
            add          = { text = '+' },
            change       = { text = '~' },
            delete       = { text = '_' },
            topdelete    = { text = '‾' },
            changedelete = { text = '~' },
            untracked    = { text = '┆' },
        },
        signcolumn = true,
        numhl      = false,
        linehl     = false,
        word_diff  = false,
        watch_gitdir = {
            interval = 1000,
            follow_files = true
        },
        attach_to_untracked = true,
        current_line_blame = false,
        current_line_blame_opts = {
            virt_text = true,
            virt_text_pos = 'eol',
            delay = 1000,
            ignore_whitespace = false,
        },
        sign_priority = 6,
        update_debounce = 100,
        status_formatter = nil,
        max_file_length = 40000,
        preview_config = {
            border = 'single',
            style = 'minimal',
            relative = 'cursor',
            row = 0,
            col = 1
        },
    },
}
