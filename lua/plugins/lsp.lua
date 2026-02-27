-- LSP Configuration
-- NEW: Language Server Protocol support

return {
    "neovim/nvim-lspconfig",
    dependencies = {
        {
            "williamboman/mason.nvim",
            lazy = false,  -- Must load immediately for fresh installs
        },
        {
            "williamboman/mason-lspconfig.nvim",
            lazy = false,  -- Must load immediately to install servers before LSP attaches
        },
        "hrsh7th/nvim-cmp",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
    },
    lazy = false,
    init = function()
        -- Suppress lspconfig deprecation warning (runs before plugin loads)
        if not vim.g._original_notify then
            vim.g._original_notify = vim.notify
            vim.notify = function(msg, ...)
                if msg:match("lspconfig") then
                    return
                end
                vim.g._original_notify(msg, ...)
            end
        end
    end,
    config = function()

        -- Mason setup
        require("mason").setup({
            ui = {
                border = "rounded",
                icons = {
                    package_installed = "✓",
                    package_pending = "➜",
                    package_uninstalled = "✗"
                }
            }
        })

        require("mason-lspconfig").setup({
            ensure_installed = {
                "verible",  -- Verilog/SystemVerilog LSP
                "lua_ls",   -- Lua LSP
                "bashls",   -- Bash LSP
            },
            automatic_enable = {
                exclude = { "verible" },  -- Don't auto-enable verible, use manual config below
            },
        })

        -- nvim-cmp setup for autocompletion
        local cmp = require("cmp")

        cmp.setup({
            -- No snippet engine - just use LSP completion
            snippet = {
                expand = function(args)
                    -- No snippet expansion
                end,
            },
            mapping = cmp.mapping.preset.insert({
                ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                ['<C-f>'] = cmp.mapping.scroll_docs(4),
                ['<C-Space>'] = cmp.mapping.complete(),
                ['<C-e>'] = cmp.mapping.abort(),
                ['<CR>'] = cmp.mapping.confirm({ select = true }),
                ['<Tab>'] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_next_item()
                    else
                        fallback()
                    end
                end, { 'i', 's' }),
                ['<S-Tab>'] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_prev_item()
                    else
                        fallback()
                    end
                end, { 'i', 's' }),
            }),
            sources = cmp.config.sources({
                { name = 'nvim_lsp' },
                { name = 'buffer' },
                { name = 'path' },
            }),
        })

        -- LSP capabilities for completion
        local capabilities = require('cmp_nvim_lsp').default_capabilities()

        local lspconfig = require("lspconfig")

        -- Verilog/SystemVerilog LSP (Verible)
        lspconfig.verible.setup({
            capabilities = capabilities,
            cmd = {
                "verible-verilog-ls",
                "--rules_config=" .. vim.fn.expand("~/.config/nvim/verible-rules.conf")
            },
            filetypes = { "verilog", "systemverilog", "verilog_systemverilog" },
            root_dir = function(fname)
                return lspconfig.util.find_git_ancestor(fname) or vim.fn.getcwd()
            end,
        })

        -- Lua LSP (.luarc.json in workspace root defines vim global)
        -- Only setup if lua-language-server is installed
        if vim.fn.executable("lua-language-server") == 1 then
            lspconfig.lua_ls.setup({
                capabilities = capabilities,
                settings = {
                    Lua = {
                        completion = {
                            callSnippet = "Replace",
                        },
                        telemetry = {
                            enable = false,
                        },
                    },
                },
            })
        end

        -- Bash LSP
        -- Only setup if bash-language-server is installed
        if vim.fn.executable("bash-language-server") == 1 then
            lspconfig.bashls.setup({
                capabilities = capabilities,
            })
        end

        -- LSP keymaps (attached when LSP attaches to buffer)
        vim.api.nvim_create_autocmd("LspAttach", {
            callback = function(args)
                local opts = { buffer = args.buf, silent = true }

                -- Navigation
                vim.keymap.set('n', 'gd', vim.lsp.buf.definition, vim.tbl_extend('force', opts, { desc = "Go to definition" }))
                vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, vim.tbl_extend('force', opts, { desc = "Go to declaration" }))
                vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, vim.tbl_extend('force', opts, { desc = "Go to implementation" }))
                vim.keymap.set('n', 'gr', vim.lsp.buf.references, vim.tbl_extend('force', opts, { desc = "Show references" }))
                vim.keymap.set('n', 'K', vim.lsp.buf.hover, vim.tbl_extend('force', opts, { desc = "Hover documentation" }))
                vim.keymap.set('n', '<leader>k', vim.lsp.buf.signature_help, vim.tbl_extend('force', opts, { desc = "Signature help" }))

                -- Refactoring
                vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, vim.tbl_extend('force', opts, { desc = "Rename symbol" }))
                vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, vim.tbl_extend('force', opts, { desc = "Code action" }))
                vim.keymap.set('n', '<leader>f', function()
                    vim.lsp.buf.format({ async = true })
                end, vim.tbl_extend('force', opts, { desc = "Format buffer" }))

                -- Diagnostics
                vim.keymap.set('n', '[d', function() vim.diagnostic.jump({ count = -1 }) end, vim.tbl_extend('force', opts, { desc = "Previous diagnostic" }))
                vim.keymap.set('n', ']d', function() vim.diagnostic.jump({ count =  1 }) end, vim.tbl_extend('force', opts, { desc = "Next diagnostic" }))
                vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, vim.tbl_extend('force', opts, { desc = "Show diagnostic" }))
                vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, vim.tbl_extend('force', opts, { desc = "Diagnostic list" }))
            end,
        })

        -- Diagnostic configuration
        vim.diagnostic.config({
            virtual_text = {
                prefix = '●',
                source = "if_many",
            },
            float = {
                source = "always",
                border = "rounded",
            },
            signs = {
                text = {
                    [vim.diagnostic.severity.ERROR] = "E",
                    [vim.diagnostic.severity.WARN]  = "W",
                    [vim.diagnostic.severity.HINT]  = "H",
                    [vim.diagnostic.severity.INFO]  = "I",
                },
            },
            underline = true,
            update_in_insert = false,
            severity_sort = true,
        })
    end,
}
