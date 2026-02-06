-- nvim-tree.lua Configuration
-- Replaces NERDTree

return {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
        { "<F4>", "<cmd>NvimTreeToggle<cr>", desc = "Toggle NvimTree" },
        { "<leader>nn", "<cmd>NvimTreeToggle<cr>", desc = "Toggle NvimTree" },
        { "<leader>nf", "<cmd>NvimTreeFindFile<cr>", desc = "Find file in tree" },
        { "<leader>nc", "<cmd>NvimTreeCollapse<cr>", desc = "Collapse tree" },
    },
    opts = {
        -- Match NERDTree-like behavior
        view = {
            width = 30,
            side = "left",
        },
        renderer = {
            group_empty = true,
            highlight_git = true,
            icons = {
                show = {
                    file = true,
                    folder = true,
                    folder_arrow = true,
                    git = true,
                },
            },
        },
        filters = {
            dotfiles = false,
            custom = { "^\\.git$", "node_modules", "\\.cache" },
        },
        actions = {
            open_file = {
                quit_on_open = false,
                window_picker = {
                    enable = true,
                },
            },
        },
        git = {
            enable = true,
            ignore = false,
        },
    },
}
