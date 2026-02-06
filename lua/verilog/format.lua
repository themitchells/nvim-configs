-- Verilog Formatting Functions
-- Carefully translated from ~/.vim/vimrcs/extended.vim
-- Original VimScript by user, translated to Lua
--
-- Refactored 2026-02-05:
--   - Added CONSTANTS section for magic numbers (columns, indentation)
--   - Extracted helper functions for better code organization:
--     * extract_comment(): Parse comments from lines
--     * pad_to_column(): Handle column alignment
--     * extract_signal_name(): Smart signal name extraction from any Verilog pattern
--     * format_port_connection(): Generate aligned port connection lines
--   - Simplified main function port/parameter logic from 118 lines to ~30 lines
--   - Improved handling of:
--     * Parameters with bit vector widths (parameter [3:0] NAME)
--     * Type parameters (parameter type NAME)
--     * Unpacked arrays (output [7:0] mem [0:15])
--     * SystemVerilog interfaces and structs
--     * Bus delimiters {a, b, c}
--   - Maintains exact output format and alignment (columns 48 and 88)

local M = {}

--------------------------------------------------------------------------------
-- CONSTANTS
--------------------------------------------------------------------------------

local CONSTANTS = {
    PORT_COLUMN = 48,        -- Where (signal) starts after .portname
    COMMENT_COLUMN = 88,     -- Where // comment starts
    BASE_INDENT = "    ",    -- 4 spaces for module/instance
    PORT_INDENT = "        ", -- 8 spaces for port maps
    COMMENT_INDENT = "        " -- 8 spaces for comment lines
}

