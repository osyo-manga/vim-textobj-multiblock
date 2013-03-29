scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim


" a <= b
function! s:pos_less_equal(a, b)
	return a:a[1] == a:b[1] ? a:a[2] <= a:b[2] : a:a[1] <= a:b[1]
endfunction

" a == b
function! s:pos_equal(a, b)
	return a:a[1] == a:b[1] && a:a[2] == a:b[2]
endfunction

" a < b
function! s:pos_less(a, b)
	return a:a[1] == a:b[1] ? a:a[2] < a:b[2] : a:a[1] < a:b[1]
endfunction

" begin < pos && pos < end
function! s:is_in(range, pos)
	return type(a:pos) == type([]) && type(get(a:pos, 0)) == type([])
\		 ? len(a:pos) == len(filter(copy(a:pos), "s:is_in(a:range, v:val)"))
\		 : s:pos_less(a:range[0], a:pos) && s:pos_less(a:pos, a:range[1])
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
	let blocks = s:blocks
	let result = get(filter(copy(blocks), "v:val[0] ==# a:block || v:val[1] ==# a:block"), 0, [])
	
	return empty(result) ? "" : result[0] ==# a:block ? result[1] : result[0]
endfunction


function! s:regex_escape(str)
	return substitute(substitute(a:str, '[', '\\[', 'g'), ']', '\\]', 'g')
endfunction


function! s:get_cursorchar()
	return matchstr(getline('.'), '.', col('.')-1)
endfunction

function! s:searchpair(cursormove_key, ...)
	if !call("searchpair", a:000)
		return [0, 0, 0, 0]
	endif
	let result = getpos('.')
	if !empty(a:cursormove_key)
		let tmp = getpos('.')
		execute "normal!" a:cursormove_key
		let result = getpos('.')
		call setpos(".", tmp)
	endif
	return result
endfunction

let s:nullpos = [0, 0, 0, 0]

function! s:search(cursormove_key, ...)
	if !call("search", a:000)
		return s:nullpos
	endif
	let result = getpos('.')
	if !empty(a:cursormove_key)
		execute "normal!" a:cursormove_key
	endif
	return getpos('.')
endfunction


function! s:region_single(key, in)
	let pos = getpos(".")
	try
		let end   = s:search(a:in ? "h" : "", s:regex_escape(a:key), "W")
		let start = s:search(a:in ? "l" : "", s:regex_escape(a:key), "bW")
	finally
		call setpos(".", pos)
	endtry
	return [start, end]
endfunction


function! s:searchpair(cursormove_key, ...)
	if !call("searchpair", a:000)
		return s:nullpos
	endif
	if !empty(a:cursormove_key)
		execute "normal!" a:cursormove_key
	endif
	return getpos('.')
endfunction

function! s:region_pair(begin, end, in)
	let pos = getpos(".")
	try
		let end   = s:searchpair(a:in ? "h" : "", s:regex_escape(a:begin), "", s:regex_escape(a:end), "W")
		let start = s:searchpair(a:in ? "l" : "", s:regex_escape(a:begin), "", s:regex_escape(a:end), "bW")
	finally
		call setpos(".", pos)
	endtry
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
	let blocks = s:blocks
	let regions = filter(map(copy(blocks), "s:search_region(v:val[0], v:val[1], a:in)"), "v:val[0] != s:nullpos && v:val[1] != s:nullpos")
	let regions = filter(copy(regions), 'empty(filter(copy(regions), "s:is_in(".string(v:val).", v:val)"))')
	return get(regions, 0, [s:nullpos, s:nullpos])
endfunction


function! s:select(in)
	if empty(getline('.'))
		return 0
	endif
	
	let old_ww = &whichwrap
	try
		set whichwrap=h,l
		let [start, end] = s:select_block(a:in)
		return ["v", start, end]
	finally
		let &whichwrap = old_ww
	endtry
endfunction


function! textobj#multiblock#select_a_forward()
	return s:select(0)
endfunction

function! textobj#multiblock#select_i_forward()
	return s:select(1)
endfunction




let &cpo = s:save_cpo
unlet s:save_cpo


