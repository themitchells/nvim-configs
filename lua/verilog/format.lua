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
    PORT_COLUMN    = 48,         -- Where (signal) starts after .portname
    COMMENT_COLUMN = 88,         -- Where // comment starts
    BASE_INDENT    = "    ",     -- 4 spaces for module/instance
    PORT_INDENT    = "        ", -- 8 spaces for port maps
    COMMENT_INDENT = "        "  -- 8 spaces for comment lines
}

-- Global module name (mimics vim's g:moduleName)
vim.g.verilog_moduleName = "dummy_inst"

-- Helper function to execute normal mode commands
local function normal(cmd)
    vim.cmd('normal! ' .. cmd)
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

    -- Normalize: strip whitespace before closing parentheses
    -- (handles re-formatting when signame has trailing space e.g. .port (signame ),)
    work_line = work_line:gsub('%s+%)', ')')

    -- Special case: bus delimiter {a,b,c}
    -- In Verilog: .port({a, b, c}) means bus concatenation
    if work_line:match("{") and not is_parameter then
        -- Scope-limited match: [^%)]*  cannot cross a ) boundary, preventing greedy overshoot
        local match = work_line:match("%(([^%)]*{[^%)]*}[^%)]*)%)")
        if match then
            return match:match("^%s*(.-)%s*$")  -- trim whitespace
        end
        -- Second try: without parentheses (output wire {a, b, c})
        match = work_line:match("({.-})")
        if match then
            return match:match("^%s*(.-)%s*$")
        end
    end

    -- Special case: already formatted .port(signal)
    if work_line:match("^ *%.") then
        local sig = work_line:match("%(([^%)]*)")
        if sig then
            sig = sig:gsub(",", ""):gsub("%)", "")
            sig = sig:match("^%s*(.-)%s*$")  -- trim whitespace
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
        -- If no = found, use last non-array-subscript token (same logic as port branch)
        if not signal or signal == "" then
            for i = #tokens, 1, -1 do
                local tok = tokens[i]:gsub(",",""):gsub(";",""):gsub("%(",""):gsub("%)","")
                if not tok:match("^%[") and tok ~= "" and tok ~= "parameter" then
                    signal = tok
                    break
                end
            end
            signal = signal or ""
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
    -- Save original state to detect if changes were actually made
    local original_line = vim.fn.getline('.')
    local was_modified = vim.bo.modified
    local changenr_before = vim.fn.changenr()

    -- Save wrap setting
    local mywrap = vim.wo.wrap
    vim.wo.wrap = false

    -- Save window view to restore cursor position after processing
    local winview = vim.fn.winsaveview()

    local instCurLine = vim.fn.getline('.')

    -- Get next line
    normal('j')
    local instNextLine = vim.fn.getline('.')
    normal('k')

    -- Pure comment lines
    if instCurLine:match("^ */") then
        -- Comment line - just ensure indentation
        local trimmed = instCurLine:match("^%s*(.*)$")
        vim.fn.setline('.', CONSTANTS.COMMENT_INDENT .. trimmed)

    -- Blank lines
    elseif instCurLine == "" then
        -- Skip blank lines

    -- Preprocessor directives (`ifdef, `ifndef, `else, `endif, etc.)
    elseif instCurLine:match("^ *`") then
        -- Preserve content; indentation handled by ==

    -- Module declaration
    elseif instCurLine:match("^ *module") then
        local parts = vim.split(instCurLine, "%s+", { trimempty = true })
        if parts[2] then
            vim.g.verilog_moduleName = parts[2]
            -- Remove any parentheses
            vim.g.verilog_moduleName = vim.g.verilog_moduleName:gsub("#%(", ""):gsub("%(", "")

            vim.fn.setline('.', CONSTANTS.BASE_INDENT .. vim.g.verilog_moduleName)

            if instNextLine:match("^ *%(") then
                vim.fn.append(vim.fn.line('.'), CONSTANTS.BASE_INDENT .. "u_" .. vim.g.verilog_moduleName)
            end

            if instCurLine:match("#%( *$") then
                vim.fn.append(vim.fn.line('.'), CONSTANTS.BASE_INDENT .. "#(")
            elseif instCurLine:match("%( *$") then
                -- Non-parametric module with paren on same line - insert instance name then "("
                vim.fn.append(vim.fn.line('.'),     CONSTANTS.BASE_INDENT .. "u_" .. vim.g.verilog_moduleName)
                vim.fn.append(vim.fn.line('.') + 1, CONSTANTS.BASE_INDENT .. "(")
                vim.g.verilog_moduleName = "dummy_inst"
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
        vim.fn.append(vim.fn.line('.'), CONSTANTS.BASE_INDENT .. "#(")

    -- Just indent stand-alone "("
    elseif instCurLine:match("^ *%( *$") then
        local newLine = instCurLine:gsub("^ *", CONSTANTS.BASE_INDENT)
        vim.fn.setline('.', newLine)

    -- Separate "(" from rest of line (not synthesis directive)
    elseif instCurLine:match("^ *%(") and not instCurLine:match('^ *%(%*.*%*%)') then
        local newLine = instCurLine:gsub("^ *%(", "")
        vim.fn.setline('.', newLine)
        normal('k')
        vim.fn.append(vim.fn.line('.'), CONSTANTS.BASE_INDENT .. "(")

    -- Just indent stand-alone ");"
    elseif instCurLine:match("^ *%);") then
        local newLine = instCurLine:gsub("^ *", CONSTANTS.BASE_INDENT)
        vim.fn.setline('.', newLine)

    -- Separate "); from rest of line
    elseif instCurLine:match("%)%; *$") then
        local newLine = instCurLine:gsub("%)%;", "")
        vim.fn.setline('.', newLine)
        vim.fn.append(vim.fn.line('.'), CONSTANTS.BASE_INDENT .. ");")
        M.format_to_instance_line()

    -- Split ")(" - parameter list close followed immediately by port list open
    elseif instCurLine:match("^ *%)%( *$") then
        vim.fn.setline('.', CONSTANTS.BASE_INDENT .. ")")
        vim.fn.append(vim.fn.line('.'),     CONSTANTS.BASE_INDENT .. "u_" .. vim.g.verilog_moduleName)
        vim.fn.append(vim.fn.line('.') + 1, CONSTANTS.BASE_INDENT .. "(")
        vim.g.verilog_moduleName = "dummy_inst"

    -- Closing parenthesis logic
    elseif instCurLine:match("^ *%)") then
        -- Check if followed by synthesis/preprocessor block ending in standalone ";"
        -- E.g.  )  /  `ifdef SYN / /* synthesis ... */ / `endif / ;
        local cur_lnum = vim.fn.line('.')
        local scan = cur_lnum + 1
        local semi_lnum = -1
        while scan <= vim.fn.line('$') do
            local scanline = vim.fn.getline(scan)
            if scanline:match("^ *; *$") then
                semi_lnum = scan
                break
            elseif scanline:match("^ *$") or scanline:match("^ *`") or scanline:match("^ */") then
                scan = scan + 1
            else
                break
            end
        end

        if semi_lnum > 0 then
            -- Merge: delete intervening lines and replace ")" with ");"
            -- Use explicit line number (not '.') since delete may reposition cursor
            vim.cmd(tostring(cur_lnum + 1) .. "," .. tostring(semi_lnum) .. "d")
            vim.fn.setline(cur_lnum, CONSTANTS.BASE_INDENT .. ");")
        else
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
                vim.fn.append(vim.fn.line('.'), CONSTANTS.BASE_INDENT .. "u_" .. vim.g.verilog_moduleName)
                -- Clear after use as instance
                vim.g.verilog_moduleName = "dummy_inst"
            end
        end

    -- Separate ") from rest of line
    elseif instCurLine:match("%) *$") and not instNextLine:match("^ *%)") and not instCurLine:match("%(") then
        local newLine = instCurLine:gsub("%)", "")
        vim.fn.setline('.', newLine)
        vim.fn.append(vim.fn.line('.'), CONSTANTS.BASE_INDENT .. ")")
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

    -- Restore window view (cursor position) before re-indenting
    vim.fn.winrestview(winview)

    -- Restore previous wrap setting
    if mywrap then
        vim.wo.wrap = true
    end

    -- Fix indentation
    normal('==')

    -- If nothing actually changed, undo to clear modified flag
    local final_line = vim.fn.getline('.')
    if final_line == original_line and not was_modified then
        -- Undo all changes made by this function
        local changenr_after = vim.fn.changenr()
        if changenr_after > changenr_before then
            vim.cmd('silent! undo ' .. changenr_before)
        end
    end
