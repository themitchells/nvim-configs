# Neovim Configuration

Modern Neovim configuration migrated from Vim, optimized for FPGA development and Verilog/SystemVerilog editing.

**Migration Date:** 2026-02-04
**Plugin Manager:** lazy.nvim
**Primary Use:** Verilog/SystemVerilog HDL development

---

## Quick Start

```bash
# Launch Neovim
nvim

# Install plugins (first time only)
:Lazy sync

# Install LSP servers
:Mason

# Check health
:checkhealth
```

---

## Directory Structure

```
~/.config/nvim/
├── init.lua                    # Entry point - loads core and plugins
├── README.md                   # This file
├── verible-rules.conf          # Global Verible linter rules
│
├── lua/
│   ├── core/                   # Core Neovim configuration
│   │   ├── init.lua           # Loads all core modules
│   │   ├── options.lua        # Vim options (indentation, search, etc.)
│   │   ├── keymaps.lua        # Global key mappings
│   │   └── autocmds.lua       # Autocommands (filetype detection, etc.)
│   │
│   ├── plugins/               # Plugin specifications (one file per plugin)
│   │   ├── init.lua          # Plugin manager bootstrap & plugin list
│   │   ├── lsp.lua           # LSP configuration (mason, lspconfig, cmp)
│   │   ├── treesitter.lua    # Syntax highlighting
│   │   ├── telescope.lua     # Fuzzy finder
│   │   ├── nvim-tree.lua     # File explorer
│   │   ├── lualine.lua       # Status line
│   │   ├── buffergator.lua   # Buffer sidebar
│   │   ├── gitsigns.lua      # Git integration
│   │   ├── surround.lua      # Surround text objects
│   │   └── verilog.lua       # Verilog plugin configuration
│   │
│   ├── verilog/              # Verilog-specific functionality
│   │   ├── format.lua        # Module instance formatter (F8/F9)
│   │   └── keymaps.lua       # Verilog-specific key mappings
│   │
│   ├── colorscheme/          # Color scheme configuration
│   │   └── tinted.lua        # Tinted-theming setup
│   │
│   ├── sessions/             # Session management
│   │   └── manager.lua       # Session save/load functions
│   │
│   └── utils/                # Utility functions
│       ├── helpers.lua       # General helper functions
│       └── buffer.lua        # Buffer manipulation utilities
│
└── temp_dirs/                # Temporary files (swap, backup, undo, sessions)
    ├── swap/
    ├── backup/
    ├── undo/
    └── sessions/
```

---

## Plugin Management

### Plugin Organization

Each plugin has its own configuration file in `lua/plugins/`. This keeps configurations modular and easy to manage.

**Pattern:**
```lua
-- lua/plugins/example.lua
return {
    "author/plugin-name",
    event = "VeryLazy",  -- or specific events
    config = function()
        -- Plugin configuration here
    end,
}
```

Then import in `lua/plugins/init.lua`:
```lua
{ import = "plugins.example" },
```

### Adding a New Plugin

1. **Create plugin file:** `~/.config/nvim/lua/plugins/newplugin.lua`
   ```lua
   return {
       "author/plugin-name",
       event = "VeryLazy",  -- Lazy-load on event
       config = function()
           -- Setup here
       end,
   }
   ```

2. **Add import:** Edit `lua/plugins/init.lua`
   ```lua
   { import = "plugins.newplugin" },
   ```

3. **Install:** Restart Neovim or run `:Lazy sync`

### Updating Plugins

```vim
:Lazy update              " Update all plugins
:Lazy update plugin-name  " Update specific plugin
:Lazy clean              " Remove unused plugins
```

### Plugin Loading Events

Common lazy-loading triggers:
- `event = "VeryLazy"` - Load after startup
- `event = "BufReadPre"` - Load before reading buffer
- `ft = "filetype"` - Load on specific filetype
- `cmd = "Command"` - Load when command is run
- `keys = { "<leader>x" }` - Load on keypress

---

## LSP Configuration

### File: `lua/plugins/lsp.lua`

