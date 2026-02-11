-- Core Neovim Options
-- Migrated from ~/.vim/vimrcs/basic.vim
-- Note: Leader keys are set in init.lua before this file loads

-- Sets how many lines of history VIM has to remember
vim.opt.history = 500

-- Enable filetype plugins
vim.cmd('filetype plugin on')
vim.cmd('filetype indent on')

-- Load matchit plugin for % matching (begin-end, etc.)
vim.cmd('runtime! macros/matchit.vim')

-- Set to auto read when a file is changed from the outside
vim.opt.autoread = false  -- Ask before reloading modified files

-- Fast saving
vim.keymap.set('n', '<leader>w', ':w!<cr>', { desc = "Fast save" })

-- Turn on the Wild menu
vim.opt.wildmenu = true
vim.opt.wildmode = 'longest:full,full'

-- Ignore compiled files
vim.opt.wildignore = '*.o,*~,*.pyc,*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store'

-- Always show current position
vim.opt.ruler = true

-- Height of the command bar
vim.opt.cmdheight = 1

-- A buffer becomes hidden when it is abandoned
vim.opt.hidden = true

-- Configure backspace so it acts as it should act
vim.opt.backspace = 'eol,start,indent'
vim.opt.whichwrap:append('<,>,h,l')

-- Ignore case when searching
vim.opt.ignorecase = true

-- When searching try to be smart about cases
vim.opt.smartcase = true

-- Highlight search results
vim.opt.hlsearch = true

-- Makes search act like search in modern browsers
vim.opt.incsearch = true

-- Don't redraw while executing macros (good performance config)
vim.opt.lazyredraw = true

-- For regular expressions turn magic on
vim.opt.magic = true

-- Show matching brackets when text indicator is over them
vim.opt.showmatch = true

-- How many tenths of a second to blink when matching brackets
vim.opt.matchtime = 2

-- No annoying sound on errors
vim.opt.errorbells = false
vim.opt.visualbell = false
vim.opt.timeoutlen = 500

-- Add a bit extra margin to the left
vim.opt.foldcolumn = '1'

-- Enable syntax highlighting
vim.cmd('syntax enable')

-- Set extra options when running in GUI mode
if vim.fn.has("gui_running") == 1 then
    vim.opt.guioptions:remove('T')
    vim.opt.guioptions:remove('e')
    vim.opt.guitablabel = '%M %t'
end

-- Set utf8 as standard encoding and en_US as the standard language
vim.opt.encoding = 'utf8'

-- Use Unix as the standard file type
vim.opt.fileformats = 'unix,dos,mac'

-- Turn backup off, since most stuff is in SVN, git etc anyway
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false

-- Use XDG-compliant state directory for temporary files
-- The // suffix preserves full file paths in the filename to avoid collisions
vim.opt.directory = vim.fn.stdpath("state") .. "/swap//"
vim.opt.backupdir = vim.fn.stdpath("state") .. "/backup//"
vim.opt.undodir = vim.fn.stdpath("state") .. "/undo//"

-- Ensure directories exist
vim.fn.mkdir(vim.fn.stdpath("state") .. "/swap", "p")
vim.fn.mkdir(vim.fn.stdpath("state") .. "/backup", "p")
vim.fn.mkdir(vim.fn.stdpath("state") .. "/undo", "p")

-- Persistent undo
vim.opt.undofile = true
vim.opt.undolevels = 1000
vim.opt.undoreload = 10000

-- Use spaces instead of tabs
vim.opt.expandtab = true

-- Be smart when using tabs
vim.opt.smarttab = true

-- 1 tab == 4 spaces
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4

-- Linebreak on 500 characters
vim.opt.linebreak = true
vim.opt.textwidth = 500

vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.wrap = false  -- Disable line wrap by default

-- Visual mode pressing * or # searches for the current selection
vim.keymap.set('v', '*', ':<C-u>lua require("utils.helpers").visual_selection("f", "")<CR>/<C-R>=@/<CR><CR>', { silent = true })
vim.keymap.set('v', '#', ':<C-u>lua require("utils.helpers").visual_selection("b", "")<CR>?<C-R>=@/<CR><CR>', { silent = true })

-- Disable highlight when <leader><cr> is pressed
vim.keymap.set('n', '<leader><cr>', ':noh<cr>', { silent = true, desc = "Clear search highlight" })

-- Smart way to move between windows
vim.keymap.set('n', '<C-j>', '<C-W>j', { desc = "Move to window below" })
vim.keymap.set('n', '<C-k>', '<C-W>k', { desc = "Move to window above" })
vim.keymap.set('n', '<C-h>', '<C-W>h', { desc = "Move to window left" })
vim.keymap.set('n', '<C-l>', '<C-W>l', { desc = "Move to window right" })

