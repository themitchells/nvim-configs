-- telescope.nvim Configuration
-- NEW: Fuzzy finder

return {
    "nvim-telescope/telescope.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        {
            "nvim-telescope/telescope-fzf-native.nvim",
            build = "make",
            cond = function()
                return vim.fn.executable("make") == 1
            end,
        },
    },
    cmd = "Telescope",
    opts = {
        defaults = {
            file_ignore_patterns = {
                "%.o", "%.pyc", "%.git/",
                "node_modules", "%.cache",
                "%.swp", "%.bak",
            },
            layout_config = {
                prompt_position = "top",
                horizontal = {
                    width = 0.9,
                    height = 0.8,
                    preview_width = 0.6,
                },
            },
            sorting_strategy = "ascending",
            -- Note: buffer_previewer_maker commented out - causes errors on fresh install
            -- and is redundant (telescope uses this as default anyway)
            -- buffer_previewer_maker = require("telescope.previewers").buffer_previewer_maker,
            vimgrep_arguments = {
                "rg",
                "--color=never",
                "--no-heading",
                "--with-filename",
                "--line-number",
                "--column",
                "--smart-case",
            },
            mappings = {
                i = {
                    ["<C-j>"] = "move_selection_next",
                    ["<C-k>"] = "move_selection_previous",
                    ["<C-q>"] = "send_to_qflist",
                    ["<C-s>"] = "select_horizontal",
                },
            },
        },
        pickers = {
            find_files = {
                hidden = false,
                -- Auto-detect fd or use telescope defaults
                find_command = vim.fn.executable("fd") == 1 and {
                    "fd",
                    "--type", "f",
                    "--strip-cwd-prefix",
                } or nil,
            },
        },
        extensions = {
            fzf = {
                fuzzy = true,
                override_generic_sorter = true,
                override_file_sorter = true,
                case_mode = "smart_case",
            },
        },
    },
    config = function(_, opts)
        require("telescope").setup(opts)
        -- Load extensions
        pcall(require("telescope").load_extension, "fzf")
    end,
}