**Installed Servers:**
- **verible** - Verilog/SystemVerilog (custom configuration)
- **lua_ls** - Lua language server
- **bashls** - Bash language server

**Mason Integration:**
- **mason.nvim** - LSP server installer
- **mason-lspconfig.nvim** - Bridge between mason and lspconfig
- **nvim-lspconfig** - LSP configurations

### Verible Configuration

**Critical:** Verible is excluded from automatic setup to use custom configuration:

```lua
require("mason-lspconfig").setup({
    ensure_installed = { "verible", "lua_ls", "bashls" },
    automatic_installation = true,
    automatic_enable = {
        exclude = { "verible" },  -- Prevents duplicate instance
    },
})
```

**Custom Verible Setup:**
```lua
lspconfig.verible.setup({
    capabilities = capabilities,
    cmd = {
        "verible-verilog-ls",
        "--rules_config=" .. vim.fn.expand("~/.config/nvim/verible-rules.conf")
    },
    filetypes = { "verilog", "systemverilog", "verilog_systemverilog" },
})
```

### Verible Rules Configuration

**File:** `~/.config/nvim/verible-rules.conf`

Controls Verible linting behavior globally:

```conf
+line-length=length:250
# Add more rules as needed:
# -rule-name              (disable rule)
# +rule-name=param:value  (configure rule)
```

**Common Rules:**
- `+line-length=length:250` - Set line length limit
- `-line-length` - Disable line length checking entirely
- `-module-filename` - Don't enforce module/filename matching

