" Vim indent file
" Language:    SystemVerilog / Verilog
" Based on:    nvim built-in runtime/indent/systemverilog.vim
"              (kocha <kocha.lsifrontend@gmail.com>, last upstream change 2022)
"
" Changes from built-in:
"   - ) / ); uses text-based bracket scan (s:FindMatchOpen) rather than the
"     commented-out heuristic; correctly places module instantiation and
"     declaration port/parameter list closes.
"   - Module/function/task body indent after ); works for multi-section
"     headers (module name + import + #() params + () ports on separate lines).
"   - `ifdef/`ifndef/`else/`elsif/`endif indent their contents even inside
"     ( ) blocks (port/parameter lists), so ports inside `ifdef are indented
"     one level relative to the `ifdef line.
"   - Open-statement continuation aligns to the RHS column of assignments
"     (e.g. assign foo = bar &  →  bar is the alignment column).
"   - Close-statement resets indentation by scanning back to the base line,
"     not by a blind -offset (which broke after alignment-based continuation).
"   - always_ff / always_comb / always_latch recognised in one-line block
"     de-indent patterns (the built-in only handled plain 'always').
"   - begin after fork/end/join* does NOT de-indent (parallel block context).
"   - generate/endgenerate added to indent/de-indent keyword lists.
"   - Pure comment lines (// ...) never trigger the open-statement rule.
"   - s:open_statement cleared on close-statement and `endif to prevent
"     stale state from disrupting later `ifdef/`endif blocks.

" Only load this indent file when no other was loaded.
if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

setlocal indentexpr=GetSystemVerilogIndent()
setlocal indentkeys=!^F,o,O,0),0},=begin,=end,=join,=endcase,=join_any,=join_none
setlocal indentkeys+==endmodule,=endfunction,=endtask,=endspecify
setlocal indentkeys+==endclass,=endpackage,=endsequence,=endclocking
setlocal indentkeys+==endinterface,=endgroup,=endprogram,=endproperty,=endchecker
setlocal indentkeys+==endgenerate
setlocal indentkeys+==`else,=`elsif,=`endif
setlocal indentkeys+=;

let b:undo_indent = "setl inde< indk<"

" Only define the function once.
if exists("*GetSystemVerilogIndent")
  finish
endif

let s:cpo_save = &cpo
set cpo&vim

" Persistent multi-line comment depth tracker (/* ... */ spanning lines).
let s:multiple_comment = 0

" Tracks whether we are in an open-statement continuation that will end with
" a standalone 'begin'. Cleared on close-statement, `endif, end/join*.
let s:open_statement = 0

" Keywords that open a named body block via (arg_list); syntax.
" The body after ); should be indented +offset from the keyword.
" Optional virtual/pure virtual/static/automatic qualifier before function/task
" is included so those lines are recognised as body-openers too.
let s:body_open_kw = '\(\<\(virtual\|pure\s\+virtual\|static\|automatic\)\>\s\+\)\=' .
  \ '\<\(module\|function\|task\|interface\|class\|program\|clocking\|property\|sequence\|covergroup\|checker\)\>'

" Lines that are valid inside a module/function header between the keyword
" and the opening (.  Used by s:FindBodyKeyword to skip past them.
" Matches: blank, //-comment, /*-comment, import, #( or (, ), parameter, `
let s:hdr_skip = '^\s*\($\|//\|/\*\|import\>\|include\>\|[#(]\|)\|parameter\>\|localparam\>\|`\)'

"------------------------------------------------------------------------------
" s:FindMatchOpen(lnum)
"   Scan backward from lnum, right-to-left within each line, to find the
"   line number of the ( that matches the ) on lnum.  Comments are stripped
"   before counting.  Returns 0 if not found within 2000 lines.
"------------------------------------------------------------------------------
function! s:FindMatchOpen(lnum)
  let l:need = 0
  let l:ln   = a:lnum
  let l:stop = max([1, a:lnum - 2000])
  while l:ln > l:stop
    let l:ln -= 1
    let l:line = substitute(getline(l:ln), '//.*$',      '', '')
    let l:line = substitute(l:line,        '/\*.\{-}\*/', '', 'g')
    let l:i = len(l:line) - 1
    while l:i >= 0
      if     l:line[l:i] ==# ')' | let l:need += 1
      elseif l:line[l:i] ==# '('
        if l:need == 0 | return l:ln | endif
        let l:need -= 1
      endif
      let l:i -= 1
    endwhile
  endwhile
  return 0
