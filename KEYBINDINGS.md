# Neovim Keybindings Quick Reference

## Leader Key: `,` (comma)

---

## Essential Commands

| Key | Action |
|-----|--------|
| `,w` | Save file |
| `,q` | LSP diagnostic list |
| `,sb` | Open scratch buffer |
| `,x` | Open markdown scratch buffer |
| `,/` | Clear search highlight |
| `Space` | Search forward (/) |

---

## File Navigation

| Key | Action |
|-----|--------|
| `F3` | Toggle Buffergator (buffer sidebar) |
| `F4` | Toggle NvimTree (file explorer) |
| `Shift-Tab` | Cycle windows |
| `,nt` | Toggle NvimTree |

---

## Telescope (Fuzzy Finder)

| Key | Action |
|-----|--------|
| `,ff` | Find files |
| `,fg` | Live grep (search in files) |
| `,fb` | Find buffers |
| `,fh` | Help tags |

---

## Buffer Management

| Key | Action |
|-----|--------|
| `,bd` | Close buffer (keep window) |
| `,bn` | Next buffer |
| `,bp` | Previous buffer |
| `,bf` | First buffer |
| `,bl` | Last buffer |
| `,ba` | Close all buffers |
| `,l` | Next buffer (alias) |
| `,h` | Previous buffer (alias) |

---

## Window Navigation

| Key | Action |
|-----|--------|
| `Ctrl-h` | Move to left window |
| `Ctrl-j` | Move to window below |
| `Ctrl-k` | Move to window above |
| `Ctrl-l` | Move to right window |
| `Ctrl-w +` | Increase window height |
| `Ctrl-w -` | Decrease window height |
| `Ctrl-w >` | Increase window width |
| `Ctrl-w <` | Decrease window width |

---

## Git Commands

| Key | Action |
|-----|--------|
| `F5` | Git diff current file |
| `F6` | Toggle word diff |
| `]c` | Next git hunk |
| `[c` | Previous git hunk |
| `,hs` | Stage hunk |
| `,hu` | Undo stage hunk |
| `,hr` | Reset hunk |
| `,hp` | Preview hunk |
| `,hb` | Blame line (popup) |
| `,tb` | Toggle inline git blame |

---

## LSP (Language Server)

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gi` | Go to implementation |
| `gr` | Show references |
| `K` | Hover documentation |
| `,k` | Signature help |
| `,rn` | Rename symbol |
| `,ca` | Code action |
| `,f` | Format buffer |
| `]d` | Next diagnostic |
| `[d` | Previous diagnostic |
| `,e` | Show diagnostic float |
| `,q` | Diagnostic list |

---

## Verilog Formatting

| Key | Action |
|-----|--------|
| `F8` | Format entire Verilog instance |
| `F9` | Format single Verilog line |

**Note:** Aligns ports at column 48, comments at column 88

---

## Sessions

| Key | Action |
|-----|--------|
| `F10` | Set session name |
| `F11` | Load session |
| `F12` | Save session |

---

## Editing

| Key | Action |
|-----|--------|
| `F2` | Toggle line wrap |
| `F7` | Make file executable |
| `Y` | Yank to end of line |
| `0` | Go to first non-blank character |
| `Alt-j` | Move line down |
| `Alt-k` | Move line up |
| `Ctrl-p` | Paste over word (normal mode) |

---

## Tabs

| Key | Action |
|-----|--------|
| `,tn` | New tab |
| `,to` | Close other tabs |
| `,tc` | Close tab |
| `,tm` | Move tab |
| `,tl` | Switch to last tab |
| `,te` | New tab with current path |

---

## Spell Checking

| Key | Action |
|-----|--------|
| `,ss` | Toggle spell check |
| `,sn` | Next spelling error |
| `,sp` | Previous spelling error |
| `,sa` | Add word to dictionary |
| `,s?` | Spelling suggestions |

---

## Quickfix

| Key | Action |
|-----|--------|
| `,cn` | Next quickfix |
| `,cp` | Previous quickfix |
| `,co` | Open quickfix |
| `,cc` | Close quickfix |

---

## Toggles

| Key | Action |
|-----|--------|
| `,rn` | Toggle relative numbers |
| `,pp` | Toggle paste mode |
| `,tc` | Toggle treesitter context |
| `,tb` | Toggle git blame inline |

---

## Other

| Key | Action |
|-----|--------|
| `,cd` | CD to current file directory |
| `,rr` | Reload config |
| `[c` | Jump to context (treesitter) |

---

## Visual Mode

| Key | Action |
|-----|--------|
| `*` | Search for selection forward |
| `#` | Search for selection backward |
| `,r` | Search and replace selection |
| `,y` | Copy to system clipboard |
| `,si` | Auto increment numbers |

---

## Command Mode Shortcuts

| Key | Action |
|-----|--------|
| `Ctrl-A` | Beginning of line |
| `Ctrl-E` | End of line |
| `Ctrl-K` | Delete to end |
| `$h` | Expand to ~/ |
| `$d` | Expand to ~/Desktop/ |

---

## Plugin Commands

| Command | Action |
|---------|--------|
| `:Lazy` | Plugin manager |
| `:Mason` | LSP server manager |
| `:TSContext enable/disable/toggle` | Treesitter context |
| `:LspInfo` | LSP status |
| `:LspRestart` | Restart LSP |
| `:Tabularize` | Align text |

---

Press `q` to close this help window