end

-- Format entire instance (calls format_to_instance_line repeatedly)
function M.format_to_instance()
    vim.g.verilog_moduleName = "dummy_inst"
    local winview = vim.fn.winsaveview()
    local curline = ""

    while not curline:match("^ *%);") do
        curline = vim.fn.getline('.')
        M.format_to_instance_line()
        if vim.fn.getline('.'):match("^ *%);") then
            break
        end
        normal('j')
    end

    vim.fn.winrestview(winview)
end

-- ── Goto Instance Start ───────────────────────────────────────────────────────
-- Scans backward from the cursor, skipping balanced (...) and [...] pairs,
-- to find the module-type line of the enclosing Verilog instance.
-- Ported from verilog_systemverilog.vim s:GetInstanceInfo / GotoInstanceStart.
--
-- Uses a flat single-pass approach: p/b depth tracked inline on every char so
-- multi-line balanced blocks are handled correctly without nested inner loops.
function M.goto_instance_start()
    local start_line = vim.fn.line('.')
    local linenr     = start_line

    -- Detect whether the cursor is on a closing line (first non-ws char is ')').
    -- Only on such lines do we trigger the instance-opener logic when p drops to 0.
    local start_line_text = vim.fn.getline(start_line)
    local at_close_paren  = start_line_text:match('^%s*%)') ~= nil

    -- For the start line, strip trailing ';' and whitespace from col_end so
    -- a ); line doesn't immediately hit give_up.
    local function start_col_end()
        local c = #start_line_text
        while c > 0 do
            local ch = start_line_text:sub(c, c)
            if ch == ';' or ch:match('%s') then c = c - 1 else break end
        end
        return c - 1  -- 0-indexed
    end

    local p          = 0
    local b          = 0
    local ininstdecl = 0
    local ininsttype = 0
    local found_line = nil

    while linenr > 0 do
        local line    = vim.fn.getline(linenr)
        local col_end = (linenr == start_line) and start_col_end() or (#line - 1)

        for col = col_end, 0, -1 do
            local ch = line:sub(col + 1, col + 1)

            -- ── Inside a balanced skip block ──────────────────────────────────
            if p > 0 then
                if ch == ')' then
                    p = p + 1
                elseif ch == '(' then
                    p = p - 1
                    -- When p reaches 0 we exited a balanced block.  Only treat
                    -- this '(' as an instance opener when the cursor started on
                    -- a closing-paren line (at_close_paren) and nothing has been
                    -- parsed yet — that's the port-list or #( opener.
                    if p == 0 and at_close_paren
                       and ininstdecl == 0 and ininsttype == 0 then
                        local prev = (col > 0) and line:sub(col, col) or ''
                        if prev == '#' then ininsttype = -1
                        else              ininstdecl = -1
                        end
                    end
                end
            elseif b > 0 then
                if     ch == ']' then b = b + 1
                elseif ch == '[' then b = b - 1
                end

            -- ── Normal scanning ───────────────────────────────────────────────
            elseif ch == ';' then
                goto give_up
            elseif ch == ')' then
                p = p + 1
            elseif ch == ']' then
                b = b + 1
            elseif ch == '(' then
                local prev = (col > 0) and line:sub(col, col) or ''
                if prev == '#' then ininsttype = -1
                else              ininstdecl = -1
                end
            elseif ininstdecl == -1 and ch:match('%w') then
                ininstdecl = col
            elseif ininstdecl > 0 and ininsttype == 0
                   and (ch:match('%s') or col == 0) then
                ininsttype = -1
            elseif ininsttype == -1 and ch:match('%w') then
                ininsttype = col
            elseif ininsttype > 0 and (ch:match('%s') or col == 0) then
                found_line = linenr
                goto done
            end
        end

        linenr = linenr - 1
    end

    ::give_up::
    ::done::

    if found_line then
        vim.cmd("normal! m'")   -- record current position so '' jumps back
        vim.fn.cursor(found_line, 1)
    else
        vim.notify('Not inside a Verilog instance', vim.log.levels.WARN)
    end
end

return M