-- Close all the buffers
vim.keymap.set('n', '<leader>ba', ':bufdo bd<cr>', { desc = "Close all buffers" })

-- Navigate buffers
vim.keymap.set('n', '<leader>l', ':bnext<cr>', { desc = "Next buffer" })
vim.keymap.set('n', '<leader>h', ':bprevious<cr>', { desc = "Previous buffer" })

-- Let 'tl' toggle between this and the last accessed tab
vim.g.lasttab = 1
vim.keymap.set('n', '<leader>tl', ':exe "tabn " .. g:lasttab<cr>', { desc = "Last tab" })
vim.api.nvim_create_autocmd('TabLeave', {
    callback = function()
        vim.g.lasttab = vim.fn.tabpagenr()
    end,
})

-- Opens a new tab with the current buffer's path
vim.keymap.set('n', '<leader>te', ':tabedit <C-r>=expand("%:p:h")<cr>/', { desc = "New tab with current path" })

-- Switch CWD to the directory of the open buffer
vim.keymap.set('n', '<leader>cd', ':cd %:p:h<cr>:pwd<cr>', { desc = "CD to current file" })

-- Specify the behavior when switching between buffers
vim.opt.switchbuf = 'useopen,usetab,newtab'
vim.opt.showtabline = 0  -- Never show tabline (use buffergator instead)

-- Always show the status line
vim.opt.laststatus = 2

-- Format the status line (will be overridden by lualine, so keep simple)
vim.opt.statusline = '%F%m%r%h %w  CWD: %r%{getcwd()}%h    Line: %l  Column: %c'

-- Remap VIM 0 to first non-blank character
vim.keymap.set('n', '0', '^', { desc = "Go to first non-blank" })

-- Move a line of text using ALT+[jk]
vim.keymap.set('n', '<M-j>', 'mz:m+<cr>`z', { desc = "Move line down" })
vim.keymap.set('n', '<M-k>', 'mz:m-2<cr>`z', { desc = "Move line up" })
vim.keymap.set('v', '<M-j>', ":m'>+<cr>`<my`>mzgv`yo`z", { desc = "Move selection down" })
vim.keymap.set('v', '<M-k>', ":m'<-2<cr>`>my`<mzgv`yo`z", { desc = "Move selection up" })

-- When you press gv you Grep after the selected text
vim.keymap.set('v', 'gv', ':<C-u>lua require("utils.helpers").visual_selection("gv", "")<CR>', { silent = true })

-- When you press <leader>r you can search and replace the selected text
vim.keymap.set('v', '<leader>r', ':<C-u>lua require("utils.helpers").visual_selection("replace", "")<CR>', { silent = true })

-- Pressing ,ss will toggle and untoggle spell checking
vim.keymap.set('n', '<leader>ss', ':setlocal spell!<cr>', { desc = "Toggle spell check" })

-- Shortcuts using <leader>
vim.keymap.set('n', '<leader>sn', ']s', { desc = "Next spelling error" })
vim.keymap.set('n', '<leader>sp', '[s', { desc = "Previous spelling error" })
vim.keymap.set('n', '<leader>sa', 'zg', { desc = "Add word to dictionary" })
vim.keymap.set('n', '<leader>s?', 'z=', { desc = "Spelling suggestions" })

-- Toggle paste mode on and off
vim.keymap.set('n', '<leader>pp', ':setlocal paste!<cr>', { desc = "Toggle paste mode" })

-- Quickly open a buffer for scribble
vim.keymap.set('n', '<leader>q', ':e ~/buffer<cr>', { desc = "Open scratch buffer" })

-- Quickly open a markdown buffer for scribble
vim.keymap.set('n', '<leader>x', ':e ~/buffer.md<cr>', { desc = "Open markdown scratch buffer" })

-- Toggle between number and relativenumber
vim.keymap.set('n', '<leader>rn', ':set relativenumber!<cr>', { desc = "Toggle relative numbers" })

-- Line numbers
vim.opt.number = true

-- Highlight current line
vim.opt.cursorline = true
vim.opt.cursorcolumn = true

-- Color columns
vim.opt.colorcolumn = '21,49,89'

-- Enable mouse support
vim.opt.mouse = 'a'

-- Clipboard
vim.opt.clipboard = 'unnamedplus'

-- Title
vim.opt.title = true

-- Scroll offset
vim.opt.scrolloff = 7
vim.opt.sidescrolloff = 5

-- Split behavior
vim.opt.splitbelow = true
vim.opt.splitright = true

-- Update time (for better experience)
vim.opt.updatetime = 300

-- Don't pass messages to |ins-completion-menu|
vim.opt.shortmess:append('c')

-- Sign column
vim.opt.signcolumn = 'yes'

-- Completion options
vim.opt.completeopt = 'menuone,noselect'

-- True color support
if vim.fn.has('termguicolors') == 1 then
    vim.opt.termguicolors = true
end
