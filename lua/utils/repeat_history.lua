-- Repeat history — extends '.' with a manual multi-slot history.
--
-- Capture:
--   Auto-captured on exit from any editing mode back to normal.
--   The source mode is stored so replay uses the same mode (insert vs replace).
--   x, dd and pure-normal-mode edits don't update getreg('.') at all —
--   use <leader>rs to explicitly save those after the fact.
--
-- Replay:
--   Insert mode  (<M-1>–<M-9>): types slot text in the original mode, exits.
--                                Use AFTER your own motion (cw, s, ci", …).
--   Normal mode  (<leader>1–9): same, starting from normal mode.
--   <leader>rp : picker
--   <leader>rs : force-save current '.' register to slot [1]

local M = {}

local history   = {}
local MAX       = 9
local in_replay = false

-- ── Capture ───────────────────────────────────────────────────────────────────

local function save_text(text, from_mode)
    if text == '' then return end
    for i, item in ipairs(history) do
        if item.text == text and item.mode == from_mode then
            table.remove(history, i); break
        end
    end
    table.insert(history, 1, {
        text    = text,
        mode    = from_mode,
        display = string.format('(%s) %s', from_mode, text:sub(1, 55):gsub('\n', '↵')),
    })
    while #history > MAX do table.remove(history) end
end

local function capture(from_mode)
    if in_replay then
        in_replay = false
        return
    end
    save_text(vim.fn.getreg('.'), from_mode)
end

local g = vim.api.nvim_create_augroup('RepeatHistory', { clear = true })

-- Single handler for all editing-mode → normal transitions.
-- InsertLeave also fires on replace-mode exit, so use ModeChanged exclusively
-- to avoid duplicate captures.
vim.api.nvim_create_autocmd('ModeChanged', {
    group    = g,
    pattern  = { '*:n', '*:N' },
    callback = function()
        local old = vim.v.event.old_mode
        if old:sub(1, 1) == 'R' then
            capture('R')
        elseif old:sub(1, 1) == 'i' then
            capture('i')
        end
        -- other modes (v, V, etc.) are ignored
    end,
})

function M.save()
    local text = vim.fn.getreg('.')
    if text == '' then
        vim.notify('repeat_history: . register is empty', vim.log.levels.WARN)
        return
    end
    -- Guess mode from context — user triggered this manually so default to 'i'
    save_text(text, 'i')
    vim.notify(string.format('repeat_history [1]: %s', history[1].display), vim.log.levels.INFO)
end

-- ── Replay ────────────────────────────────────────────────────────────────────

function M.replay(n)
    local item = history[n]
    if not item then
        vim.notify('repeat_history: no entry at slot ' .. n, vim.log.levels.WARN)
        return
    end

    in_replay  = true
    local esc  = vim.api.nvim_replace_termcodes('<Esc>', true, false, true)
    local text = vim.api.nvim_replace_termcodes(item.text, true, false, true)

    -- Use the same mode the edit was originally made in.
    local start_key
    if item.mode == 'R' then
        start_key = 'R'   -- overwrite / replace mode
    else
        start_key = 'i'   -- insert mode
    end

    local cur_mode = vim.fn.mode()
    if cur_mode:find('i') or cur_mode:find('R') then
        -- Already in an editing mode — just feed the text and exit.
        -- (The caller has already set up the change context via their motion.)
        vim.api.nvim_feedkeys(text .. esc, 'i', true)
    else
        -- Normal mode — enter the appropriate editing mode, replay, exit.
        local keys = vim.api.nvim_replace_termcodes(start_key, true, false, true)
                   .. text .. esc
        vim.api.nvim_feedkeys(keys, 'n', false)
    end
end

-- ── Picker ────────────────────────────────────────────────────────────────────

function M.pick()
    if #history == 0 then
        vim.notify('repeat_history: history is empty', vim.log.levels.INFO)
        return
    end
    local items = {}
    for i, item in ipairs(history) do
        items[#items + 1] = { n = i, display = string.format('[%d] %s', i, item.display) }
    end
    vim.ui.select(items, {
        prompt      = 'Repeat history:',
        format_item = function(item) return item.display end,
    }, function(choice)
        if choice then M.replay(choice.n) end
    end)
end

return M
