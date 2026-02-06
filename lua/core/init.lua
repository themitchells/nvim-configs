-- Core Module Loader
-- Loads all core configuration modules in order

require("core.options")
require("core.keymaps")
require("core.autocmds")

-- Load utility modules that define user commands
require("utils.buffer")    -- Provides :Bd and :Bclose commands
require("sessions.manager") -- Provides :SaveSession, :LoadSession, :SessionName commands
