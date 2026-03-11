-- Session Management
-- Migrated from ~/.vim/vimrcs/extended.vim

local M = {}

M.session_loaded = false
M.session_name = ""

-- Helper to get session directory using XDG state path
local function get_session_dir()
    local session_dir = vim.fn.stdpath("state") .. "/sessions"
    vim.fn.mkdir(session_dir, "p")
    return session_dir
end

-- Get session name from servername (matches original Vim behavior)
local function get_server_session_name()
    local servername = vim.v.servername
    if servername ~= "" and servername ~= "GVIM" then
        local session_name
        -- If servername is a full path (starts with /), extract just the filename without extension
        -- This handles socket paths like /run/user/5556/nvim.12345.0 → nvim.12345
        if servername:match("^/") then
            -- Use fnamemodify equivalent: get tail (:t) and remove extension (:r)
            session_name = vim.fn.fnamemodify(servername, ":t:r")
        else
            -- Use servername as-is (for named servers like --listen ./mysession)
            session_name = servername
        end
        return vim.fn.tolower(get_session_dir() .. "/" .. session_name)
    end
    return nil
end

-- Load session
function M.load_session()
    print("Loading Session...")
    if M.session_name == "" then
        print("No session name set")
        M.get_session_name()
    end

    if M.session_name == "" then
        print("Session name still empty, aborting")
        return
    end

    if vim.fn.filereadable(M.session_name) == 1 then
        vim.cmd("source " .. M.session_name)
        M.session_loaded = true
        print("Loaded session: " .. M.session_name)
    else
        print("Session file not found: " .. M.session_name)
    end
end

-- Save session
function M.save_session()
    print("Saving Session...")
    if M.session_name == "" then
        print("No session name set")
        M.get_session_name()
    end

    if M.session_name == "" then
        print("Session name still empty, aborting")
        return
    end

    -- Ensure session directory exists before saving
    local session_dir = vim.fn.fnamemodify(M.session_name, ":h")
    vim.fn.mkdir(session_dir, "p")

    -- Close the buffergator sidebar before saving: it's a scratch buffer that
    -- can't be restored, leaving a stray [No Name] window on session load.
    local bg_ok, bg_view = pcall(require, "nvim-buffergator.view")
    local bg_was_open = bg_ok and bg_view.is_open()
    if bg_was_open then bg_view.close() end

    vim.cmd("mksession! " .. M.session_name)
    print("Saved session: " .. M.session_name)

    if bg_was_open then bg_view.open() end
end

-- Get session name from user
function M.get_session_name()
    M.session_name = vim.fn.input('Enter Session Name: ')
    if M.session_name ~= "" then
        M.session_name = get_session_dir() .. "/" .. M.session_name
        print("Session is: " .. M.session_name)
    end
end

-- Auto-save on close
function M.save_session_on_close()
    if M.session_name == "" then
        M.session_name = get_session_dir() .. "/lastsession"
    end
    M.save_session()
end

-- Auto-load based on servername (matches original Vim behavior)
function M.load_session_servername()
    local session = get_server_session_name()
    if session then
        -- ALWAYS set session name (even if file doesn't exist yet)
        M.session_name = session
        -- Only load if session file exists
        if vim.fn.filereadable(session) == 1 then
            M.load_session()
        end
    end
end

-- Session keymaps
vim.keymap.set('n', '<F10>', function()
    require('sessions.manager').get_session_name()
end, { desc = "Set session name" })

vim.keymap.set('n', '<F11>', function()
    require('sessions.manager').load_session()
end, { desc = "Load session" })

vim.keymap.set('n', '<F12>', function()
    require('sessions.manager').save_session()
end, { desc = "Save session" })

-- User commands for easier access
vim.api.nvim_create_user_command('SaveSession', function()
    require('sessions.manager').save_session()
end, { desc = "Save current session" })

vim.api.nvim_create_user_command('LoadSession', function()
    require('sessions.manager').load_session()
end, { desc = "Load a session" })

vim.api.nvim_create_user_command('SessionName', function()
    require('sessions.manager').get_session_name()
end, { desc = "Set session name" })

return M
