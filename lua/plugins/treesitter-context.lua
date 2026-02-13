-- Treesitter Context Configuration
-- Shows sticky header with current scope (module/function/always block)

return {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
        require("treesitter-context").setup({
            enable = true,
            max_lines = 3,  -- Maximum lines to show in context
            min_window_height = 20,  -- Minimum editor height to show context
            line_numbers = true,
            multiline_threshold = 1,  -- Max lines for single context item
            trim_scope = 'outer',  -- Remove outer scope if it doesn't fit
            mode = 'cursor',  -- Line used to calculate context ('cursor' or 'topline')
            separator = '─',  -- Separator between context and content
            zindex = 20,  -- Z-index of context window
        })

        -- Keybinding to jump to context (go to function/module definition)
        vim.keymap.set("n", "[c", function()
            require("treesitter-context").go_to_context()
        end, { silent = true, desc = "Jump to context (scope start)" })
    end,
}
