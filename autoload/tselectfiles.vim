" tselectfiles.vim
" @Author:      Thomas Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-10-15.
" @Last Change: 2009-02-06.
" @Revision:    0.0.243

if &cp || exists("loaded_tselectfiles_autoload")
    finish
endif
let loaded_tselectfiles_autoload = 1


let s:select_files_files = {}


function! s:CacheID() "{{{3
    return s:select_files_dir . string(s:select_files_pattern)
endf


function! s:PrepareSelectFiles(hide)
    " TLogVAR a:hide
    " let filter = s:select_files_dir . s:select_files_pattern.pattern
    " TLogVAR filter
    let rv = []
    for pattern in s:select_files_pattern.pattern
        " TLogVAR pattern
        let rv += split(globpath(s:select_files_dir, pattern), '\n')
        if pattern == '*'
            let rv += split(globpath(s:select_files_dir, '.'. pattern), '\n')
        endif
    endfor
    " TLogVAR rv
    if a:hide
        call filter(rv, 'v:val !~ g:tselectfiles_hidden_rx')
    endif
    " call TLogDBG(string(s:select_files_pattern))
    if s:select_files_pattern.mode == 'r'
        if s:select_files_pattern.limit == 0
            call sort(filter(rv, '!isdirectory(v:val)'))
        else
            call sort(map(rv, 'isdirectory(v:val) ? tlib#dir#CanonicName(v:val) : v:val'))
            if !empty(get(s:select_files_pattern, 'predecessor', ''))
                " call TLogDBG(get(s:select_files_pattern, 'predecessor'))
                call insert(rv, tlib#dir#CanonicName(s:select_files_pattern.predecessor))
            endif
        endif
    else
        call sort(map(rv, 'isdirectory(v:val) ? v:val."/" : v:val'))
        let rv += g:tselectfiles_favourites
        " TLogVAR rv
        " call TLogDBG(string(split(s:select_files_dir, '[^\\]\zs,')))
        for phf in split(s:select_files_dir, '[^\\]\zs,')
            let ph = tlib#dir#CanonicName(fnamemodify(tlib#dir#PlainName(phf), ':h'))
            " TLogVAR ph, phf
            " call TLogDBG(s:select_files_dir)
            if ph != tlib#dir#CanonicName(phf)
                " TLogVAR ph, phf
                " call insert(rv, ph .'../')
                call insert(rv, ph)
            endif
        endfor
    endif
    return rv
endf


function! s:UseCache() "{{{3
    let use_cache = tlib#var#Get('tselectfiles_use_cache', 'bg')
    let no_cache  = tlib#var#Get('tselectfiles_no_cache_rx', 'bg')
    let rv = use_cache && (empty(no_cache) || s:select_files_dir !~ no_cache)
    " TLogVAR rv
    return rv
endf


function! tselectfiles#GetFileList(world, mode, ...)
    TVarArg ['hide', get(a:world, 'hide', 1)]
    if s:UseCache()
        let id = s:CacheID()
        if a:mode =~ '\(!\|\d\)$' || a:mode == 'scan' || !has_key(s:select_files_files, id)
            if a:mode =~ '!$'
                let s:select_files_files = {}
            endif
            " TLogVAR id
            let s:select_files_files[id] = s:PrepareSelectFiles(hide)
        endif
        let rv = s:select_files_files[id]
    else
        let rv = s:PrepareSelectFiles(hide)
    endif
    let a:world.base = rv
    " TLogVAR a:world.base
    " let a:world.files = rv
    " let a:world.base  = map(copy(rv), 'tselectfiles#FormatEntry(a:world, v:val)')
endf


function! tselectfiles#AgentPostprocess(world, result)
    if a:result[0 : 2] == '...'
        let item = s:select_files_prefix . a:result[3 : -1]
    else
        let item = a:result
    endif
    let item = resolve(item)
    " TLogVAR item
    " TLogDBG len(a:world.list)
    if isdirectory(item)
        if get(s:select_files_pattern, 'limit', 0) > 0
            let s:select_files_pattern.predecessor = s:select_files_dir
        endif
        let s:select_files_dir = fnamemodify(item, ':p')
        return [s:ResetInputList(a:world, ''), '']
    endif
    return [a:world, item]
endf


function! tselectfiles#AgentOpenDir(world, selected)
    let dir = input('DIR: ', '', 'dir')
    echo
    if dir != ''
        let s:select_files_dir = fnamemodify(dir, ':p')
        return s:ResetInputList(a:world, '')
    endif
    return a:world
endf


" function! tselectfiles#AgentSelect(world, selected) "{{{3
"     let fname = a:world.GetBaseItem(a:world.prefidx)
"     if !filereadable(fname) && s:UseCache()
"         echom 'TSelectFile: Out-dated cache? File not readable: '. fname
"         return s:ResetInputList(a:world)
"     else
"         call a:world.SelectItem('toggle', a:world.prefidx)
"         " let a:world.state = 'display keepcursor'
"         let a:world.state = 'redisplay'
"         return a:world
"     endif
" endf


function! tselectfiles#AgentReset(world, selected) "{{{3
    return s:ResetInputList(a:world)
endf


function! s:DeleteFile(file)
    let doit = input('Really delete file '. string(a:file) .'? (y/N) ', s:delete_this_file_default)
    echo
    if doit ==? 'y'
        if doit ==# 'Y'
            let s:delete_this_file_default = 'y'
        endif
        call delete(a:file)
        echom 'Delete file: '. a:file
        let bn = bufnr(a:file)
        if bn != -1 && bufloaded(bn)
            let doit = input('Delete corresponding buffer '. bn .' too? (y/N) ')
            if doit ==? 'y'
                exec 'bdelete '. bn
            endif
        endif
    endif
endf


function! tselectfiles#AgentDeleteFile(world, selected)
    call a:world.CloseScratch()
    let s:delete_this_file_default = ''
    for file in a:selected
        call s:DeleteFile(file)
    endfor
    return s:ResetInputList(a:world)
endf


function! tselectfiles#Grep(world, selected)
    let grep_pattern = input('Grep pattern: ')
    if !empty(grep_pattern)
        call a:world.CloseScratch()
        cexpr []
        for filename in a:selected
            if filereadable(filename)
                " TLogVAR filename
                exec 'silent! vimgrepadd /'. escape(grep_pattern, '/') .'/j '. tlib#arg#Ex(filename)
            endif
        endfor
        if !empty(getqflist()) && !empty(g:tselectfiles_show_quickfix_list)
            exec g:tselectfiles_show_quickfix_list
        endif
    endif
    call a:world.ResetSelected()
    return a:world
endf


function! s:Preview(file) "{{{3
    exec 'pedit '. escape(a:file, '%# ')
    let s:tselectfiles_previewedfile = a:file
endf


function! s:ClosePreview() "{{{3
    if exists('s:tselectfiles_previewedfile')
        pclose
        unlet! s:tselectfiles_previewedfile
    endif
endf


function! tselectfiles#ViewFile(world, selected) "{{{3
    " TLogVAR a:selected
    if empty(a:selected)
        call a:world.RestoreOrigin()
        return a:world
    else
        " call a:world.SetOrigin()
        return tlib#agent#ViewFile(a:world, a:selected)
    endif
endf


function! tselectfiles#AgentPreviewFile(world, selected)
    let file = a:selected[0]
    if !exists('s:tselectfiles_previewedfile') || file != s:tselectfiles_previewedfile
        call s:Preview(file)
        let a:world.state = 'redisplay'
    else
        call s:ClosePreview()
        let a:world.state = 'display'
    endif
    return a:world
endf


function! s:ConfirmCopyMove(query, src, dest)
    echo
    echo 'From: '. a:src
    echo 'To:   '. a:dest
    let ok = input(a:query .'(y/n) ', 'y')
    echo
    return ok[0] ==? 'y'
endf


function! s:CopyFile(src, dest, confirm)
    if a:src != '' && a:dest != '' && (!a:confirm || s:ConfirmCopyMove('Copy now?', a:src, a:dest))
        let fc = readfile(a:src, 'b')
        if writefile(fc, a:dest, 'b') == 0
            echom 'Copy file "'. a:src .'" -> "'. a:dest
        else
            echom 'Failed: Copy file "'. a:src .'" -> "'. a:dest
        endif
    endif
endf


function! tselectfiles#AgentCopyFile(world, selected)
    for file in a:selected
        let name = input('Copy "'. file .'" to: ', file)
        echo
        call s:CopyFile(file, name, 0)
    endfor
    return s:ResetInputList(a:world)
endf


function! s:RenameFile(file, name, confirm)
    if a:name != '' && (!a:confirm || s:ConfirmCopyMove('Rename now?', a:file, a:name))
        call rename(a:file, a:name)
        echom 'Rename file "'. a:file .'" -> "'. a:name
        if bufloaded(a:file)
            exec 'buffer! '. bufnr('^'. a:file .'$')
            exec 'file! '. tlib#arg#Ex(a:name)
            echom 'Rename buffer: '. a:file .' -> '. a:name
        endif
    endif
endf


function! tselectfiles#AgentRenameFile(world, selected)
    let s:rename_this_file_pattern = ''
    let s:rename_this_file_subst   = ''
    call a:world.CloseScratch()
    for file in a:selected
        let name = input('Rename "'. file .'" to: ', file)
        echo
        call s:RenameFile(file, name, 0)
    endfor
    return s:ResetInputList(a:world)
endf

function! tselectfiles#AgentBatchRenameFile(world, selected)
    let pattern = input('Rename pattern (whole path): ')
    if pattern != ''
        echo 'Pattern: '. pattern
        let subst = input('Rename substitution: ')
        if subst != ''
            call a:world.CloseScratch()
            for file in a:selected
                let name = substitute(file, pattern, subst, 'g')
                call s:RenameFile(file, name, 1)
            endfor
        endif
    endif
    echo
    return s:ResetInputList(a:world)
endf


function! tselectfiles#AgentSelectBackups(world, selected)
    let a:world.filter = g:tselectfiles_suffixes
    let a:world.state  = 'display'
    return a:world
endf


function! s:ResetInputList(world, ...) "{{{3
    let mode = a:0 >= 1 ? a:1 : 'scan'
    let a:world.state  = 'reset'
    let hide = get(a:world, 'hide', 1)
    " TLogVAR hide
    call tselectfiles#GetFileList(a:world, mode)
    let a:world.picked = 0
    return a:world
endf


function! tselectfiles#AgentHide(world, selected)
    let hidden = get(a:world, 'hide', 1)
    let a:world.hide = hidden ? 0 : 1
    " TLogVAR hidden, a:world.hide
    let a:world.state = 'reset'
    let world = s:ResetInputList(a:world)
    " TLogVAR world.hide
    return world
endf


function! tselectfiles#FormatFirstLine(filename) "{{{3
    if filereadable(a:filename)
        let lines = readfile(a:filename)
        for l in lines
            if !empty(l)
                return printf('%-20s %s', fnamemodify(a:filename, ':t') .'::', l)
            endif
        endfor
    endif
    return a:filename
endf


function! tselectfiles#FormatVikiMetaDataOrFirstLine(filename) "{{{3
    " TLogVAR a:filename
    if filereadable(a:filename)
        let lines = readfile(a:filename)
        let acc   = []
        let cont  = 0
        for l in lines
            if cont || l =~ '^\(\*\|\s*#\(TI\(TLE\)\?\|AU\(THOR\)\?\|DATE\|VAR\)\>\)' || empty(acc)
                let cont = 0
                if l =~ '\\$'
                    let l = substitute(l, '\\\s*$', '', '')
                    let cont = 1
                endif
                if l =~ '\S'
                    call add(acc, l)
                endif
            else
                break
            endif
        endfor
        return printf('%-20s %s', fnamemodify(a:filename, ':t') .'::', join(acc, ' | '))
    endif
    return a:filename
endf


function! tselectfiles#Highlight(world) "{{{3
    if a:world.display_as_filenames
        call a:world.Highlight_filename()
    endif
endf


function! tselectfiles#FormatEntry(world, filename) "{{{3
    " \ {'tlib_UseInputListScratch': 'call world.Highlight_filename()'},
    let display_format = 'a:world.FormatFilename(%s)'
    let filename = fnamemodify(a:filename, ':p')
    let prefix_end = len(s:select_files_prefix) - 1
    if filename[0 : prefix_end] ==# s:select_files_prefix
        let filename = '...' . filename[prefix_end + 1 : -1]
    endif
    " TLogVAR filename
    for [rx, fn] in items(g:tselectfiles_filedescription_rx)
        " TLogVAR rx, fn
        if filename =~ rx
            let a:world.display_as_filenames = 0
            let display_format = fn
            break
        endif
    endfor
    " TLogVAR display_format
    return eval(call(function("printf"), a:world.FormatArgs(display_format, filename)))
endf


function! tselectfiles#FormatFilter(world, filename) "{{{3
    let mode = a:world.tselectfiles_filter_basename
    " TLogVAR mode
    if mode
        return fnamemodify(a:filename, ':t')
    else
        return a:filename
    endif
endf


function! tselectfiles#SelectFiles(mode, dir)
    " TLogVAR a:mode, a:dir
    let s:select_files_buffer = bufnr('%')
    let s:select_files_mode   = a:mode
    if empty(a:dir) || a:dir == '*'
        let s:select_files_dir = tlib#var#Get('tselectfiles_dir', 'bg', escape(expand('%:p:h'), ','))
        let s:select_files_prefix = tlib#var#Get('tselectfiles_prefix', 'bg')
        let filter = [['']]
        let filter_rx = tlib#var#Get('tselectfiles_filter_rx', 'bg')
        if !empty(filter_rx)
            call add(filter, [filter_rx])
        endif
        " TLogVAR filter
    else
        let s:select_files_dir = escape(fnamemodify(a:dir, ':p:h'), ',')
        let s:select_files_prefix = ''
        let filter = ''
    endif
    " call TLogVAR('s:select_files_dir=', s:select_files_dir)
    let world = copy(g:tselectfiles_world)
    let world.state_handlers = [
                \ {'state': '\<reset\>', 'exec': 'call tselectfiles#GetFileList(world, '. string(a:mode) .')'},
                \ ]
    let world.tselectfiles_filter_basename = tlib#var#Get('tselectfiles_filter_basename', 'bg', 0)
    " TLogVAR world.tselectfiles_filter_basename
    if a:mode =~ '^n'
        let s:select_files_pattern = {'mode': 'n', 'pattern': ['*']}
        call s:InstallDirHandler(world)
    elseif a:mode =~ '^r'
        let s:select_files_pattern = {'mode': 'r', 'pattern': []}
        let s:select_files_pattern.limit = tlib#var#Get('tselectfiles_limit', 'wbg', 0)
        if s:select_files_pattern.limit == 0
            call add(s:select_files_pattern.pattern, '**')
        else
            call s:InstallDirHandler(world)
            for i in range(1, s:select_files_pattern.limit)
                call add(s:select_files_pattern.pattern, join(repeat(['*'], i), '/'))
            endfor
        endif
    else
        echoerr 'TSelectFile: Unknown mode: '. a:mode
    endif
    call tselectfiles#GetFileList(world, a:mode)
    let world = tlib#World#New(world)
    if !empty(filter)
        call world.SetInitialFilter(filter)
    endif
    let world.display_as_filenames = 1
    let world.tlib_UseInputListScratch = 'call tselectfiles#Highlight(world)'
    let fs = tlib#input#ListW(world)
    call s:ClosePreview()
endf


function! s:InstallDirHandler(world) "{{{3
    let a:world.post_handlers = [{'postprocess': '', 'agent': 'tselectfiles#AgentPostprocess'}]
endf


" :display: tselectfiles#BaseFilter(?rx='', ?replace='')
function! tselectfiles#BaseFilter(...) "{{{3
    let file = expand('%:t:r')
    if a:0 >= 1
        let rplc = a:0 >= 2 ? a:2 : ''
        let file = substitute(file, a:1, rplc, 'g')
    endif
    let parts = split(file, '\A')
    let subst = tlib#var#Get('tselectfiles_part_subst_'. &filetype, 'wbg', tlib#var#Get('tselectfiles_part_subst', 'wbg', {}))
    for [pattern, substitution] in items(subst)
        call map(parts, 'substitute(v:val, pattern, substitution, "g")')
    endfor
    call filter(parts, '!empty(v:val)')
    let b:tselectfiles_filter_rx = join(parts, '\|')
    return b:tselectfiles_filter_rx
endf

