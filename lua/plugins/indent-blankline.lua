-- Indent Blankline Configuration
-- Shows vertical indent guide lines

return {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
        indent = {
            char = "│",  -- Vertical line character
            tab_char = "│",
        },
        scope = {
            enabled = true,
            show_start = false,  -- Don't underline scope start
            show_end = false,    -- Don't underline scope end
        },
        exclude = {
            filetypes = {
                "help",
                "lazy",
                "mason",
                "notify",
                "toggleterm",
                "lazyterm",
            },
        },
    },
}
