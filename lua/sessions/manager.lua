-- Session Management
-- Migrated from ~/.vim/vimrcs/extended.vim

local M = {}

M.session_loaded = false
M.session_name = ""

-- Get session name from servername
local function get_server_session_name()
    local servername = vim.v.servername
    if servername ~= "" and servername ~= "GVIM" then
        -- Extract name from socket path
        -- Neovim uses socket paths like /tmp/nvim.user/ABC123/0
        if servername:match("nvim") then
            -- Extract the session ID from the socket path
            local session_id = servername:match("/([^/]+)/[^/]+$") or servername:match("([^/]+)$")
            if session_id then
                servername = session_id
            end
        end
        return vim.fn.tolower(vim.fn.expand("~/.config/nvim/temp_dirs/sessions/") .. servername)
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

    vim.cmd("mksession! " .. M.session_name)
    print("Saved session: " .. M.session_name)
end

-- Get session name from user
function M.get_session_name()
    M.session_name = vim.fn.input('Enter Session Name: ')
    if M.session_name ~= "" then
        M.session_name = vim.fn.expand("~/.config/nvim/temp_dirs/sessions/") .. M.session_name
        print("Session is: " .. M.session_name)
    end
end

-- Auto-save on close
function M.save_session_on_close()
    if M.session_name == "" then
        M.session_name = vim.fn.expand("~/.config/nvim/temp_dirs/sessions/lastsession")
    end
    M.save_session()
end

-- Auto-load based on servername
function M.load_session_servername()
    local session = get_server_session_name()
    if session and vim.fn.filereadable(session) == 1 then
        M.session_name = session
        M.load_session()
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
