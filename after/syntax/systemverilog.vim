" after/syntax/systemverilog.vim
" Extends nvim's built-in systemverilog.vim with items from
" vhda/verilog_systemverilog.vim that are absent from the built-in.
"
" Loads after the built-in syntax/systemverilog.vim (which sources verilog.vim).

" ---- Missing keywords -------------------------------------------------------

" semaphore/mailbox: SV inter-process communication primitives
syn keyword verilogStatement   semaphore mailbox

" get_randstate/set_randstate: random state save/restore
syn keyword verilogStatement   get_randstate set_randstate

" triggered: used in sequence expressions (seq.triggered)
syn keyword verilogStatement   triggered

" std: built-in SV package name
syn keyword verilogStatement   std

" ---- Backtick macros --------------------------------------------------------
" Built-in verilog.vim only highlights a hardcoded list of known directives.
" This catches ALL user-defined `MACRO_NAME usages.
syn match   verilogGlobal      "`[a-zA-Z_][a-zA-Z0-9_$]\+"

" ---- Constants --------------------------------------------------------------
" Built-in pattern misses $ in constant names (e.g. PARAM_$IDX) and requires
" two or more chars after the first letter (uses \+ not *).
syn match   verilogConstant    "\<[A-Z][A-Z0-9_$]*\>"

" ---- Time unit numbers ------------------------------------------------------
" Matches real-number time literals with unit suffix: 100ns, 1.5ps, 10us etc.
" Units: fs ps ns us ms s (with optional f/p/n/u/m prefix before s)
syn match   verilogNumber      "\<\d[0-9_]*\(\.[0-9_]\+\)\=\([fpnum]\)\=s\>"
syn keyword verilogNumber      1step

" ---- Keyword exclusion list -------------------------------------------------
" Used by verilogMethod and verilogInstance patterns to prevent SV keywords
" from being misidentified as module/instance/method names.
let s:inst_excl =
  \ '\<\(begin\|end\|fork\|join\(_any\|_none\)\?\|else\|' .
  \ 'always\(_ff\|_comb\|_latch\)\?\|initial\|final\|' .
  \ 'if\|for\|while\|forever\|repeat\|do\|foreach\|' .
  \ 'case\|casez\|casex\|endcase\|' .
  \ 'return\|wait\|disable\|break\|continue\|default\|' .
  \ 'assign\|typedef\|enum\|import\|export\|' .
  \ 'static\|automatic\|virtual\|extends\|implements\|' .
  \ 'module\|endmodule\|function\|endfunction\|task\|endtask\|' .
  \ 'class\|endclass\|package\|endpackage\|interface\|endinterface\|' .
  \ 'generate\|endgenerate\|program\|endprogram\|' .
  \ 'clocking\|endclocking\|property\|endproperty\|' .
  \ 'sequence\|endsequence\|covergroup\|endgroup\)\>'

" ---- Function / method call names ------------------------------------------
" Highlights the identifier immediately before ( or #(, excluding identifiers
" that follow a dot (those are member accesses, handled by verilogObject below).
" The negative lookbehind avoids matching obj.method() as a function name.
" s:inst_excl exclusion prevents control-flow keywords (if/for/while/case/etc.)
" from being highlighted as method names.
syn keyword verilogMethod      new
execute 'syn match verilogMethod "\(\(\s\|[(/]\|^\)\.\)\@2<!\(' . s:inst_excl . '\)\@!\<\w\+\ze#\?("'

" ---- Object / scope resolution / member access ------------------------------
" Highlights the identifier before :: (package scope) or . (member/modport).
" e.g. pkg::Type, if_toFromSys.sys, struct_var.field
" Starts with letter/underscore to avoid false-matching numbers like 1.5.
syn match   verilogObject      "\<[a-zA-Z_]\w*\ze\(::\|\.\)"

" super/null/this as typed objects (distinct colour from plain statements)
syn keyword verilogObject      super null this

