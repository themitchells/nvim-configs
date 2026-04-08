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
            globalstatus = false,
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
                    colored = true,
                    diff_color = {
                        added    = 'LualineDiffAdd',
                        modified = 'LualineDiffChange',
                        removed  = 'LualineDiffDelete',
                    },
                    -- Use buffer-local gitsigns data so switching buffers never
                    -- shows the previous buffer's diff stats while gitsigns refreshes.
                    source = function()
                        local gs = vim.b.gitsigns_status_dict
                        if not gs then return nil end
                        return {
                            added    = gs.added,
                            modified = gs.changed,
                            removed  = gs.removed,
                        }
                    end,
                },
                {
                    -- Staged changes indicator — shown when there are staged hunks.
                    -- Reads gitsigns' internal hunks_staged cache (populated from git diff --cached).
                    function()
                        local ok, cache = pcall(require, 'gitsigns.cache')
                        if not ok then return '' end
                        local bcache = cache.cache[vim.api.nvim_get_current_buf()]
                        if not bcache or not bcache.hunks_staged or #bcache.hunks_staged == 0 then
                            return ''
                        end
                        local added, removed = 0, 0
                        for _, h in ipairs(bcache.hunks_staged) do
                            added   = added   + (h.added   and h.added.count   or 0)
                            removed = removed + (h.removed and h.removed.count or 0)
                        end
                        local parts = {}
                        if added   > 0 then parts[#parts+1] = '+' .. added   end
                        if removed > 0 then parts[#parts+1] = '-' .. removed end
                        return '[S:' .. table.concat(parts, ' ') .. ']'
                    end,
                    color = 'DiagnosticInfo',
                    padding = { left = 1, right = 0 },
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
                    -- Directory portion of path (not bold)
                    function()
                        local full = vim.fn.expand('%:~:.')
                        local dir  = vim.fn.fnamemodify(full, ':h')
                        if dir == '.' then return '' end
                        return dir .. '/'
                    end,
                    padding = { left = 1, right = 0 },
                    color = function()
                        return vim.bo.modified and 'LualineFilenameModified' or 'LualineFilenameNormal'
                    end,
                },
                {
                    -- Filename (bold)
                    function()
                        local file     = vim.fn.fnamemodify(vim.fn.expand('%:~:.'), ':t')
                        local modified = vim.bo.modified and '[+]' or ''
                        if file == '' then return '[No Name]' end
                        return file .. modified
                    end,
                    padding = { left = 0, right = 0 },
                    color = function()
                        return vim.bo.modified and 'LualineFilenameModifiedBold' or 'LualineFilenameNormalBold'
                    end,
                },
                {
                    -- [RO] indicator (not bold)
                    function()
                        if vim.bo.readonly then return '[RO]' end
                        if not vim.bo.modifiable then return '[-]' end
                        return ''
                    end,
                    padding = { left = 0, right = 1 },
                    color = function()
                        return vim.bo.modified and 'LualineFilenameModified' or 'LualineFilenameNormal'
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
                    function() return tostring(vim.fn.line('.')) end,
                    padding = { left = 1, right = 0 },
                    color = { gui = 'bold' },
                },
                {
                    function() return string.format('/%d', vim.fn.line('$')) end,
                    padding = { left = 0, right = 0 },
                },
                {
                    function() return string.format('|%d', vim.fn.col('.')) end,
                    padding = { left = 0, right = 1 },
                    color = { gui = 'bold' },
                },
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