endfunction

"------------------------------------------------------------------------------
" s:InParens(lnum)
"   Return 1 if lnum is inside an unmatched ( ) pair (e.g. port/parameter
"   list).  Same algorithm as s:FindMatchOpen but returns 0/1 only.
"   Limit 2000 lines for consistency with s:FindMatchOpen.
"------------------------------------------------------------------------------
function! s:InParens(lnum)
  let l:need = 0
  let l:ln   = a:lnum
  let l:stop = max([1, a:lnum - 2000])
  while l:ln > l:stop
    let l:ln -= 1
    let l:line = substitute(getline(l:ln), '//.*$',      '', '')
    let l:line = substitute(l:line,        '/\*.\{-}\*/', '', 'g')
    let l:i = len(l:line) - 1
    while l:i >= 0
      if     l:line[l:i] ==# ')' | let l:need += 1
      elseif l:line[l:i] ==# '('
        if l:need == 0 | return 1 | endif
        let l:need -= 1
      endif
      let l:i -= 1
    endwhile
  endwhile
  return 0
endfunction

"------------------------------------------------------------------------------
" s:FindBodyKeyword(open_lnum)
"   Given the line number of a standalone ( that opens a port/param list,
"   scan backward through recognised header lines (s:hdr_skip: blank,
"   comment, import, include, #(, ), parameter, localparam, backtick)
"   to find the body keyword (module/function/task/etc.).
"   Stops at any unrecognised line to avoid scanning into module body code.
"   Returns the line number if found, else -1.  Limit 200 lines.
"------------------------------------------------------------------------------
function! s:FindBodyKeyword(open_lnum)
  let l:ln   = a:open_lnum
  let l:stop = max([1, a:open_lnum - 200])
  while l:ln > l:stop
    let l:ln -= 1
    let l:hdr = getline(l:ln)
    if l:hdr =~ '^\s*' . s:body_open_kw | return l:ln | endif
    if l:hdr =~ s:hdr_skip              | continue    | endif
    break
  endwhile
  return -1
endfunction

"------------------------------------------------------------------------------
" s:ModuleBodyIndent(close_lnum, offset_val)
"   Given the line number of ) or ); that closes a body block port list,
"   return indent(keyword_line) + offset_val.  Returns -1 if this does not
"   close a recognised body block (e.g. it closes an instantiation).
"------------------------------------------------------------------------------
function! s:ModuleBodyIndent(close_lnum, offset_val)
  let l:open_lnum = s:FindMatchOpen(a:close_lnum)
  if l:open_lnum <= 0 | return -1 | endif
  let l:ctx = getline(l:open_lnum)
  " ( on the same line as the keyword
  if l:ctx =~ '^\s*' . s:body_open_kw
    return indent(l:open_lnum) + a:offset_val
  endif
  " standalone ( — scan backward through header
  let l:kw = s:FindBodyKeyword(l:open_lnum)
  if l:kw > 0
    return indent(l:kw) + a:offset_val
  endif
  return -1
endfunction

