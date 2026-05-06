-- Repeat history — extends '.' with a manual multi-slot history.
--
-- Capture:
--   Auto-captured on exit from any editing mode back to normal.
--   The complete key sequence is recorded for exact replay (like .).
--   Visual changes store the character extent for positional replay.
--   x, dd and pure-normal-mode edits don't enter insert mode —
--   use <leader>rs to explicitly save those after the fact.
--
-- Replay:
--   Insert mode  (<M-1>–<M-9>): types slot text, exits.
--                                Use AFTER your own motion (cw, s, ci", …).
--   Normal mode  (<leader>1–9): exact replay of the original edit.
--   Visual mode  (<leader>1–9): replaces the visual selection with the text.
--   <leader>rp : picker
--   <leader>rs : force-save current '.' register to slot [1]

local M = {}

local history               = {}
local MAX                   = 9
local in_replay             = false

-- Key recording state
local key_log               = {}
local edit_start_idx        = nil
local prev_unnamed          = vim.fn.getreg('"')
local pending_change_extent = nil  -- for visual changes only

-- Record every user keypress for exact replay.
-- Uses `typed` (2nd arg) to exclude internal Neovim keys (K_SPECIAL sequences).
-- Skipped during replay to avoid capturing our own feedkeys output.
vim.on_key(function(_key, typed)
    if not in_replay and typed and typed ~= '' then
        key_log[#key_log + 1] = typed
        -- Keep bounded
        if #key_log > 500 then
            local offset = 250
            local new = {}
            for i = offset + 1, #key_log do
                new[#new + 1] = key_log[i]
            end
            if edit_start_idx then
                edit_start_idx = edit_start_idx - offset
                if edit_start_idx < 1 then edit_start_idx = nil end
            end
            key_log = new
        end
    end
end)

-- ── Capture ───────────────────────────────────────────────────────────────────

local function save_text(text, from_mode, extent, keys)
    if text == '' then return end
    for i, item in ipairs(history) do
        if item.text == text and item.mode == from_mode then
            table.remove(history, i); break
        end
    end
    local mode_labels = {
        i = 'insert',
        R = 'replace',
        c = extent and string.format('change %d', extent) or 'change',
        n = 'normal',
    }
    local label = mode_labels[from_mode] or from_mode
    table.insert(history, 1, {
        text    = text,
        mode    = from_mode,
        extent  = extent,
        keys    = keys,
        display = string.format('[%s] %s', label, text:sub(1, 50):gsub('\n', '↵')),
    })
    while #history > MAX do table.remove(history) end
end

local function extract_keys()
    if not edit_start_idx or edit_start_idx < 1 or edit_start_idx > #key_log then
        return nil
    end
    local parts = {}
    for i = edit_start_idx, #key_log do
        parts[#parts + 1] = key_log[i]
    end
    edit_start_idx = nil
    return table.concat(parts)
end

local function capture(from_mode, extent, keys)
    if in_replay then
        in_replay = false
        return
    end
    vim.schedule(function()
        save_text(vim.fn.getreg('.'), from_mode, extent, keys)
    end)
end

local g = vim.api.nvim_create_augroup('RepeatHistory', { clear = true })

-- Mark edit start when entering operator-pending mode (c, d, y, etc.).
-- Look back for preceding count digits (e.g. 3cw).
vim.api.nvim_create_autocmd('ModeChanged', {
    group    = g,
    pattern  = { 'n:no*' },
    callback = function()
        local start = #key_log
        while start > 1 and key_log[start - 1]:match('^%d$') do
            start = start - 1
        end
        edit_start_idx = start
    end,
})

-- Mark edit start for direct-to-insert commands (i, a, o, s, S, etc.)
-- and detect visual changes for extent tracking.
vim.api.nvim_create_autocmd('ModeChanged', {
    group    = g,
    pattern  = { '*:i', '*:I' },
    callback = function()
        local old = vim.v.event.old_mode
        local first = old:sub(1, 1)
        local is_visual = first == 'v' or first == 'V' or first:byte() == 22

        if is_visual then
            -- Visual change: track extent from unnamed register
            local cur_unnamed = vim.fn.getreg('"')
            if cur_unnamed ~= prev_unnamed
               and cur_unnamed ~= ''
               and not cur_unnamed:find('\n') then
                pending_change_extent = vim.fn.strchars(cur_unnamed)
            else
                pending_change_extent = nil
            end
            -- Don't record keys for visual edits (motion is context-dependent)
            edit_start_idx = nil
        elseif not edit_start_idx then
            -- No operator-pending start was recorded — this is a direct insert
            -- command (i, a, o, s, S, C, etc.). The triggering key is the last
            -- entry in key_log.
            local start = #key_log
            while start > 1 and key_log[start - 1]:match('^%d$') do
                start = start - 1
            end
            edit_start_idx = start
            pending_change_extent = nil
        end
    end,
})

-- Capture on all editing-mode → normal transitions.
vim.api.nvim_create_autocmd('ModeChanged', {
    group    = g,
    pattern  = { '*:n', '*:N' },
    callback = function()
        local old = vim.v.event.old_mode
        local first = old:sub(1, 1)

        if first == 'R' then
            local keys = extract_keys()
            pending_change_extent = nil
            capture('R', nil, keys)
        elseif first == 'i' then
            local ext = pending_change_extent
            pending_change_extent = nil
            local keys = extract_keys()
            if ext then
                capture('c', ext, nil)   -- visual change: use extent, no keys
            elseif keys then
                capture('c', nil, keys)  -- operator/direct change: use keys
            else
                capture('i', nil, nil)   -- plain insert (shouldn't normally happen)
            end
        elseif first == 'v' or first == 'V' or first:byte() == 22 then
            pending_change_extent = nil
            edit_start_idx = nil
            capture('n')
        end

        prev_unnamed = vim.fn.getreg('"')
    end,
})

function M.save()
    local text = vim.fn.getreg('.')
    if text == '' then
        vim.notify('repeat_history: . register is empty', vim.log.levels.WARN)
        return
    end
    save_text(text, 'i', nil, nil)
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

    local cur_mode = vim.fn.mode()
    local cur_first = cur_mode:sub(1, 1)

    if cur_first == 'v' or cur_first == 'V' or cur_first:byte() == 22 then
        -- Visual mode — replace selection with stored text.
        local c = vim.api.nvim_replace_termcodes('c', true, false, true)
        vim.api.nvim_feedkeys(c .. text .. esc, 'n', false)
    elseif cur_first == 'i' or cur_mode:find('R') then
        -- Already in editing mode — just type the text and exit.
        vim.api.nvim_feedkeys(text .. esc, 'i', true)
    elseif item.keys then
        -- Exact replay of recorded keystrokes (like .)
        vim.api.nvim_feedkeys(item.keys, 't', true)
    elseif item.extent then
        -- Visual change — substitute same number of characters.
        local keys = tostring(item.extent) .. 's' .. text .. esc
        vim.api.nvim_feedkeys(keys, 'n', false)
    else
        -- Fallback: enter insert, type text, exit.
        local start_key = item.mode == 'R' and 'R' or 'i'
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
