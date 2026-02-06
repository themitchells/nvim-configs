-- Verilog-specific Keymaps
-- Migrated from ~/.vim/vimrcs/extended.vim

-- Verilog formatting keymaps
vim.keymap.set('n', '<F8>', function()
    local ok, format = pcall(require, 'verilog.format')
    if ok then
        format.format_to_instance()
    else
        vim.notify("Failed to load verilog.format", vim.log.levels.ERROR)
    end
end, { desc = "Format Verilog instance" })

vim.keymap.set('n', '<F9>', function()
    local ok, format = pcall(require, 'verilog.format')
    if ok then
        format.format_to_instance_line()
    else
        vim.notify("Failed to load verilog.format", vim.log.levels.ERROR)
    end
end, { desc = "Format Verilog line" })

-- Verilog plugin keymaps (if verilog_systemverilog.vim is loaded)
vim.keymap.set('n', '<leader>u', function()
    if vim.fn.exists(':VerilogGotoInstanceStart') == 2 then
        vim.cmd('VerilogGotoInstanceStart')
    else
        vim.notify("Verilog plugin not loaded", vim.log.levels.WARN)
    end
end, { silent = true, desc = "Goto Verilog instance start" })

-- Additional Verilog-specific mappings can be added here
