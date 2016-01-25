" ============================================================================
" Name:        hiPairs.vim
" Author:      Yggdroot <archofortune@gmail.com>
" Description: Highlight the pair surrounding the current cursor position.
"              The pairs are defined in &matchpairs.
" ============================================================================

if exists("g:loaded_hiPairs") || &cp || !exists("##CursorMoved")
    finish
endif
let g:loaded_hiPairs = 1

if !exists("g:hiPairs_hl_matchPair")
    let g:hiPairs_hl_matchPair = { 'term'    : 'underline,bold',
                \                  'cterm'   : 'underline,bold',
                \                  'ctermfg' : 'NONE',
                \                  'ctermbg' : 'NONE',
                \                  'gui'     : 'underline,bold',
                \                  'guifg'   : 'NONE',
                \                  'guibg'   : 'NONE' }
endif

if !exists("g:hiPairs_hl_unmatchPair")
    let g:hiPairs_hl_unmatchPair = { 'term'    : 'underline,italic',
                \                    'cterm'   : 'italic',
                \                    'ctermfg' : '15',
                \                    'ctermbg' : '12',
                \                    'gui'     : 'italic',
                \                    'guifg'   : 'White',
                \                    'guibg'   : 'Red' }
endif

if !exists("g:hiPairs_enable_matchParen")
    let g:hiPairs_enable_matchParen = 1
endif

if !exists("g:hiPairs_timeout")
    let g:hiPairs_timeout = 20
endif

if !exists("g:hiPairs_insert_timeout")
    let g:hiPairs_insert_timeout = 20
endif

if !exists("g:hiPairs_stopline_more")
    let g:hiPairs_stopline_more = 20000
endif

augroup hiPairs
    autocmd! VimEnter,ColorScheme * call s:DisableMatchParen() | call s:InitColor()
    autocmd! BufWinEnter * call s:InitMatchPairs()
    autocmd! CursorMoved,CursorMovedI,WinEnter * call s:HiPairs(0)
    autocmd! CursorHold,CursorHoldI * call s:HiPairs(1)
augroup END

" Skip the rest if it was already done.
if exists("*s:HiPairs")
    finish
endif

let s:cpo_save = &cpo
set cpo-=C

" a and b is of type [line, col]
function! s:Compare(a, b)
    return a:a[0] == a:b[0] ? a:a[1]-a:b[1] : a:a[0]-a:b[0]
endfunction

" Disable matchparen.vim
function! s:DisableMatchParen()
    if !g:hiPairs_enable_matchParen
        NoMatchParen
    endif
endfunction

" Enable matchparen.vim
function! s:EnableMatchParen()
    if !g:hiPairs_enable_matchParen
        DoMatchParen
    endif
endfunction

function! s:InitColor()
    let arguments = ''
    for [key, value] in items(g:hiPairs_hl_matchPair)
        let arguments .= ' '.key.'='.value
    endfor
    exec 'hi default hiPairs_matchPair'.arguments
    let arguments = ''
    for [key, value] in items(g:hiPairs_hl_unmatchPair)
        let arguments .= ' '.key.'='.value
    endfor
    exec 'hi default hiPairs_unmatchPair'.arguments
endfunction

