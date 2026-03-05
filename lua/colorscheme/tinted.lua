-- Tinted Theming Integration
-- Migrated from ~/.vim/vimrcs/plugins_config.vim

local M = {}

-- Source the VimScript colorscheme file
local function load_tinted_colorscheme()
    local tinted_file = vim.fn.expand("~/.local/share/tinted-theming/tinty/artifacts/tinted-vim-colors-file.vim")
    if vim.fn.filereadable(tinted_file) == 1 then
        vim.cmd("source " .. tinted_file)
        return true
    else
        -- Fallback to a default colorscheme if tinted not available
        vim.cmd("colorscheme default")
        return false
    end
end

-- Custom highlight overrides
function M.customize_highlights()
    -- Get colors from VimScript globals (set by tinted-vim)
    local colors = {
        gui00 = vim.g.base16_gui00 or vim.g.tinted_gui00,
        gui01 = vim.g.base16_gui01 or vim.g.tinted_gui01,
        gui02 = vim.g.base16_gui02 or vim.g.tinted_gui02,
        gui04 = vim.g.base16_gui04 or vim.g.tinted_gui04,
        gui08 = vim.g.base16_gui08 or vim.g.tinted_gui08,
        gui09 = vim.g.base16_gui09 or vim.g.tinted_gui09,
        gui0A = vim.g.base16_gui0A or vim.g.tinted_gui0A,
        gui0B = vim.g.base16_gui0B or vim.g.tinted_gui0B,
        gui0D = vim.g.base16_gui0D or vim.g.tinted_gui0D,
        cterm01 = vim.g.base16_cterm01 or vim.g.tinted_cterm01 or "18",
        cterm04 = vim.g.base16_cterm04 or vim.g.tinted_cterm04 or "20",
        cterm0A = vim.g.base16_cterm0A or vim.g.tinted_cterm0A or "11",
        cterm0B = vim.g.base16_cterm0B or vim.g.tinted_cterm0B or "10",
    }

    -- Helper function to ensure color has # prefix
    local function ensure_hash(color)
        if color and not color:match("^#") and color:match("^%x+$") then
            return "#" .. color
        end
        return color
    end

    -- Helper to darken a hex color by a factor (e.g. 0.8 = 80% brightness)
    local function darken(color, factor)
        local c = ensure_hash(color)
        if not c then return c end
        local r = math.floor(tonumber(c:sub(2, 3), 16) * factor)
        local g = math.floor(tonumber(c:sub(4, 5), 16) * factor)
        local b = math.floor(tonumber(c:sub(6, 7), 16) * factor)
        return string.format('#%02x%02x%02x', r, g, b)
    end

    -- Apply custom highlights
    if colors.gui0A and colors.gui01 then
        vim.api.nvim_set_hl(0, 'Search', {
            fg = ensure_hash(colors.gui0A),
            bg = ensure_hash(colors.gui01),
            ctermfg = tonumber(colors.cterm0A),
            ctermbg = tonumber(colors.cterm01),
            reverse = true,
        })
    end

    if colors.gui01 and colors.gui08 and colors.gui09 and colors.gui0A and colors.gui0B and colors.gui0D then
        local diff_bg = ensure_hash(colors.gui01)
        vim.api.nvim_set_hl(0, 'LualineDiffAdd',    { fg = ensure_hash(colors.gui0B), bg = diff_bg, bold = true })
        vim.api.nvim_set_hl(0, 'LualineDiffChange', { fg = ensure_hash(colors.gui0A), bg = diff_bg, bold = true })
        vim.api.nvim_set_hl(0, 'LualineDiffDelete', { fg = ensure_hash(colors.gui08), bg = diff_bg, bold = true })
        vim.api.nvim_set_hl(0, 'LualineFilenameNormal',       { fg = '#ffffff', bg = darken(colors.gui0D, 0.8) })
        vim.api.nvim_set_hl(0, 'LualineFilenameNormalBold',   { fg = '#ffffff', bg = darken(colors.gui0D, 0.8), bold = true })
        vim.api.nvim_set_hl(0, 'LualineFilenameModified',     { fg = '#ffffff', bg = ensure_hash(colors.gui09) })
        vim.api.nvim_set_hl(0, 'LualineFilenameModifiedBold', { fg = '#ffffff', bg = ensure_hash(colors.gui09), bold = true })
    end

    vim.api.nvim_set_hl(0, 'MatchParen', {
        fg = '#000000',  -- Black text for contrast
        bg = '#af8700',  -- Amber
        -- bg = '#d7875f',  -- More orange
        -- bg = '#d7af00',  -- Yellow-orange
        bold = true,
        underline = true,
    })

    if colors.gui0B then
        vim.api.nvim_set_hl(0, 'Constant', {
            fg = ensure_hash(colors.gui0B),
            ctermfg = tonumber(colors.cterm0B),
        })
    end

    if colors.gui04 then
        vim.api.nvim_set_hl(0, 'Comment', {
            fg = ensure_hash(colors.gui04),
            ctermfg = tonumber(colors.cterm04),
            italic = true,
        })
    end

    if colors.gui0A and colors.gui01 then
        local split_hl = {
            fg = ensure_hash(colors.gui0A),
            bg = ensure_hash(colors.gui01),
            ctermfg = tonumber(colors.cterm0A),
            ctermbg = tonumber(colors.cterm01),
        }
        vim.api.nvim_set_hl(0, 'VertSplit', split_hl)
        vim.api.nvim_set_hl(0, 'WinSeparator', split_hl)
    end

    -- Custom color columns (from original config)
    vim.api.nvim_set_hl(0, 'ColorColumn', {
        bg = '#072632',
        ctermbg = 23,
    })
end

-- Initialize colorscheme
function M.setup()
    -- Enable true color support
    if vim.fn.has('termguicolors') == 1 then
        vim.opt.termguicolors = true
    end

    -- Set colorspace
    vim.g.tinted_colorspace = 256

    -- Load the colorscheme
    if load_tinted_colorscheme() then
        -- Apply customizations
        M.customize_highlights()
    end
end

return M
