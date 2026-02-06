-- nvim-surround Configuration
-- Replaces vim-surround

return {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    opts = {
        -- Use default keymaps (ys, ds, cs)
        keymaps = {
            insert = "<C-g>s",
            insert_line = "<C-g>S",
            normal = "ys",
            normal_cur = "yss",
            normal_line = "yS",
            normal_cur_line = "ySS",
            visual = "S",
            visual_line = "gS",
            delete = "ds",
            change = "cs",
        },
    },
}
