-- nvim-tree.lua Configuration
-- Replaces NERDTree

return {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
        -- Match NERDTree-like behavior
        view = {
            -- Dynamic width: size to content, bounded by min/max.
            width = {
                min = 30,
                max = 60,
                padding = 1,
            },
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
        -- Follow the active buffer: highlight it in the tree and re-root the
        -- tree at the buffer's directory instead of always sitting at the cwd.
        update_focused_file = {
            enable = true,
            update_root = true,
        },
    },
}
