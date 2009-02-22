" tAssert.vim
" @Author:      Tom Link (micathom AT gmail com?subject=vim-tAssert)
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2006-12-12.
" @Last Change: 2009-02-22.
" @Revision:    770
"
" GetLatestVimScripts: 1730 1 07tAssert.vim


if &cp || exists("loaded_tassert")
    if !(!exists("s:assert") || g:TASSERT != s:assert)
        finish
    endif
endif
let loaded_tassert = 100


if !exists('g:TASSERT')    | let g:TASSERT = 0    | endif
if !exists('g:TASSERTLOG') | let g:TASSERTLOG = 1 | endif

if exists('s:assert')
    echo 'TAssertions are '. (g:TASSERT ? 'on' : 'off')
endif
let s:assert = g:TASSERT


if g:TASSERT

    if exists(':TLogOn') && empty(g:TLOG)
        TLogOn
    endif

    " :display: TAssert[!] {expr}
    " Test that an expression doesn't evaluate to something |empty()|. 
    " If used after a |:TAssertBegin| command, any occurrences of 
    " "<SID>" in the expression is replaced with the current script's 
    " |<SNR>|. With [!] failures are logged according to the setting of 
    " |g:tAssertLog|.
    command! -nargs=1 -bang TAssert 
                \ let s:assertReason = '' |
                \ try |
                \   let s:assertFailed = empty(eval(<q-args>)) |
                \ catch |
                \   let s:assertReason = v:exception |
                \   let s:assertFailed = 1 |
                \ endtry |
                \ if s:assertFailed |
                \   if "<bang>" != '' |
                \     call tlog#Log(s:assertReason) |
                \   else |
                \     throw substitute(s:assertReason, '^Vim.\{-}:', '', '') |
                \   endif |
                \ endif

else

    " :nodoc:
    command! -nargs=* -bang TAssert :

endif


if !exists(':TAssertOn')

    " Switch assertions on and reload the plugin.
    " :read: command! -bar TAssertOn
    exec 'command! -bar TAssertOn let g:TASSERT = 1 | runtime '. fnameescape(expand('<sfile>:p'))

    " Switch assertions off and reload the plugin.
    " :read: command! -bar TAssertOff
    exec 'command! -bar TAssertOff let g:TASSERT = 0 | runtime '. fnameescape(expand('<sfile>:p'))

    " Comment TAssert* commands and all lines between a TAssertBegin 
    " and a TAssertEnd command.
    command! -range=% -bar -bang TAssertComment call tassert#Comment(<line1>, <line2>, "<bang>")
    " Uncomment TAssert* commands and all lines between a TAssertBegin 
    " and a TAssertEnd command.
    command! -range=% -bar -bang TAssertUncomment call tassert#Uncomment(<line1>, <line2>, "<bang>")

end


finish
CHANGE LOG {{{1

0.1: Initial release

0.2
- More convenience functions
- The convenience functions now display an explanation for a failure
- Convenience commands weren't loaded when g:TASSERT was off.
- Logging to a file & via Decho()
- TAssert! (the one with the bang) doesn't throw an error but simply 
displays the failure in the log
- s:ResolveSIDs() didn't return a string if s:assertFile wasn't set.
- s:ResolveSIDs() caches scriptnames
- Moved logging code to 00tLog.vim

0.3
- IsA(): Can take a list of types as arguments and it provides a way to 
check dictionaries against prototypes or interface definitions.
- IsExistent()
- New log-related commands: TLogOn, TLogOff, TLogBufferOn, TLogBufferOff
- Use TAssertVal(script, expr) to evaluate an expression (as 
argument to a command) in the script context.
- TAssertOn implies TLogOn
- *Comment & *Uncomment commands now take a range as argument (default: 
whole file).
- TAssertComment! & TAssertUncomment! (with [!]) also call 
TLog(Un)Comment.

0.4
- TLogVAR: take a comma-separated variable list as argument; display a 
time-stamp (if +reltime); show only the g:tlogBacktrace'th last items of 
the backtrace.

1.0
- Incompatible changes galore
- Removed :TAssertToggle, :TAssertBegin & :TAssertEnd and other stuff 
that doesn't really belong here.


TODO:
- Line number? Integration with the quickfix list.
- Interactive assertions (buffer input, expected vs observed): 
compare#BufferWithFile() or should#result_in#BufferWithFile()
- Support for Autoloading, AsNeeded ...