" ---- Named block and assertion labels ---------------------------------------
" Label before assert/assume/cover: label_name: assert(...)
syn match   verilogLabel       "\<\k\+\>\ze\s*:\s*\<\(assert\|assume\|cover\(point\)\?\|cross\)\>"
" Label name after begin/end colon: begin : block_name ... end : block_name
syn match   verilogLabel       "\(\<\(begin\|end\)\>\s*:\s*\)\@20<=\<\k\+\>"

" ---- Module type / instance names ------------------------------------------
" Three patterns cover the common FPGA instantiation styles:
"
"   1. Bare name on its own line (( or #( on next line):
"        zmb_rev0_v2_iobufs
"        u_zmb_rev0_v2_iobufs
"        (
"   Negative lookahead uses s:inst_excl (defined above) to exclude SV keywords.
execute 'syn match verilogInstance "^\s*\(' . s:inst_excl . '\)\@!\<[a-zA-Z_]\w*\>\s*$"'

"   2. Name followed by ( or #( on the same line:
"        if_lifs #(
"        my_module u_inst (     ← matches my_module (u_inst matched by verilogMethod
"                                 because it is followed by '(' on the same line)
execute 'syn match verilogInstance "^\s*\(' . s:inst_excl . '\)\@!\<[a-zA-Z_]\w*\>\ze\s\+[#(]"'

"   3. Name following a (* ... *) attribute on the same line:
"        (* keep_hierarchy = "yes" *) interconnectFabric
"   A syn match cannot span a verilogString region ("yes"), so we use a
"   region for the attribute with nextgroup to pick up the name after it.
syn region  verilogAttribute   start="(\*" end="\*)" oneline
                               \ nextgroup=verilogInstPost skipwhite
syn match   verilogInstPost    "\<[a-zA-Z_]\w*\>\s*$" contained

" ---- Declaration qualifiers -------------------------------------------------
" input/output/inout/ref and parameter/localparam/genvar tell you *what kind*
" of declaration follows. Distinct from other statement keywords.
syn keyword verilogDeclQual    input output inout ref
syn keyword verilogDeclQual    parameter localparam genvar

" ---- Data types -------------------------------------------------------------
" Logic/register/net types and integer types. Distinct from control keywords.
syn keyword verilogDataType    logic wire reg integer
syn keyword verilogDataType    bit byte int shortint longint
syn keyword verilogDataType    real realtime time

" ---- Block delimiters -------------------------------------------------------
" Redefine begin/end/fork/join as a distinct group so they are consistently
" coloured in all contexts (standalone line vs. end of always/if/for line).
syn keyword verilogBlockDelim  begin end fork join join_any join_none



" ---- Highlight links --------------------------------------------------------
hi def link verilogDeclQual    Special
hi def link verilogDataType    Type
hi def link verilogMethod      Function
hi def link verilogObject      Type  " intentionally same as verilogDataType
hi def link verilogInstance    Function
hi def link verilogInstPost    Function
hi def link verilogAttribute   SpecialComment
" Override verilogGlobal (backtick macros, `ifdef etc.) away from Define/Special.
" Uses 'hi link' (not 'hi def link') so tinted.lua can override the color after us.
hi link verilogGlobal          PreProc

" verilogBlockDelim: inherit Function colour + bold.
" nvim_set_hl discards non-link attrs when 'link' is set, so copy first.
" Runs in vim.schedule so colorscheme is fully applied before we read it.
" ColorScheme autocmd reapplies after any theme reload.
lua << EOF
local function apply_block_delim_bold()
  local ok, fn = pcall(vim.api.nvim_get_hl, 0, {name='Function', link=false})
  if ok and fn then
    fn.bold = true
    vim.api.nvim_set_hl(0, 'verilogBlockDelim', fn)
  end
end
vim.schedule(apply_block_delim_bold)
vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('VerilogBlockBold', {clear=true}),
  callback = apply_block_delim_bold,
})
EOF