function! s:InitMatchPairs()
    let b:pair_list = split(&l:matchpairs, '.\zs[:,]')
    let b:pair_list_ok = map(copy(b:pair_list), 'v:val =~ '']\|['' ? ''\''.v:val : v:val')
endfunction

function! s:ClearMatch()
    if exists("w:hiPairs_ids")
        for id in w:hiPairs_ids
            call matchdelete(id)
        endfor
    endif
    " Store the IDs returned by matchadd
    let w:hiPairs_ids = []
endfunction

function! s:IsBufferChanged()
    if !exists('b:hiPairs_changedtick')
        let b:hiPairs_changedtick = -1
    endif
    if b:hiPairs_changedtick != b:changedtick
        let b:hiPairs_changedtick = b:changedtick
        return 1
    else
        return 0
endfunction

function! s:HiPairs(is_hold)
    if empty(b:pair_list)
        return
    endif

    " Avoid that we remove the popup menu.
    " Return when there are no colors (looks like the cursor jumps).
    if pumvisible() || (&t_Co < 8 && !has("gui_running"))
        return
    endif

    " Build an expression that detects whether the current cursor position is in
    " certain syntax types (string, comment, etc.), for use as searchpairpos()'s
    " skip argument.
    " We match 'escape' for special items, such as lispEscapeSpecial.
    let s_skip = '!empty(filter(map(synstack(line("."), col(".")), ''synIDattr(v:val, "name")''), ' .
                \ '''v:val =~? "string\\|character\\|singlequote\\|escape\\|comment"''))'

    " Limit the search to lines visible in the window.
    let stopline_bottom = line('w$')
    let stopline_top = line('w0')

    if !exists("b:hiPairs_old_pos")
        let b:hiPairs_old_pos = [[0, 0], [0, 0]]
    endif

    let cur_line = line('.')
    let cur_col = col('.')
    let text = getline('.')
    let cur_char = text[cur_col-1]
    let idx = index(b:pair_list, cur_char)

    " Limit the search time to 1 msec to avoid a hang on very long lines.
    " This fails when a timeout is not supported.
    if mode() == 'i' || mode() == 'R'
        let timeout = g:hiPairs_insert_timeout
        let before_char = cur_col > 1 ? text[cur_col-2] : ''
        let before_idx = index(b:pair_list, before_char)
    else
        let timeout = g:hiPairs_timeout
    endif

    if a:is_hold
        let timeout = 500
        let b:hiPairs_old_pos = [[0, 0], [0, 0]]
    endif

    " Character under cursor is not bracket
    if idx < 0
        " In Insert mode, character before the cursor is a right bracket
        if !g:hiPairs_enable_matchParen && (mode() == 'i' || mode() == 'R') && before_idx >= 0 && before_idx % 2 == 1
            let [r_line, r_col] = [cur_line, cur_col-1]
            if s:IsBufferChanged() == 0 && b:hiPairs_old_pos[1] == [r_line, r_col]
                return
            endif
            call cursor(cur_line, cur_col - 1)
            " Search backward
            let [l_line, l_col] = searchpairpos(b:pair_list_ok[before_idx-1], '', b:pair_list_ok[before_idx], 'nbW', s_skip, max([stopline_top-g:hiPairs_stopline_more,1]), timeout)
            call cursor(cur_line, cur_col)
        else
            let [l_line, l_col] = searchpairpos(b:pair_list_ok[0], '', b:pair_list_ok[1], 'nbW', s_skip, max([stopline_top-g:hiPairs_stopline_more,1]), timeout)
            let k = 0
            for i in range(2, len(b:pair_list)-1, 2)
                let pos = searchpairpos(b:pair_list_ok[i], '', b:pair_list_ok[i+1], 'nbW', s_skip, max([l_line,stopline_top-g:hiPairs_stopline_more,1]), timeout)
                if s:Compare(pos, [l_line, l_col]) > 0
                    let [l_line, l_col] = pos
                    let k = i
                endif
            endfor
            if [l_line, l_col] != [0, 0]
                if s:IsBufferChanged() == 0 && b:hiPairs_old_pos[0] == [l_line, l_col]
                    return
                endif
                let [r_line, r_col] = searchpairpos(b:pair_list_ok[k], '', b:pair_list_ok[k+1], 'nW', s_skip, stopline_bottom+g:hiPairs_stopline_more, timeout)
            else
                let [r_line, r_col] = searchpairpos(b:pair_list_ok[0], '', b:pair_list_ok[1], 'nW', s_skip, stopline_bottom+g:hiPairs_stopline_more, timeout)
                for i in range(2, len(b:pair_list)-1, 2)
                    let stopline = r_line > 0 ? r_line : stopline_bottom+g:hiPairs_stopline_more
                    let pos = searchpairpos(b:pair_list_ok[i], '', b:pair_list_ok[i+1], 'nW', s_skip, stopline, timeout)
                    if [r_line, r_col] == [0, 0] || pos != [0, 0] && s:Compare(pos, [r_line, r_col]) < 0
                        let [r_line, r_col] = pos
                    endif
                endfor
            endif
        endif
    " Character under cursor is a left bracket
    elseif idx % 2 == 0
        let [l_line, l_col] = [cur_line, cur_col]
        if s:IsBufferChanged() == 0 && b:hiPairs_old_pos[0] == [l_line, l_col]
            return
        endif
        " Search forward
        let [r_line, r_col] = searchpairpos(b:pair_list_ok[idx], '', b:pair_list_ok[idx+1], 'nW', s_skip, stopline_bottom+g:hiPairs_stopline_more, timeout)
    " Character under cursor is a right bracket
    else
        let [r_line, r_col] = [cur_line, cur_col]
        if s:IsBufferChanged() == 0 && b:hiPairs_old_pos[1] == [r_line, r_col]
            return
        endif
        " Search backward
        let [l_line, l_col] = searchpairpos(b:pair_list_ok[idx-1], '', b:pair_list_ok[idx], 'nbW', s_skip, max([stopline_top-g:hiPairs_stopline_more,1]), timeout)
    endif

    if b:hiPairs_old_pos[0] == [l_line, l_col] && b:hiPairs_old_pos[1] == [r_line, r_col]
        return
    else
        let b:hiPairs_old_pos = [[l_line, l_col], [r_line, r_col]]
    endif

    " Remove any previous match.
    call s:ClearMatch()

    if [r_line, r_col] == [0, 0]
        if [l_line, l_col] == [0, 0]
            return
        else
            "highlight the left unmatched pair
            let id = matchadd("hiPairs_unmatchPair", '\%' . l_line . 'l\%' . l_col . 'c')
            call add(w:hiPairs_ids, id)
        endif
    else
        if [l_line, l_col] == [0, 0]
            "highlight the right unmatched pair
            let id = matchadd("hiPairs_unmatchPair", '\%' . r_line . 'l\%' . r_col . 'c')
            call add(w:hiPairs_ids, id)
        else
            if l_line < stopline_top && r_line > stopline_bottom
                return
            else
                "highlight the matching pairs
                let id = matchadd("hiPairs_matchPair", '\(\%' . l_line . 'l\%' . l_col . 'c\)\|\(\%' . r_line . 'l\%' . r_col . 'c\)')
                call add(w:hiPairs_ids, id)
            endif
        endif
    endif
endfunction

" Define commands that will disable and enable the plugin.
command! HiPairsDisable windo silent! call s:EnableMatchParen() | call s:ClearMatch() |
            \ unlet! g:loaded_hiPairs | unlet! b:hiPairs_old_pos | au! hiPairs
command! HiPairsEnable runtime plugin/hiPairs.vim | windo doau CursorMoved
command! HiPairsToggle if exists("g:loaded_hiPairs") | exec 'HiPairsDisable' | else | exec 'HiPairsEnable' | endif

let &cpo = s:cpo_save
unlet s:cpo_save
