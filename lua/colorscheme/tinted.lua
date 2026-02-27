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
        gui0A = vim.g.base16_gui0A or vim.g.tinted_gui0A,
        gui0B = vim.g.base16_gui0B or vim.g.tinted_gui0B,
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

    if colors.gui0A and colors.gui01 then
        vim.api.nvim_set_hl(0, 'MatchParen', {
            fg = ensure_hash(colors.gui0A),  -- Yellow/orange text
            bg = ensure_hash(colors.gui01),  -- Subtle background
            ctermfg = tonumber(colors.cterm0A),
            ctermbg = tonumber(colors.cterm01),
            bold = true,
            underline = true,  -- Added for better visibility
        })
    end

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