"==============================================================================
function GetSystemVerilogIndent()

  let offset = exists('b:sv_indent_width') ? b:sv_indent_width : shiftwidth()
  let indent_modules = exists('b:sv_indent_modules') ? offset : 0
  let indent_ifdef   = exists('b:sv_indent_ifdef_off') ? 0 : 1

  " Find a non-blank line above the current line.
  let lnum = prevnonblank(v:lnum - 1)

  " At the start of the file use zero indent.
  if lnum == 0
    return 0
  endif

  let lnum2      = prevnonblank(lnum - 1)
  let curr_line  = getline(v:lnum)
  let last_line  = getline(lnum)
  let last_line2 = getline(lnum2)
  let ind        = indent(lnum)

  " Operator pattern for open-statement detection.
  " Excludes // and /* */ to avoid matching operators inside comments.
  let sv_openstat = '\(\<or\>\|\([*/]\)\@<![*(,{><+-/%^&|!=?:]\([*/]\)\@!\)'
  " Pattern for an optional trailing comment on a line.
  let sv_comment  = '\(//.*\|/\*.*\*/\s*\)'

  if exists('b:sv_indent_verbose')
    let vverb_str = 'SV INDENT: '. v:lnum .":"
    let vverb = 1
  else
    let vverb = 0
  endif

  " ---- Multi-line block comment tracking -----------------------------------
  if curr_line =~ '^\s*/\*' && curr_line !~ '/\*.\{-}\*/'
    let s:multiple_comment += 1
    if vverb | echom vverb_str "Start of multiple-line comment" | endif
  elseif curr_line =~ '\*/\s*$' && curr_line !~ '/\*.\{-}\*/'
    let s:multiple_comment -= 1
    if vverb | echom vverb_str "End of multiple-line comment" | endif
    return ind
  endif
  if s:multiple_comment > 0
    return ind
  endif

  " ---- ) or ); — place at matching ( level ---------------------------------
  " Must run before the last_line analysis so port list closes are handled
  " before the open-statement logic can misidentify them.
  if curr_line =~ '^\s*)'
    let l:open_lnum = s:FindMatchOpen(v:lnum)
    if l:open_lnum > 0
      let l:open_line = getline(l:open_lnum)
      " ); closes a body block port list — return keyword indent (not body)
      if curr_line =~ '^\s*);\s*' . sv_comment . '*$'
        if l:open_line =~ '^\s*' . s:body_open_kw
          " ( on the same line as the keyword
          if vverb | echom vverb_str "De-indent ); body keyword same line" | endif
          return indent(l:open_lnum)
        endif
        let l:kw = s:FindBodyKeyword(l:open_lnum)
        if l:kw > 0
          if vverb | echom vverb_str "De-indent ); body keyword split" | endif
          return indent(l:kw)
        endif
      endif
      if vverb | echom vverb_str "De-indent ) to matching ( line " . l:open_lnum | endif
      return indent(l:open_lnum)
    else
      if vverb | echom vverb_str "De-indent ) — no match found, fallback" | endif
      return ind - offset
    endif
  endif

  " =========================================================================
  " last_line analysis — set ind for the line being indented
  " =========================================================================

  " ---- if/else/for/case/always/initial/fork/etc. blocks -------------------
  if last_line =~ '^\s*\(end\)\=\s*`\@<!\<\(if\|else\)\>' ||
    \ last_line =~ '^\s*\<\(for\|while\|repeat\|case\%[[zx]]\|do\|foreach\|forever\|randcase\)\>' ||
    \ last_line =~ '^\s*\<\(always\|always_comb\|always_ff\|always_latch\)\>' ||
    \ last_line =~ '^\s*\<\(initial\|specify\|fork\|final\)\>'
    if last_line !~ '\(;\|\<end\>\|\*/\)\s*' . sv_comment . '*$' ||
      \ last_line =~ '\(//\|/\*\).*\(;\|\<end\>\)\s*' . sv_comment . '*$'
      let ind = ind + offset
      let s:open_statement = 0
      if vverb | echom vverb_str "Indent after a block statement." | endif
    endif

  " ---- function/task/class/package/interface/generate/etc. blocks ---------
  elseif last_line =~ '^\s*\<\(function\|task\|class\|package\)\>' ||
    \ last_line =~ '^\s*\<\(sequence\|clocking\|interface\|generate\)\>' ||
    \ last_line =~ '^\s*\(\w\+\s*:\)\=\s*\<covergroup\>' ||
    \ last_line =~ '^\s*\<\(property\|checker\|program\)\>' ||
    \ ( last_line =~ '^\s*\<virtual\>' && last_line =~ '\<\(function\|task\|class\|interface\)\>' ) ||
    \ ( last_line =~ '^\s*\<pure\>'    && last_line =~ '\<virtual\>'  && last_line =~ '\<\(function\|task\)\>' )
    if last_line !~ '\<end\>\s*' . sv_comment . '*$' ||
      \ last_line =~ '\(//\|/\*\).*\(;\|\<end\>\)\s*' . sv_comment . '*$'
      let ind = ind + offset
      let s:open_statement = 0
      if vverb | echom vverb_str "Indent after function/task/class block statement." | endif
    endif

  " ---- ); closed a body block — next line is body -------------------------
  elseif last_line =~ '^\s*);\s*' . sv_comment . '*$'
    let l:r = s:ModuleBodyIndent(lnum, offset)
    if l:r >= 0 | let ind = l:r | endif
    if vverb | echom vverb_str "After ); — indent " . ind | endif

  " ---- ) alone — port list close with ; on a separate line ----------------
  " ; and header lines (synthesis, preprocessor) stay at ) level.
  " Actual code lines get body indent.
  elseif last_line =~ '^\s*)\s*' . sv_comment . '*$'
    if curr_line !~ '^\s*;\s*' . sv_comment . '*$' &&
     \ curr_line !~ '^\s*//' &&
     \ curr_line !~ '^\s*/\*' &&
     \ curr_line !~ '^\s*`' &&
     \ curr_line !~ '^\s*('
      let l:r = s:ModuleBodyIndent(lnum, offset)
      if l:r >= 0 | let ind = l:r | endif
    endif
    if vverb | echom vverb_str "After ) — indent " . ind | endif

  " ---- standalone ; — may terminate a body block with ) on earlier line ---
  elseif last_line =~ '^\s*;\s*' . sv_comment . '*$'
    let l:scan = lnum
    while l:scan > max([1, lnum - 20])
      let l:scan -= 1
      let l:sl = getline(l:scan)
      if     l:sl =~ '^\s*)' | break
      elseif l:sl =~ '^\s*\($\|//\|`\|/\*\)' | continue
      else   | let l:scan = 0 | break
      endif
    endwhile
    if l:scan > 0
      let l:r = s:ModuleBodyIndent(l:scan, offset)
      if l:r >= 0 | let ind = l:r | endif
    endif
    if vverb | echom vverb_str "After ; — indent " . ind | endif

  " ---- module declaration --------------------------------------------------
  elseif last_line =~ '^\s*\(\<extern\>\s*\)\=\<module\>'
    let ind = ind + indent_modules
    if vverb && indent_modules | echom vverb_str "Indent after module statement." | endif
    if last_line =~ '[(,]\s*' . sv_comment . '*$' &&
      \ last_line !~ '\(//\|/\*\).*[(,]\s*' . sv_comment . '*$'
      let ind = ind + offset
      if vverb | echom vverb_str "Indent after a multiple-line module statement." | endif
    endif

  " ---- begin (not on same line as its owner) ------------------------------
  elseif last_line =~ '\(\<begin\>\)\(\s*:\s*\w\+\)*' . sv_comment . '*$' &&
    \ last_line !~ '\(//\|/\*\).*\(\<begin\>\)' &&
    \ ( last_line2 !~ sv_openstat . '\s*' . sv_comment . '*$' ||
    \ last_line2 =~ '^\s*[^=!]\+\s*:\s*' . sv_comment . '*$' )
    let ind = ind + offset
    let s:open_statement = 0
    if vverb | echom vverb_str "Indent after begin statement." | endif

  " ---- { or ( at end of line ----------------------------------------------
  elseif last_line =~ '[{(]' . sv_comment . '*$' &&
    \ last_line !~ '\(//\|/\*\).*[{(]' &&
    \ ( last_line2 !~ sv_openstat . '\s*' . sv_comment . '*$' ||
    \ last_line2 =~ '^\s*[^=!]\+\s*:\s*' . sv_comment . '*$' )
    let ind = ind + offset
    let s:open_statement = 0
    if vverb | echom vverb_str "Indent after { or ( statement." | endif

  " ---- ignore de-indent for end of completed one-line block ---------------
  elseif ( last_line !~ '\<begin\>' ||
    \ last_line =~ '\(//\|/\*\).*\<begin\>' ) &&
    \ last_line2 =~ '\<\(`\@<!if\|`\@<!else\|for\|always\(_comb\|_ff\|_latch\)\?\|initial\|do\|foreach\|forever\|final\)\>.*' .
      \ sv_comment . '*$' &&
    \ last_line2 !~ '\(//\|/\*\).*\<\(`\@<!if\|`\@<!else\|for\|always\(_comb\|_ff\|_latch\)\?\|initial\|do\|foreach\|forever\|final\)\>' &&
    \ last_line2 !~ sv_openstat . '\s*' . sv_comment . '*$' &&
    \ ( last_line2 !~ '\<begin\>' ||
    \ last_line2 =~ '\(//\|/\*\).*\<begin\>' ) &&
    \ last_line2 =~ ')*\s*;\s*' . sv_comment . '*$'
    if vverb | echom vverb_str "Ignore de-indent after end of one-line statement." | endif

  " ---- de-indent for end of one-line block --------------------------------
  " Loops to handle nested single-line blocks, e.g. always_ff → if → stmt.
  elseif ( last_line !~ '\<begin\>' ||
    \ last_line =~ '\(//\|/\*\).*\<begin\>' ) &&
    \ last_line2 =~ '\<\(`\@<!if\|`\@<!else\|for\|always\(_comb\|_ff\|_latch\)\?\|initial\|do\|foreach\|forever\|final\)\>.*' .
      \ sv_comment . '*$' &&
    \ last_line2 !~ '\(//\|/\*\).*\<\(`\@<!if\|`\@<!else\|for\|always\(_comb\|_ff\|_latch\)\?\|initial\|do\|foreach\|forever\|final\)\>' &&
    \ last_line2 !~ sv_openstat . '\s*' . sv_comment . '*$' &&
    \ last_line2 !~ '\(;\|\<end\>\|\*/\)\s*' . sv_comment . '*$' &&
    \ ( last_line2 !~ '\<begin\>' ||
    \ last_line2 =~ '\(//\|/\*\).*\<begin\>' )
    let ind = ind - offset
    if vverb | echom vverb_str "De-indent after end of one-line statement." | endif
    " Unwind additional nesting levels
    let l:chk_lnum = lnum2
    let l:chk_line = last_line2
    while 1
      let l:prv_lnum = prevnonblank(l:chk_lnum - 1)
      if l:prv_lnum == 0 | break | endif
      let l:prv_line = getline(l:prv_lnum)
      if ( l:chk_line !~ '\<begin\>' ||
        \ l:chk_line =~ '\(//\|/\*\).*\<begin\>' ) &&
        \ l:prv_line =~ '\<\(`\@<!if\|`\@<!else\|for\|always\(_comb\|_ff\|_latch\)\?\|initial\|do\|foreach\|forever\|final\)\>.*' .
          \ sv_comment . '*$' &&
        \ l:prv_line !~ '\(//\|/\*\).*\<\(`\@<!if\|`\@<!else\|for\|always\(_comb\|_ff\|_latch\)\?\|initial\|do\|foreach\|forever\|final\)\>' &&
        \ l:prv_line !~ sv_openstat . '\s*' . sv_comment . '*$' &&
        \ l:prv_line !~ '\(;\|\<end\>\|\*/\)\s*' . sv_comment . '*$' &&
        \ ( l:prv_line !~ '\<begin\>' ||
        \ l:prv_line =~ '\(//\|/\*\).*\<begin\>' )
        let ind = ind - offset
        let l:chk_lnum = l:prv_lnum
        let l:chk_line = l:prv_line
      else
        break
      endif
    endwhile

  " ---- close statement — last continuation line ends with ; ---------------
  " Scan back past all continuation lines to restore the pre-continuation
  " indent (handles both +offset and assignment-aligned continuations).
  elseif last_line =~ ')*\s*;\s*' . sv_comment . '*$' &&
   \ last_line !~ '^\s*)*\s*;\s*' . sv_comment . '*$' &&
   \ last_line !~ '\(//\|/\*\).*\S)*\s*;\s*' . sv_comment . '*$' &&
   \ ( last_line2 =~ sv_openstat . '\s*' . sv_comment . '*$' &&
   \   last_line2 !~ '^\s*//' &&
   \   last_line2 !~ ';\s*\(//.*\)\?$') &&
   \ last_line2 !~ '^\s*' . sv_comment . '$'
    let l:scan = lnum
    while 1
      let l:prev = prevnonblank(l:scan - 1)
      if l:prev == 0 | break | endif
      let l:pl = getline(l:prev)
      if l:pl =~ sv_openstat . '\s*' . sv_comment . '*$' &&
       \ l:pl !~ '^\s*//' &&
       \ l:pl !~ '\(//\|/\*\).*' . sv_openstat . '\s*$'
        let l:scan = l:prev
      else
        let ind = indent(l:prev)
        break
      endif
    endwhile
    let s:open_statement = 0
    if vverb | echom vverb_str "De-indent after close statement to col " . ind | endif

  " ---- open statement — continuation line (assign, expressions, etc.) -----
  " Not fired for pure comment lines or inside ( ) blocks.
  " Aligns to RHS column of assignment when present.
  elseif last_line =~ sv_openstat . '\s*' . sv_comment . '*$' &&
   \ last_line !~ '^\s*//' &&
   \ last_line !~ '\(//\|/\*\).*' . sv_openstat . '\s*$' &&
   \ ( last_line2 !~ sv_openstat . '\s*' . sv_comment . '*$' ||
   \   last_line2 =~ '^\s*//' ) &&
   \ !s:InParens(v:lnum)
    let l:asgn_pat = '\([^=!]=\([^=]\|$\)\|<=\)'
    let l:lhs = substitute(last_line, l:asgn_pat . '\s*\zs.*', '', '')
    if len(l:lhs) < len(last_line) && len(l:lhs) > ind
      let ind = len(l:lhs)
    else
      let ind = ind + offset
    endif
    let s:open_statement = 1
    if vverb | echom vverb_str "Indent after an open statement (col " . ind . ")." | endif

  " ---- `ifdef/`ifndef/`elsif/`else — always indent, including inside ( ) --
  elseif last_line =~ '^\s*`\<\(ifn\?def\|elsif\|else\)\>' && indent_ifdef
    let ind = ind + offset
    if vverb | echom vverb_str "Indent after `ifdef/`ifndef/`elsif/`else." | endif

  endif

  " =========================================================================
  " curr_line adjustments — re-indent the current line
  " =========================================================================

  " ---- end*/join*/} — de-indent -------------------------------------------
  " } closes enum/struct/union/concatenation blocks opened by a trailing {.
  if curr_line =~ '^\s*\<\(join\|join_any\|join_none\|end\)\>' ||
      \ curr_line =~ '^\s*\<\(endfunction\|endtask\|endspecify\|endclass\)\>' ||
      \ curr_line =~ '^\s*\<\(endpackage\|endsequence\|endclocking\|endinterface\)\>' ||
      \ curr_line =~ '^\s*\<endgenerate\>' ||
      \ curr_line =~ '^\s*\<\(endgroup\|endproperty\|endchecker\|endprogram\)\>' ||
      \ curr_line =~ '^\s*}'
    let ind = ind - offset
    if vverb | echom vverb_str "De-indent the end of a block." | endif
    if s:open_statement == 1
      let ind = ind - offset
      let s:open_statement = 0
      if vverb | echom vverb_str "De-indent the close statement." | endif
    endif

  " ---- endcase — scan back to matching case keyword -----------------------
  " Uses depth counting to handle nested case statements.
  elseif curr_line =~ '^\s*\<endcase\>'
    let l:ln    = v:lnum
    let l:depth = 0
    while l:ln > 1
      let l:ln -= 1
      let l:gl  = getline(l:ln)
      if l:gl =~ '^\s*\<endcase\>'
        let l:depth += 1
      elseif l:gl =~ '^\s*\<\(case\|casez\|casex\|randcase\)\>'
        if l:depth == 0
          let ind = indent(l:ln)
          break
        endif
        let l:depth -= 1
      endif
    endwhile
    if vverb | echom vverb_str "De-indent endcase to case level" | endif

  " ---- endmodule — scan back to matching module keyword -------------------
  " No line limit: module and endmodule can be arbitrarily far apart.
  elseif curr_line =~ '^\s*\<endmodule\>'
    let l:ln = v:lnum
    while l:ln > 1
      let l:ln -= 1
      if getline(l:ln) =~ '^\s*\(\<extern\>\s*\)\=\<module\>'
        let ind = indent(l:ln)
        break
      endif
    endwhile
    if vverb | echom vverb_str "De-indent endmodule to module level" | endif

  " ---- standalone begin — de-indent when preceded by a block declarator ---
  " Does NOT de-indent when preceded by fork/end/join* (parallel blocks),
  " or function/task/module/etc. (they already added +offset for their block).
  elseif curr_line =~ '^\s*\<begin\>'
    if last_line !~ '^\s*\<\(function\|task\|specify\|module\|class\|package\|fork\)\>' &&
      \ last_line !~ '^\s*\<\(sequence\|clocking\|interface\|covergroup\|generate\)\>' &&
      \ last_line !~ '^\s*\<\(property\|checker\|program\)\>' &&
      \ last_line !~ '^\s*\<\(end\|join\|join_any\|join_none\|endcase\)\>' &&
      \ last_line !~ '^\s*\()*\s*;\|)\+\)\s*' . sv_comment . '*$' &&
      \ ( last_line =~
      \ '\<\(`\@<!if\|`\@<!else\|for\|case\%[[zx]]\|always\(_comb\|_ff\|_latch\)\?\|initial\|do\|foreach\|forever\|randcase\|final\)\>' ||
      \ last_line =~ ')\s*' . sv_comment . '*$' ||
      \ ( last_line =~ sv_openstat . '\s*' . sv_comment . '*$' &&
      \   last_line !~ '^\s*\w[^;()\[\]{]*:\s*' . sv_comment . '*$' ) )
      let ind = ind - offset
      if vverb | echom vverb_str "De-indent a stand alone begin statement." | endif
      if s:open_statement == 1
        let ind = ind - offset
        let s:open_statement = 0
        if vverb | echom vverb_str "De-indent the close statement." | endif
      endif
    endif

  " ---- case item label after end — restore to case-item level -------------
  " When 'end' closes a case arm body, the next case label should be one
  " level below 'case', not at the body level.  Detect by: last non-blank
  " line is a standalone 'end' and curr_line looks like a case item label
  " (identifier/expr followed by ':' with nothing else on the line).
  elseif last_line =~ '^\s*\<end\>\s*' . sv_comment . '*$' &&
      \ curr_line =~ '^\s*\w[^;()\[\]{]*:\s*' . sv_comment . '*$'
    let ind = ind - offset
    if vverb | echom vverb_str "De-indent case label after end." | endif

  " ---- `elsif/`else/`endif — always de-indent, including inside ( ) ------
  elseif curr_line =~ '^\s*`\<\(elsif\|else\|endif\)\>' && indent_ifdef
    let ind = ind - offset
    let s:open_statement = 0
    if vverb | echom vverb_str "De-indent `elsif/`else/`endif." | endif

  endif

  return ind
endfunction

let &cpo = s:cpo_save
unlet s:cpo_save

" vim:sw=2
