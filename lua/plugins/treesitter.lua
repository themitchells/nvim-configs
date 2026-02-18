-- nvim-treesitter Configuration
-- NOTE: nvim-treesitter was fully rewritten in 2025; configs module is gone.
-- See: https://github.com/nvim-treesitter/nvim-treesitter/blob/main/README.md
--
-- DISABLED: Marginal benefit for this workflow.
--   - Primary language (Verilog/SystemVerilog) is excluded; verilog_systemverilog.vim is used instead.
--   - Remaining benefit is modest highlighting/indent improvements for Python, bash, YAML, C, etc.
--   - Textobject keymaps (af/if/]m/etc.) are available but not actively used.
-- To re-enable: change `enabled = false` to `enabled = true` and run :TSInstall for desired parsers.

-- -- Filetypes to enable treesitter highlighting (excludes verilog - use syntax plugin instead)
-- local highlight_filetypes = {
--     "lua", "vim", "python", "bash",
--     "yaml", "json", "toml",
--     "make", "cmake",
--     "c", "cpp",
--     "markdown",
-- }
--
-- -- Filetypes to enable treesitter indentation
-- local indent_filetypes = {
--     "lua", "vim", "python", "bash",
--     "json", "toml",
--     "make", "cmake",
--     "c", "cpp",
--     "markdown",
-- }

return {
    "nvim-treesitter/nvim-treesitter",
    enabled = false,
    build = ":TSUpdate",
    lazy = false,  -- Does not support lazy-loading (new rewrite)
    dependencies = {
        "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
        -- Enable treesitter highlighting per filetype
        vim.api.nvim_create_autocmd("FileType", {
            pattern = highlight_filetypes,
            callback = function() vim.treesitter.start() end,
        })

        -- Enable treesitter indentation per filetype
        vim.api.nvim_create_autocmd("FileType", {
            pattern = indent_filetypes,
            callback = function()
                vim.wo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            end,
        })

        -- Textobjects: configure options
        require("nvim-treesitter-textobjects").setup({
            select = { lookahead = true },
            move  = { set_jumps = true },
        })

        -- Textobjects: select keymaps
        local select = require("nvim-treesitter-textobjects.select")
        local function sel(q) return function() select.select_textobject(q, "textobjects") end end
        vim.keymap.set({ "x", "o" }, "af", sel("@function.outer"), { desc = "outer function" })
        vim.keymap.set({ "x", "o" }, "if", sel("@function.inner"), { desc = "inner function" })
        vim.keymap.set({ "x", "o" }, "ac", sel("@class.outer"),    { desc = "outer class" })
        vim.keymap.set({ "x", "o" }, "ic", sel("@class.inner"),    { desc = "inner class" })

        -- Textobjects: move keymaps
        local move = require("nvim-treesitter-textobjects.move")
        vim.keymap.set("n", "]m",  function() move.goto_next_start("@function.outer",  "textobjects") end, { desc = "next function start" })
        vim.keymap.set("n", "]]",  function() move.goto_next_start("@class.outer",     "textobjects") end, { desc = "next class start" })
        vim.keymap.set("n", "]M",  function() move.goto_next_end("@function.outer",    "textobjects") end, { desc = "next function end" })
        vim.keymap.set("n", "][",  function() move.goto_next_end("@class.outer",       "textobjects") end, { desc = "next class end" })
        vim.keymap.set("n", "[m",  function() move.goto_previous_start("@function.outer", "textobjects") end, { desc = "prev function start" })
        vim.keymap.set("n", "[[",  function() move.goto_previous_start("@class.outer",    "textobjects") end, { desc = "prev class start" })
        vim.keymap.set("n", "[M",  function() move.goto_previous_end("@function.outer",   "textobjects") end, { desc = "prev function end" })
        vim.keymap.set("n", "[]",  function() move.goto_previous_end("@class.outer",      "textobjects") end, { desc = "prev class end" })
    end,
}
