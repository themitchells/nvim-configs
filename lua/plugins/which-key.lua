-- Which-Key Configuration
-- Shows popup with available keybindings when you pause

return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
        local wk = require("which-key")

        wk.setup({
            preset = "modern",
            delay = 500,  -- Delay before showing popup (ms)
            icons = {
                breadcrumb = "»",
                separator = "➜",
                group = "+",
            },
            win = {
                border = "rounded",
                padding = { 1, 2 },
            },
        })

        -- Register key groups with descriptions
        wk.add({
            { "<leader>b", group = "Buffers" },
            { "<leader>c", group = "Quickfix" },
            { "<leader>f", group = "Find (Telescope)" },
            { "<leader>h", group = "Git Hunks" },
            { "<leader>s", group = "Spell/Scratch" },
            { "<leader>t", group = "Tabs" },
            { "<leader>r", group = "Refactor/Reload" },
        })
    end,
}
