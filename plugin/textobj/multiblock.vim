if exists('g:loaded_textobj_multiblock')
  finish
endif
let g:loaded_textobj_multiblock = 1

let s:save_cpo = &cpo
set cpo&vim

let g:textobj_multiblock_blocks = get(g:, "textobj_multiblock_blocks", [])

call textobj#user#plugin('multiblock', {
\      '-': {
\        'select-a': 'asb',
\       '*select-a-function*': 'textobj#multiblock#select_a_forward',
\        'select-i': 'isb',
\      '*select-i-function*': 'textobj#multiblock#select_i_forward',
\      },
\    })

let g:textobj_multiblock_search_limit = get(g:, "textobj_multiblock_search_limit", 100)

let &cpo = s:save_cpo
unlet s:save_cpo
