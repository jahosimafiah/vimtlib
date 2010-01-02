" ruby.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2008-07-15.
" @Last Change: 2009-02-15.
" @Revision:    0.0.41

if &cp || exists("loaded_worksheet_ruby_autoload")
    finish
endif
let loaded_worksheet_ruby_autoload = 1
let s:save_cpo = &cpo
set cpo&vim


let s:prototype = {}


function! s:prototype.Evaluate(lines) dict "{{{3
    let ruby = join(a:lines, "\n")
    let value = ''
    ruby <<EOR
    value = eval(VIM.evaluate('ruby'))
    VIM.command(%{let value=#{value.inspect.inspect}})
EOR
    redir END
    return value
endf


function! worksheet#ruby#InitializeInterpreter(worksheet) "{{{3
endf


function! worksheet#ruby#InitializeBuffer(worksheet) "{{{3
    call extend(a:worksheet, s:prototype)
endf


let &cpo = s:save_cpo
unlet s:save_cpo
