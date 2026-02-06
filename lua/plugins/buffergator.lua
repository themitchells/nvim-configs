-- Buffergator - Sidebar buffer list
-- Custom fork with modifications

return {
    "jerias/vim-buffergator",  -- Your custom fork
    keys = {
        { "<leader>b", "<cmd>BuffergatorToggle<cr>", desc = "Toggle Buffergator" },
        { "<F3>", "<cmd>BuffergatorToggle<cr>", desc = "Toggle Buffergator" },
    },
    config = function()
        -- Buffergator configuration
        vim.g.buffergator_viewport_split_policy = "L"  -- Open on left side
        vim.g.buffergator_split_size = 30              -- Width of vertical split
        vim.g.buffergator_sort_regime = "mru"          -- Most recently used first
        vim.g.buffergator_show_full_directory_path = 0 -- Show relative paths
        vim.g.buffergator_suppress_keymaps = 0         -- Use default keymaps
    end,
}
