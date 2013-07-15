scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim


let s:nullpos = [0, 0]

" a <= b
function! s:pos_less_equal(a, b)
	return a:a[0] == a:b[0] ? a:a[1] <= a:b[1] : a:a[0] <= a:b[0]
endfunction

" a == b
function! s:pos_equal(a, b)
	return a:a[0] == a:b[0] && a:a[1] == a:b[1]
endfunction

" a < b
function! s:pos_less(a, b)
	return a:a[0] == a:b[0] ? a:a[1] < a:b[1] : a:a[0] < a:b[0]
endfunction

" begin < pos && pos < end
function! s:is_in(range, pos)
	return type(a:pos) == type([]) && type(get(a:pos, 0)) == type([])
\		 ? len(a:pos) == len(filter(copy(a:pos), "s:is_in(a:range, v:val)"))
\		 : s:pos_less(a:range[0], a:pos) && s:pos_less(a:pos, a:range[1])
endfunction

function! s:pos_next(pos)
	if a:pos == s:nullpos
		return a:pos
	endif
	let lnum = a:pos[0]
	let col  = a:pos[1]
	let line_size = len(getline(lnum))
	return [
\		line_size == col ? lnum + 1 : lnum,
\		line_size == col ? 1        : col + 1,
\	]
endfunction

function! s:pos_prev(pos)
	if a:pos == s:nullpos
		return a:pos
	endif
	let lnum = a:pos[0]
	let col  = a:pos[1]
	let line_size = len(getline(lnum))
	return [
\		line_size == 0 ? lnum-1               : lnum,
\		line_size == 0 ? len(getline(lnum-1)) : col - 1,
\	]
endfunction


let s:blocks = [
\	[ "(", ")" ],
\	[ "[", "]" ],
\	[ "{", "}" ],
\	[ '<', '>' ],
\	[ '"', '"' ],
\	[ "'", "'" ],
\]


let g:textobj_multiblock_blocks = get(g:, "textobj_multiblock_blocks", s:blocks)


function! s:get_block_pair(block)
	let blocks = g:textobj_multiblock_blocks
	let result = get(filter(copy(blocks), "v:val[0] ==# a:block || v:val[1] ==# a:block"), 0, [])
	
	return empty(result) ? "" : result[0] ==# a:block ? result[1] : result[0]
endfunction


function! s:regex_escape(str)
	return substitute(substitute(a:str, '[', '\\[', 'g'), ']', '\\]', 'g')
endfunction


function! s:get_cursorchar()
	return matchstr(getline('.'), '.', col('.')-1)
endfunction


function! s:region_single(key, in)
	let end   = searchpos(s:regex_escape(a:key), "nW")
	let start = searchpos(s:regex_escape(a:key), "nbW")
	return [start, end]
endfunction


function! s:region_pair(begin, end, in)
	let end   = searchpairpos(s:regex_escape(a:begin), "", s:regex_escape(a:end), "nW")
	let start = searchpairpos(s:regex_escape(a:begin), "", s:regex_escape(a:end), "nbW")
	return [start, end]
endfunction


function! s:search_region(begin, end, in)
	if a:begin ==# a:end
		return s:region_single(a:begin, a:in)
	else
		return s:region_pair(a:begin, a:end, a:in)
	endif
endfunction


function! s:select_block(in)
	let blocks = g:textobj_multiblock_blocks
	let regions = map(copy(blocks), "[s:search_region(v:val[0], v:val[1], a:in), get(v:val, 2, 0)]")
	call map(filter(regions, "v:val[0][0] != s:nullpos && v:val[0][1] != s:nullpos && (v:val[1] ? v:val[0][0][0] == v:val[0][1][0] : 1)"), "v:val[0]")
	call filter(regions, 'empty(filter(copy(regions), "s:is_in(".string(v:val).", v:val)"))')
	return get(regions, 0, [s:nullpos, s:nullpos])
endfunction


function! s:to_cursorpos(pos)
	if a:pos == s:nullpos
		return [0, 0, 0, 0]
	endif
	return [0, a:pos[0], a:pos[1], 0]
endfunction


function! s:select(in)
	let [start, end] = s:select_block(a:in)
	if a:in
		return ["v",
\			s:to_cursorpos(s:pos_next(start)),
\			s:to_cursorpos(s:pos_prev(end))
\		]
	else
		return ["v", s:to_cursorpos(start), s:to_cursorpos(end)]
	endif
endfunction


function! textobj#multiblock#select_a_forward()
	return s:select(0)
endfunction

function! textobj#multiblock#select_i_forward()
	return s:select(1)
endfunction




let &cpo = s:save_cpo
unlet s:save_cpo


