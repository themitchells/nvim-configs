-- Verilog/SystemVerilog plugin
-- Custom fork with moduleports indent feature

return {
    "jerias/verilog_systemverilog.vim",
    ft = { "verilog", "systemverilog", "verilog_systemverilog" },
    config = function()
        -- Disable indent for:
        --   eos = end-of-statement (prevents extra indent on );)
        --   moduleports = module port/parameter lists (prevents indent on standalone ()
        vim.g.verilog_disable_indent_lst = "eos,standalone,moduleports"
    end,
}
