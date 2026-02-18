-- Keybindings help window
-- Dynamically generated from lua/core/keymaps.lua

local M = {}

local function generate_lines()
    local sections = require('core.keymaps').sections
    local lines = {}

    lines[#lines + 1] = '# Neovim Keybindings  (leader = ,)'
    lines[#lines + 1] = ''
    lines[#lines + 1] = '_LSP keymaps: see lua/plugins/lsp.lua (buffer-local, set on LspAttach)_'
    lines[#lines + 1] = '_Session keymaps: F10 set name · F11 load · F12 save_'
    lines[#lines + 1] = ''

    for _, section in ipairs(sections) do
        lines[#lines + 1] = '## ' .. section.name
        lines[#lines + 1] = ''
        lines[#lines + 1] = '| Key | Description |'
        lines[#lines + 1] = '|-----|-------------|'
        for _, map in ipairs(section.maps) do
            local lhs  = map[2]:gsub('<leader>', ',')  -- display leader as comma
            local desc = map[4] or ''
            lines[#lines + 1] = '| `' .. lhs .. '` | ' .. desc .. ' |'
        end
        lines[#lines + 1] = ''
    end

    lines[#lines + 1] = '---'
    lines[#lines + 1] = '_Press `q`, `<Esc>`, or `<CR>` to close_'

    return lines
end

function M.show_help()
    local lines = generate_lines()

    local width  = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines   * 0.8)
    local row    = math.floor((vim.o.lines   - height) / 2)
    local col    = math.floor((vim.o.columns - width)  / 2)

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].filetype    = 'markdown'
    vim.bo[buf].modifiable  = false
    vim.bo[buf].bufhidden   = 'wipe'

    local win = vim.api.nvim_open_win(buf, true, {
        relative    = 'editor',
        width       = width,
        height      = height,
        row         = row,
        col         = col,
        style       = 'minimal',
        border      = 'rounded',
        title       = ' Keybindings ',
        title_pos   = 'center',
    })
    vim.wo[win].wrap       = true
    vim.wo[win].linebreak  = true
    vim.wo[win].cursorline = true

    for _, key in ipairs({ 'q', '<Esc>', '<CR>' }) do
        vim.keymap.set('n', key, '<cmd>close<CR>', { buffer = buf, silent = true })
    end
end

return M
