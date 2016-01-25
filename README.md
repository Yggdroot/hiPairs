**hiPairs**
===========

Highlights the pair surrounding the current cursor position.
This plugin is inspired by [matchParen.vim]

Screenshots
-----------


Installation
------------

For `Vundle` user, just add `Plugin 'Yggdroot/hiPairs'` to your .vimrc.

Usage
-----

 - `:HiPairsDisable` - Disable the plugin.
 - `:HiPairsEnable` &nbsp;&nbsp;- Enable the plugin.
 - `:HiPairsToggle` &nbsp;&nbsp;- Toggle the plugin.

Customization
-------------

You can use the following global variables to customize the plugin:

 - `g:hiPairs_enable_matchParen`

 If the value is 0, the [matchParen.vim] will be disabled.
 </br>Default value is 1.

 - `g:hiPairs_timeout`

 This plugin takes advantage of the [CursorMoved] autocommand event which is triggered very often,
 so it may make your vim slow(if your computer is not good enough). This variable indicates the
 time highlighting pairs costs during one movement of your cursor. If you encounter performance
 issue, set this variable to a little value(measured in milliseconds).
 </br>Default value is 20 milliseconds.

 - `g:hiPairs_insert_timeout`

 Same as `g:hiPairs_timeout`, but available in insert mode.


 - `g:hiPairs_stopline_more`

 When `hiPairs` searching the pair, this variable tells it to search `g:hiPairs_stopline_more` lines more.
 </br>Default value is 20000.

 - `g:hiPairs_hl_matchPair`

 This variable can be used to change the color of matched pair.
 </br>Default value is as below:

        let g:hiPairs_hl_matchPair = { 'term'    : 'underline,bold',
                    \                  'cterm'   : 'underline,bold',
                    \                  'ctermfg' : 'NONE',
                    \                  'ctermbg' : 'NONE',
                    \                  'gui'     : 'underline,bold',
                    \                  'guifg'   : 'NONE',
                    \                  'guibg'   : 'NONE' }


 - `g:hiPairs_hl_unmatchPair`

 This variable can be used to change the color of unmatched pair.
 </br>Default value is as below:

        let g:hiPairs_hl_unmatchPair = { 'term'    : 'underline,italic',
                    \                    'cterm'   : 'italic',
                    \                    'ctermfg' : '15',
                    \                    'ctermbg' : '12',
                    \                    'gui'     : 'italic',
                    \                    'guifg'   : 'White',
                    \                    'guibg'   : 'Red' }

License
-------

 [MIT](LICENSE)


 [matchParen.vim]: http://vimdoc.sourceforge.net/htmldoc/pi_paren.html
 [CursorMoved]: http://vimdoc.sourceforge.net/htmldoc/autocmd.html#CursorMoved