**Documentation:** [Verible Lint Rules](https://chipsalliance.github.io/verible/verilog_lint.html)

### Why Verible Needs Exclusion

Without `automatic_enable = { exclude = { "verible" } }`, mason-lspconfig starts Verible twice:
1. Once with default settings (no custom rules)
2. Once with your custom `--rules_config`

This causes conflicting diagnostics. The exclusion ensures only your custom config runs.

### Adding New LSP Servers

1. Add to `ensure_installed` in mason-lspconfig setup
2. Add manual setup after the mason-lspconfig.setup() call:
   ```lua
   lspconfig.newserver.setup({
       capabilities = capabilities,
   })
   ```
3. Restart Neovim - mason will auto-install the server

---

## Verilog/SystemVerilog Support

### Verilog Plugin

**File:** `lua/plugins/verilog.lua`

Loads the custom fork of verilog_systemverilog.vim from GitHub:
```lua
{
    "jerias/verilog_systemverilog.vim",
    ft = { "verilog", "systemverilog", "verilog_systemverilog" },
    config = function()
        vim.g.verilog_disable_indent_lst = "eos,moduleports"
    end,
}
```

**Indent Configuration:**
- `eos` - Disables extra indent on `);` (end of statement)
- `moduleports` - Disables indent on standalone `(` after module/instance names

### Custom Verilog Formatter

**File:** `lua/verilog/format.lua`

Converts Verilog module declarations into properly formatted instances.

**Functions:**
- `format_to_instance_line()` - Format current line (F9)
- `format_to_instance()` - Format entire instance (F8)

**Features:**
- Extracts module name and parameters
- Creates instance name as `u_<modulename>`
- Aligns port connections at column 48
- Aligns comments at column 88
- Handles all Verilog/SystemVerilog patterns:
  - Parameters (various types)
  - Buses and packed arrays
  - Unpacked arrays
  - SystemVerilog interfaces and structs
  - Bus delimiters `{a, b, c}`
  - Synthesis directives `(* ... *)`

**Example:**

Input:
```verilog
module my_mod #(
    parameter WIDTH = 32
) (
    input wire clk,
    input wire [WIDTH-1:0] data
);
```

Output (after F8):
```verilog
    my_mod
    #(
        .WIDTH                                  (WIDTH)
    )
    u_my_mod
    (
        .clk                                    (clk),
        .data                                   (data)
    );
```

**Keybindings:**
- `F8` - Format entire instance (calls `format_to_instance()`)
- `F9` - Format single line (calls `format_to_instance_line()`)

---

## Core Configuration

### Options (`lua/core/options.lua`)

Global Vim settings:
- Indentation: 4 spaces, expandtab
- Search: case-insensitive with smart case
- Line numbers, relative numbers
- Persistent undo, swap, backup directories
- Timeout settings
- Display options (list chars, wrap, etc.)

### Key Mappings (`lua/core/keymaps.lua`)

Global keybindings and leader key setup (`,` as leader).

**Quick Reference:**
- `,w` - Write file
- `,q` - Quit
- `,bd` - Delete buffer (keep window)
- `,/` - Clear search highlight
- `j`/`k` - Move by visual lines when wrapped
- `Y` - Yank to end of line
- Window navigation: `Ctrl-h/j/k/l`

### Autocommands (`lua/core/autocmds.lua`)

Automatic behaviors:
- Verilog filetype detection (*.v, *.sv, *.svh, etc.)
- Window title updates
- Last cursor position restoration
- Auto-reload changed files

---

## Plugin Details

### File Explorer (nvim-tree)

**Toggle:** `F4` or `,nt`

**Configuration:** `lua/plugins/nvim-tree.lua`

### Fuzzy Finder (Telescope)

**Keybindings:**
- `<leader>ff` - Find files
- `<leader>fg` - Live grep
- `<leader>fb` - Find buffers
- `<leader>fh` - Help tags

**Configuration:** `lua/plugins/telescope.lua`

### Git Integration (Gitsigns)

**Keybindings:**
- `F5` - Git diff current file
- `F6` - Toggle word diff
- `]c` / `[c` - Navigate hunks
- `<leader>hs` - Stage hunk
- `<leader>hu` - Undo stage hunk

**Configuration:** `lua/plugins/gitsigns.lua`

### Status Line (Lualine)

Shows mode, filename, git status, diagnostics, and position.

**Configuration:** `lua/plugins/lualine.lua`

### Buffer Management

**Buffergator:** Sidebar buffer list (`F3` or `,b`)
- Toggle sidebar with F3
- Navigate with j/k
- Open buffer with Enter
- Delete buffer with d

---

## Custom Features

### Verilog Module Instance Formatter

The verilog formatter has been refactored (2026-02-05) with significant improvements:

**Changes:**
- Added CONSTANTS section for magic numbers
- Extracted helper functions for better organization
- Reduced port/parameter logic from 118 lines to 30 lines (74% reduction)
- Fixed bugs with parameter bit vectors, type parameters, and unpacked arrays

**Helper Functions:**
- `extract_comment()` - Parse comments from lines
- `pad_to_column()` - Handle column alignment
- `extract_signal_name()` - Smart signal extraction from any Verilog pattern
- `format_port_connection()` - Generate aligned port connection lines

**Supported Patterns:**
- Basic signals, buses, packed/unpacked arrays
- SystemVerilog interfaces (`axi_if.master`)
- Struct types (`config_struct_t`)
- Bus delimiters (`{a, b, c}`)
- Synthesis directives (`(* keep = "true" *)`)
- Parameters with bit vectors (`parameter [3:0] NAME`)
- Type parameters (`parameter type data_t`)

### Session Management

**Keybindings:**
- `F10` - Set session name
- `F11` - Load session
- `F12` - Save session

Sessions saved to `~/.config/nvim/temp_dirs/sessions/`

---

## Configuration Details

### Leader Key

`,` (comma) is set as both `mapleader` and `maplocalleader`

### Temporary Directories

All temporary files stored in `~/.config/nvim/temp_dirs/`:
- **swap/** - Swap files
- **backup/** - Backup files
- **undo/** - Persistent undo history
- **sessions/** - Session files

This keeps your working directories clean.

### Filetype Detection

Custom filetype detection for Verilog/SystemVerilog:
- Extensions: `.v`, `.vh`, `.vp`, `.sv`, `.svi`, `.svh`, `.svp`, `.sva`
- Filetype: `verilog_systemverilog`

---

## Modifying Configuration

### Adding a Plugin

1. **Create plugin file:**
   ```bash
   # Example: Add a new fuzzy finder
   cat > ~/.config/nvim/lua/plugins/fzf.lua << 'EOF'
   return {
       "junegunn/fzf.vim",
       dependencies = { "junegunn/fzf" },
       cmd = { "Files", "Rg" },
       config = function()
           -- Configuration here
       end,
   }
   EOF
   ```

2. **Import in init.lua:**
   ```lua
   -- In lua/plugins/init.lua, add:
   { import = "plugins.fzf" },
   ```

3. **Install:**
   ```vim
   :Lazy sync
   ```

### Modifying Plugin Configuration

Each plugin has its own file in `lua/plugins/`. Edit the appropriate file and restart Neovim or run `:Lazy reload <plugin-name>`.

### Changing Keybindings

**Global keybindings:** Edit `lua/core/keymaps.lua`

**Plugin-specific keybindings:** Edit the plugin's config file in `lua/plugins/`

**Verilog keybindings:** Edit `lua/verilog/keymaps.lua`

### Adjusting Options

Edit `lua/core/options.lua` for global Vim options like:
- Indentation settings
- Search behavior
- Display options
- Timeout settings

---

## LSP Server Management

### Installing New Language Servers

1. **Via Mason (recommended):**
   ```vim
   :Mason
   ```
   Navigate and press `i` to install

2. **Via Configuration:**
   Add to `ensure_installed` in `lua/plugins/lsp.lua`:
   ```lua
   ensure_installed = {
       "verible",
       "lua_ls",
       "bashls",
       "pyright",  -- Add new server
   },
   ```

3. **Add manual setup:**
   ```lua
   lspconfig.pyright.setup({
       capabilities = capabilities,
   })
   ```

### Configuring LSP Keybindings

LSP keybindings are set in the `LspAttach` autocmd in `lua/plugins/lsp.lua`:

```lua
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(ev)
        -- Add custom keybindings here
    end,
})
```

### Diagnostic Configuration

Control how diagnostics are displayed:

```lua
vim.diagnostic.config({
    virtual_text = { prefix = '●' },  -- Inline warnings
    signs = true,                      -- Gutter signs
    underline = true,                  -- Underline errors
    severity_sort = true,              -- Sort by severity
})
```

---

## Verible Linter Configuration

### Global Rules File

**File:** `~/.config/nvim/verible-rules.conf`

This file is always used for Verible linting (configured via `--rules_config` flag).

**Current Configuration:**
```conf
+line-length=length:250
```

### Adding/Modifying Rules

Edit `verible-rules.conf` and restart Neovim:

```conf
# Syntax:
# +rule-name              Enable rule with defaults
# +rule-name=param:value  Enable and configure
# -rule-name              Disable rule

# Examples:
+line-length=length:250           # Line length: 250 chars
-module-filename                  # Don't enforce module/file naming
-always-comb                      # Don't require always_comb
+port-declarations:length:80      # Configure port declarations
```

**Find available rules:**
```bash
~/.local/share/nvim/mason/bin/verible-verilog-ls --helpfull | grep -i rule
```

**Documentation:** [Verible Rules](https://chipsalliance.github.io/verible/verilog_lint.html)

### Why Custom Verible Configuration?

The LSP config excludes verible from `automatic_enable` to prevent duplicate instances:
- Mason would start verible with defaults (100 char line length)
- Custom setup starts verible with your rules_config (250 char line length)

Without the exclusion, both would run simultaneously causing conflicting diagnostics.

---

## Custom Plugin Modifications

### verilog_systemverilog.vim (Custom Fork)

**Source:** `jerias/verilog_systemverilog.vim` (custom fork)

**Local Modifications** (in `~/.local/share/nvim/lazy/verilog_systemverilog.vim/`):

**File:** `indent/verilog_systemverilog.vim`

**Changes Made:**
1. **Line 18** - Added `0(` to indentkeys:
   ```vim
   setlocal indentkeys=!^F,o,O,0(,0),0},=begin,=end,...
   ```
   Triggers indent recalculation when `(` is typed at beginning of line

2. **Line ~421** - Added bare identifier detection:
   ```vim
   elseif l:line =~ '^\s*[a-zA-Z_][a-zA-Z0-9_]*\s*$'
     " Bare identifier (potential instance name)
     if s:curr_line =~ '^\s*(\s*$' || s:curr_line =~ '^\s*#(\s*$'
       return s:GetContextStartIndent("moduleports", l:lnum) + l:open_offset
     endif
   ```
   Applies moduleports logic to instance names (not just module declarations)

**To Commit Changes:**
```bash
cd ~/.local/share/nvim/lazy/verilog_systemverilog.vim
git add indent/verilog_systemverilog.vim
git commit -m "Fix indent for ( after instance names

- Add 0( to indentkeys to trigger recalc when ( typed
- Detect bare identifiers (instance names) and apply moduleports logic"
git push origin master
```

**Purpose:** These changes prevent unwanted indentation on `(` after module/instance names when `verilog_disable_indent_lst` includes "moduleports".

---

## Essential Keymaps

### General
- `,w` - Save file
- `,q` - Quit
- `,bd` - Close buffer (keep window)
- `,/` - Clear search highlight
- `<Space>` - Search (/)
- `Ctrl-h/j/k/l` - Navigate windows

### Files & Buffers
- `F3` - Buffergator (buffer sidebar)
- `F4` - NvimTree (file explorer)
- `Shift-Tab` - Cycle windows
- `<leader>ff` - Find files (Telescope)
- `<leader>fg` - Live grep (Telescope)
- `<leader>fb` - Find buffers (Telescope)

### Git
- `F5` - Git diff current file
- `F6` - Toggle word diff
- `]c` / `[c` - Next/previous git hunk
- `<leader>hs` - Stage hunk
- `<leader>hu` - Undo stage hunk

### Verilog Formatting
- `F8` - Format entire Verilog instance
- `F9` - Format single Verilog line
- Aligns ports at column 48, comments at column 88

### LSP (when available)
- `gd` - Go to definition
- `gD` - Go to declaration
- `gi` - Go to implementation
- `gr` - Show references
- `K` - Hover documentation
- `<C-k>` - Signature help
- `<leader>rn` - Rename symbol
- `<leader>ca` - Code action
- `<leader>f` - Format buffer
- `]d` / `[d` - Next/previous diagnostic
- `<leader>e` - Show diagnostic float
- `<leader>q` - Diagnostic list

### Sessions
- `F10` - Set session name
- `F11` - Load session
- `F12` - Save session

---

## Troubleshooting

### Plugins Not Loading

Check plugin status:
```vim
:Lazy
```

See which plugins are loaded, any errors, or pending installations.

### LSP Not Working

1. **Check LSP status:**
   ```vim
   :LspInfo
   ```

2. **Check installed servers:**
   ```vim
   :Mason
   ```

3. **Check LSP logs:**
   ```vim
   :lua vim.cmd('edit ' .. vim.fn.stdpath('log') .. '/lsp.log')
   ```

4. **Restart LSP:**
   ```vim
   :LspRestart
   ```

### Verible Showing Duplicate Diagnostics

Ensure `automatic_enable = { exclude = { "verible" } }` is set in mason-lspconfig setup (see LSP Configuration section).

### Indent Issues

Verilog indent configuration is controlled by:
- `vim.g.verilog_disable_indent_lst` - Set in `lua/plugins/verilog.lua`
- verilog_systemverilog.vim indent script
- Treesitter indent (can be disabled per language)

If indent behaves unexpectedly, check:
1. `verilog_disable_indent_lst` value
2. Custom modifications in lazy plugin directory
3. Treesitter indent settings in `lua/plugins/treesitter.lua`

---

## File Locations

### Configuration Files
- **Main entry:** `~/.config/nvim/init.lua`
- **Core config:** `~/.config/nvim/lua/core/`
- **Plugin specs:** `~/.config/nvim/lua/plugins/`
- **Verible rules:** `~/.config/nvim/verible-rules.conf`

### Plugin Data
- **Installed plugins:** `~/.local/share/nvim/lazy/`
- **LSP servers:** `~/.local/share/nvim/mason/`
- **Plugin modifications:** `~/.local/share/nvim/lazy/<plugin-name>/`

### Temporary Files
- **All temp files:** `~/.config/nvim/temp_dirs/`
- **Swap:** `~/.config/nvim/temp_dirs/swap/`
- **Backup:** `~/.config/nvim/temp_dirs/backup/`
- **Undo:** `~/.config/nvim/temp_dirs/undo/`
- **Sessions:** `~/.config/nvim/temp_dirs/sessions/`

---

## Important Notes

### Vim vs Neovim Separation

This Neovim configuration is **completely independent** of any Vim configuration.

- **Neovim config:** `~/.config/nvim/`
- **Vim config:** `~/.vim/` (if exists)
- **No cross-references** - All plugins loaded via lazy.nvim from GitHub

### Plugin Modifications

If you modify plugins in `~/.local/share/nvim/lazy/`, those changes are:
- **NOT tracked by git** (lazy.nvim manages these directories)
- **Will be lost on plugin update** unless committed to your fork

**To preserve changes:**
1. Fork the plugin on GitHub
2. Commit your changes locally
3. Push to your fork
4. Update plugin spec to use your fork

### Backup Before Updates

Before running `:Lazy update`, consider:
- Backing up custom modifications in lazy plugin directories
- Testing updates on non-critical files first
- Checking plugin changelogs for breaking changes

---

## Migration from Vim

This configuration was migrated from Vim to Neovim on 2026-02-04.

**Key Changes:**
- VimScript → Lua configuration
- Vundle → lazy.nvim plugin manager
- Native plugin packs → lazy.nvim managed plugins
- Added LSP support (verible, lua_ls, bashls)
- Added Treesitter for better syntax highlighting
- Added Telescope fuzzy finder
- Preserved all essential functionality from original Vim config

**Original Vim config** remains at `~/.vim/` but is not used by Neovim.

---

## Updates & Maintenance

### Update All Plugins
```vim
:Lazy update
```

### Update LSP Servers
```vim
:Mason
```
Press `U` to update all, or select and press `u` for individual servers.

### Update Neovim
Follow your system's package manager (not managed by this config).

### Git Management

This entire `~/.config/nvim/` directory can be managed with git:

```bash
cd ~/.config/nvim
git init
git add .
git commit -m "Initial Neovim configuration"
git remote add origin <your-repo>
git push -u origin master
```

**Include in git:**
- All `lua/` files
- `init.lua`
- `README.md`
- `verible-rules.conf`
- Any other config files

**Exclude from git:** (add to `.gitignore`)
- `temp_dirs/` - Temporary files
- `lazy-lock.json` - Optional (locks plugin versions)

---

## Resources

- [lazy.nvim](https://github.com/folke/lazy.nvim) - Plugin manager
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) - LSP configurations
- [Mason](https://github.com/williamboman/mason.nvim) - LSP/tool installer
- [Verible](https://github.com/chipsalliance/verible) - SystemVerilog tools
- [verilog_systemverilog.vim](https://github.com/vhda/verilog_systemverilog.vim) - Verilog plugin (upstream)
- [jerias/verilog_systemverilog.vim](https://github.com/jerias/verilog_systemverilog.vim) - Custom fork

---

## Support & Issues

For issues specific to:
- **This configuration:** Check this README and configuration files
- **lazy.nvim:** [lazy.nvim issues](https://github.com/folke/lazy.nvim/issues)
- **LSP:** `:checkhealth lsp` and `:LspInfo`
- **Verible:** [Verible issues](https://github.com/chipsalliance/verible/issues)
- **Verilog plugin:** [verilog_systemverilog.vim issues](https://github.com/vhda/verilog_systemverilog.vim/issues)

---

## Version History

**2026-02-05:**
- Refactored verilog formatter (format.lua)
- Fixed 4 bugs in signal extraction
- Configured Verible with 250 char line length
- Fixed duplicate Verible instance issue
- Added verilog plugin with moduleports indent disabled
- Fixed vim/nvim config separation
- Modified verilog indent script (0( in indentkeys, bare identifier detection)

**2026-02-04:**
- Initial migration from Vim to Neovim
- Converted VimScript to Lua
- Set up lazy.nvim plugin manager
- Configured LSP support
- Added Treesitter and Telescope
