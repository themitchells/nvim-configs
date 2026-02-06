-- Verilog-specific Keymaps
-- Migrated from ~/.vim/vimrcs/extended.vim

-- Verilog formatting keymaps
vim.keymap.set('n', '<F8>', function()
    require('verilog.format').format_to_instance()
end, { desc = "Format Verilog instance" })

vim.keymap.set('n', '<F9>', function()
    require('verilog.format').format_to_instance_line()
end, { desc = "Format Verilog line" })

-- Verilog plugin keymaps (if verilog_systemverilog.vim is loaded)
vim.keymap.set('n', '<leader>u', ':VerilogGotoInstanceStart<CR>', { silent = true, desc = "Goto Verilog instance start" })

-- Additional Verilog-specific mappings can be added here
