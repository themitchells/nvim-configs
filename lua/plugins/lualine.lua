-- lualine.nvim Configuration
-- Replaces vim-airline

return {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    opts = {
        options = {
            theme = "auto", -- Will integrate with tinted-theming
            section_separators = '',
            component_separators = '',
            globalstatus = true,
        },
        sections = {
            lualine_a = {'mode'},
            lualine_b = {
                'branch',
                {
                    'diff',
                    symbols = {
                        added = '+',
                        modified = '~',
                        removed = '-'
                    },
                    colored = true,  -- Use colors for diff
                    diff_color = {
                        added    = { fg = '#5faf5f' },  -- Green
                        modified = { fg = '#d7af5f' },  -- Yellow
                        removed  = { fg = '#df5f5f' },  -- Red
                    },
                },
                {
                    'diagnostics',
                    sources = { 'nvim_lsp' },
                    symbols = {
                        error = 'E:',
                        warn = 'W:',
                        info = 'I:',
                        hint = 'H:',
                    },
                },
            },
            lualine_c = {
                {
                    'filename',
                    path = 0, -- Just filename (like airline short path)
                    shorting_target = 40,
                    symbols = {
                        modified = '[+]',
                        readonly = '[RO]',
                        unnamed = '[No Name]',
                    },
                    color = function()
                        -- Colored background section (like airline) - hardcoded for reliability
                        if vim.bo.modified then
                            -- Orange background when modified (readable)
                            return {
                                fg = '#ffffff',  -- White text
                                bg = '#d7875f',  -- Orange background
                                gui = 'bold'
                            }
                        else
                            -- Blue background when NOT modified
                            return {
                                fg = '#ffffff',  -- White text
                                bg = '#5f87af',  -- Blue background
                                gui = 'bold'
                            }
                        end
                    end,
                },
            },
            lualine_x = {
                {
                    -- Show paste mode indicator
                    function()
                        return require('utils.helpers').has_paste()
                    end,
                },
                {
                    -- Only show encoding if not utf-8[unix]
                    'encoding',
                    cond = function()
                        local enc = vim.opt.encoding:get()
                        local fmt = vim.bo.fileformat
                        return not (enc == 'utf-8' and fmt == 'unix')
                    end,
                },
                {
                    -- Only show fileformat if not unix
                    'fileformat',
                    cond = function()
                        return vim.bo.fileformat ~= 'unix'
                    end,
                },
                'filetype',
            },
            lualine_y = {'progress'},
            lualine_z = {
                {
                    -- Show row/total_rows:column (like airline)
                    function()
                        local line = vim.fn.line('.')
                        local total = vim.fn.line('$')
                        local col = vim.fn.col('.')
                        return string.format('%d/%d:%d', line, total, col)
                    end,
                }
            }
        },
        inactive_sections = {
            lualine_a = {},
            lualine_b = {},
            lualine_c = {{'filename', path = 1}},
            lualine_x = {'location'},
            lualine_y = {},
            lualine_z = {}
        },
    },
}
