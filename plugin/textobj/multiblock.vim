if exists('g:loaded_textobj_multiblock')
  finish
endif
let g:loaded_textobj_multiblock = 1

let s:save_cpo = &cpo
set cpo&vim


call textobj#user#plugin('multiblock', {
\      '-': {
\        'select-a': 'asb',
\       '*select-a-function*': 'textobj#multiblock#select_a_forward',
\        'select-i': 'isb',
\      '*select-i-function*': 'textobj#multiblock#select_i_forward',
\      },
\    })


let &cpo = s:save_cpo
unlet s:save_cpo