-- Global module name (mimics vim's g:moduleName)
vim.g.verilog_moduleName = "dummy_inst"

-- Helper function to execute normal mode commands
local function normal(cmd)
    vim.cmd('normal! ' .. cmd)
end

-- Helper function to insert a newline after current line
local function insert_line_below()
    local line = vim.fn.line('.')
    vim.fn.append(line, '')
    normal('j')
end

--------------------------------------------------------------------------------
-- HELPER FUNCTIONS
--------------------------------------------------------------------------------

-- Extract comment from line
-- Returns: comment_text, remainder_line
local function extract_comment(line)
    if line:match("//") then
        local parts = vim.split(line, "//", { plain = true })
        local comment = parts[#parts] or ""
        local remainder = parts[1] or ""
        return comment, remainder
    elseif line:match("/%*") then
        local parts = vim.split(line, "/%*")
        local comment = parts[#parts] or ""
        local remainder = parts[1] or ""
        return comment, remainder
    end
    return "", line
end

-- Pad string to target column
-- If already past target, add single space
local function pad_to_column(str, target)
    if #str < target then
        return str .. string.rep(" ", target - #str)
    else
        return str .. " "
    end
end

-- Extract signal name from a Verilog declaration line
-- Handles all patterns: basic signals, buses, packed arrays, unpacked arrays,
-- interfaces, structs, bus delimiters, synthesis directives, etc.
-- Parameters:
--   line: the line to parse (should have comments removed first)
--   is_parameter: true if this is a parameter line
-- Returns: signal name
local function extract_signal_name(line, is_parameter)
    local work_line = line

    -- Remove synthesis directives: (* ... *)
    work_line = work_line:gsub('%(%*.*%*%)', "")

    -- Special case: bus delimiter {a,b,c}
    -- In Verilog: output wire {a, b, c}, means multiple signals
    -- Extract the entire {a, b, c} expression
    if work_line:match("{") and not is_parameter then
        -- First try: with parentheses (.port({a, b, c}))
        local match = work_line:match(".-%((.*{.*})%).*")
        if match then
            return match
        end
        -- Second try: without parentheses (output wire {a, b, c})
        match = work_line:match("({.-})")
        if match then
            return match
        end
    end

    -- Special case: already formatted .port(signal)
    if work_line:match("^ *%.") then
        local sig = work_line:match("%((.-)%)")
        if sig then
            sig = sig:gsub(",", ""):gsub("%)", "")
            return sig
        end
    end

    -- Standard case: tokenize and extract signal name
    -- Add space before ( to help tokenization
    work_line = work_line:gsub("%(", " %(")
    local tokens = vim.split(work_line, "%s+", { trimempty = true })

    local signal
    if is_parameter then
        -- parameter [type] NAME = value
        -- Find token before = sign
        for i, token in ipairs(tokens) do
            if token:match("=") then
                -- Token before = is the name
                signal = tokens[i - 1]
                break
            end
        end
        -- If no = found, might be in parameter port list
        if not signal or signal == "" then
            -- parameter integer NAME or parameter type NAME
            if work_line:match("integer") or work_line:match("int") or
               work_line:match("string") or work_line:match("type") then
                signal = tokens[3] or ""
            else
                signal = tokens[2] or ""
            end
        end
    else
        -- Port declaration: direction type [width] NAME [unpacked_dims] [,]
        -- Signal name is last token that doesn't start with [
        -- Work backwards to find signal name
        for i = #tokens, 1, -1 do
            local tok = tokens[i]
            -- Clean up
            tok = tok:gsub(",", ""):gsub("%(", ""):gsub("%)", ""):gsub(";", "")
            -- Skip tokens that are only array subscripts
            if not tok:match("^%[") and tok ~= "" then
                signal = tok
                break
            end
        end
        signal = signal or ""
    end

    -- Clean up extracted signal (remove any embedded array subscripts)
    signal = signal:gsub(",", "")      -- Remove trailing comma
    signal = signal:gsub("%(", "")     -- Remove parentheses
    signal = signal:gsub("%)", "")
    signal = signal:gsub(";", "")      -- Remove semicolon

    return signal
end

-- Format a complete port connection line with proper alignment
-- Parameters:
--   port_name: the port name (left side of connection)
--   signal_name: the signal name (right side of connection)
--   comment: comment text (without // prefix)
--   trailing_char: "," or "" for last port
-- Returns: formatted line string
local function format_port_connection(port_name, signal_name, comment, trailing_char)
    local line = CONSTANTS.PORT_INDENT .. "." .. port_name
    line = pad_to_column(line, CONSTANTS.PORT_COLUMN)
    line = line .. "(" .. signal_name .. ")" .. trailing_char

    if comment ~= "" then
        line = pad_to_column(line, CONSTANTS.COMMENT_COLUMN)
        line = line .. "//" .. comment
    end

    return line
end

-- Main formatting function - formats a single line for Verilog instance
function M.format_to_instance_line()
    -- Save wrap setting
    local mywrap = vim.wo.wrap
    vim.wo.wrap = false

    local instCurLine = vim.fn.getline('.')

    -- Get next line
    normal('j')
    local instNextLine = vim.fn.getline('.')
    normal('k')

    -- Pure comment lines
    if instCurLine:match("^ */") then
        -- Comment line - just ensure indentation
        -- Remove leading whitespace and add proper indent
        local trimmed = instCurLine:match("^%s*(.*)$")
        vim.fn.setline('.', CONSTANTS.COMMENT_INDENT .. trimmed)

    -- Blank lines
    elseif instCurLine == "" then
        -- Skip blank lines

    -- Module declaration
    elseif instCurLine:match("^ *module") then
        -- Store module name
        local parts = vim.split(instCurLine, "%s+", { trimempty = true })
        if parts[2] then
            vim.g.verilog_moduleName = parts[2]
            -- Remove any parentheses
            vim.g.verilog_moduleName = vim.g.verilog_moduleName:gsub("#%(", ""):gsub("%(", "")

            vim.fn.setline('.', CONSTANTS.BASE_INDENT .. vim.g.verilog_moduleName)

            if instNextLine:match("^ *%(") then
                insert_line_below()
                vim.fn.setline('.', CONSTANTS.BASE_INDENT .. "u_" .. vim.g.verilog_moduleName)
                normal('k')
            end

            if instCurLine:match("#%( *$") then
                insert_line_below()
                vim.fn.setline('.', CONSTANTS.BASE_INDENT .. "#(")
                normal('k')
            elseif instCurLine:match("%( *$") then
                insert_line_below()
                vim.fn.setline('.', CONSTANTS.BASE_INDENT .. "(")
                normal('k')
            end
        end

    -- Bare word with no "." or ","
    elseif not instCurLine:match(",") and not instCurLine:match("%.") and instCurLine:match("^ *[a-zA-Z0-9_]+ *$") then
        local trimmed = instCurLine:match("^%s*(.-)%s*$")
        vim.fn.setline('.', CONSTANTS.BASE_INDENT .. trimmed)

    -- Just indent stand-alone "#("
    elseif instCurLine:match("^ *#%( *$") then
        local newLine = instCurLine:gsub("^ *", CONSTANTS.BASE_INDENT)
        vim.fn.setline('.', newLine)

    -- Separate "#(" from rest of line
    elseif instCurLine:match("^ *#%(") then
        local newLine = instCurLine:gsub("^ *#%(", "")
        vim.fn.setline('.', newLine)
        normal('k')
        insert_line_below()
        vim.fn.setline('.', "    #(")
        normal('k')

    -- Just indent stand-alone "("
    elseif instCurLine:match("^ *%( *$") then
        local newLine = instCurLine:gsub("^ *", CONSTANTS.BASE_INDENT)
        vim.fn.setline('.', newLine)

    -- Separate "(" from rest of line (not synthesis directive)
    elseif instCurLine:match("^ *%(") and not instCurLine:match('^ *%(%*.*%*%)') then
        local newLine = instCurLine:gsub("^ *%(", "")
        vim.fn.setline('.', newLine)
        normal('k')
        insert_line_below()
        vim.fn.setline('.', "    (")
        normal('k')

    -- Just indent stand-alone ");"
    elseif instCurLine:match("^ *%);") then
        local newLine = instCurLine:gsub("^ *", CONSTANTS.BASE_INDENT)
        vim.fn.setline('.', newLine)

    -- Separate "); from rest of line
    elseif instCurLine:match("%)%; *$") then
        local newLine = instCurLine:gsub("%)%;", "")
        vim.fn.setline('.', newLine)
        insert_line_below()
        vim.fn.setline('.', CONSTANTS.BASE_INDENT .. ");")
        normal('k')
        M.format_to_instance_line()

    -- Closing parenthesis logic
    elseif instCurLine:match("^ *%)") then
        -- Need to check two lines ahead
        normal('jj')
        local instNextNextLine = vim.fn.getline('.')
        normal('kk')

        if instNextNextLine:match("^ *%( *$") then
            -- Just format
            local newLine = instCurLine:gsub("^ *", CONSTANTS.BASE_INDENT)
            vim.fn.setline('.', newLine)
        else
            -- Write module instance name below parameter ")"
            local newLine = instCurLine:gsub("^ *", CONSTANTS.BASE_INDENT)
            vim.fn.setline('.', newLine)
            insert_line_below()
            vim.fn.setline('.', "    u_" .. vim.g.verilog_moduleName)
            normal('k')
            -- Clear after use as instance
            vim.g.verilog_moduleName = "dummy_inst"
        end

    -- Separate ") from rest of line
    elseif instCurLine:match("%) *$") and not instNextLine:match("^ *%)") and not instCurLine:match("%(") then
        local newLine = instCurLine:gsub("%)", "")
        vim.fn.setline('.', newLine)
        insert_line_below()
        vim.fn.setline('.', CONSTANTS.BASE_INDENT .. ")")
        normal('k')
        M.format_to_instance_line()

    -- Bare word module/instance name above open parentheses - do nothing
    elseif instNextLine:match("^ *#%(") or (instNextLine:match("^ *%(") and not instNextLine:match('^ *%(%*.*%*%)')) then
        -- Do nothing

    else
        --------------------------------------------------------------------------------
        -- Parameters and ports - Using helper functions
        --------------------------------------------------------------------------------

        -- Determine if this is a parameter line
        local is_param = instCurLine:match("^ *parameter") ~= nil

        -- Capture trailing comma
        local trailing = ""
        if instCurLine:match(",") then
            trailing = ","
        end

        -- Extract comment and remainder
        local comment, remainder = extract_comment(instCurLine)

        -- Extract signal name
        local signal = extract_signal_name(remainder, is_param)

        -- Determine port name
        local port
        if instCurLine:match("^ *%.") then
            -- Already formatted: .portname (signalname)
            -- Extract port name from the line
            local tokens = vim.split(instCurLine, "%s+", { trimempty = true })
            port = tokens[1] or ""
            port = port:gsub("%.", "")
            port = port:gsub("%[.-%]", "")  -- Remove array subscripts
        else
            -- New formatting: port name = signal name (with arrays stripped)
            port = signal:gsub("%[.-%]", "")
        end

        -- Format and write the line
        local formatted = format_port_connection(port, signal, comment, trailing)
        vim.fn.setline('.', formatted)
    end

    -- Restore previous wrap setting
    if mywrap then
        vim.wo.wrap = true
    end

    -- Fix indentation
    normal('==')
end

-- Format entire instance (calls format_to_instance_line repeatedly)
function M.format_to_instance()
    local winview = vim.fn.winsaveview()
    local curline = ""

    while not curline:match("^ *%);") do
        curline = vim.fn.getline('.')
        M.format_to_instance_line()
        normal('j')
    end

    vim.fn.winrestview(winview)
end

return M
