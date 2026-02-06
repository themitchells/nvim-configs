-- Plugin Manager Bootstrap and Configuration
-- Using lazy.nvim

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
    vim.fn.system({
        "git", "clone", "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- Plugin specifications
require("lazy").setup({
    -- File explorer (replaces NERDTree)
    { import = "plugins.nvim-tree" },

    -- Status line (replaces vim-airline)
    { import = "plugins.lualine" },

    -- Buffer sidebar (vim-buffergator)
    { import = "plugins.buffergator" },

    -- Git integration (replaces vim-gitgutter)
    { import = "plugins.gitsigns" },

    -- Surround plugin
    { import = "plugins.surround" },

    -- Fuzzy finder (NEW)
    { import = "plugins.telescope" },

    -- Better syntax highlighting (NEW)
    { import = "plugins.treesitter" },

    -- LSP support (NEW)
    { import = "plugins.lsp" },

    -- Keep tabular plugin
    {
        "godlygeek/tabular",
        cmd = "Tabularize",
    },

    -- Verilog/SystemVerilog plugin
    { import = "plugins.verilog" },
}, {
    -- Lazy.nvim configuration
    ui = {
        border = "rounded",
    },
    performance = {
        rtp = {
            disabled_plugins = {
                "gzip",
                "matchit",
                -- "matchparen",  -- Re-enabled for bracket highlighting
                "netrwPlugin",
                "tarPlugin",
                "tohtml",
                "tutor",
                "zipPlugin",
            },
        },
    },
})
