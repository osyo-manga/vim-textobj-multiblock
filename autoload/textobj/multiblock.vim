scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim


function! s:uniq(list)
	return reverse(filter(reverse(a:list), "count(a:list, v:val) <= 1"))
endfunction


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

function! s:pos_next(pos, ...)
	if a:0 == 0
		return s:pos_next(a:pos, getline(a:pos[0]))
	endif
	if a:pos == s:nullpos
		return a:pos
	endif
	let line = a:1
	let lnum = a:pos[0]
	let col  = a:pos[1]
	let line_size = len(a:1)
	echo len(get(split(line[col-1:], '\zs'), 0))
	return [
\		line_size <= col ? lnum + 1 : lnum,
\		line_size <= col ? 1        : col + len(get(split(line[col-1:], '\zs'), 0, "") ),
\	]
endfunction


function! s:pos_prev(pos, ...)
	let [lnum, col] = a:pos
	if a:0 == 0
		return s:pos_prev(a:pos, getline(lnum), getline(lnum-1))
	endif

	let line = a:1
	let prev_line = a:2
	if a:pos == s:nullpos
		return a:pos
	endif
	let line = a:1
	return [
\		col >= 2 ? lnum  : lnum-1,
\		col >= 2 ? col - len(get(split(line[:col-1], '\zs'), -2, "")) : len(prev_line)
\	]
endfunction



let s:default_blocks = [
\	[ "(", ")" ],
\	[ "[", "]" ],
\	[ "{", "}" ],
\	[ '<', '>' ],
\	[ '"', '"' ],
\	[ "'", "'" ],
\]



function! s:get_block_pair(block)
	let blocks = s:blocks()
	let result = get(filter(copy(blocks), "v:val[0] ==# a:block || v:val[1] ==# a:block"), 0, [])
	
	return empty(result) ? "" : result[0] ==# a:block ? result[1] : result[0]
endfunction


function! s:regex_escape(str)
	return substitute(substitute(a:str, '[', '\\[', 'g'), ']', '\\]', 'g')
endfunction


function! s:get_cursorchar()
	return matchstr(getline('.'), '.', col('.')-1)
endfunction



function! s:region_search_pattern(first, last, pattern)
	if a:first == a:last
		return printf('\%%%dl%s\%%%dc', a:first[0], a:pattern, a:first[1])
	elseif a:first[0] == a:last[0]
		return printf('\%%%dl\%%>%dc%s\%%<%dc', a:first[0], a:first[1]-1, a:pattern, a:last[1]+1)
	elseif a:last[0] - a:first[0] == 1
		return  printf('\%%%dl%s\%%>%dc', a:first[0], a:pattern, a:first[1]-1)
\		. "\\|" . printf('\%%%dl%s\%%<%dc', a:last[0], a:pattern, a:last[1]+1)
	else
		return  printf('\%%%dl%s\%%>%dc', a:first[0], a:pattern, a:first[1]-1)
\		. "\\|" . printf('\%%>%dl%s\%%<%dl', a:first[0], a:pattern, a:last[0])
\		. "\\|" . printf('\%%%dl%s\%%<%dc', a:last[0], a:pattern, a:last[1]+1)
	endif
endfunction


function! s:searchpair_firstpos_end(first, middle, end, pos)
	let pos = searchpairpos(a:first, a:middle, a:end, 'nWb')
	if pos == s:nullpos
		return s:nullpos
	endif
	return searchpos(s:region_search_pattern(pos, a:pos, a:first), 'enb')
endfunction

function! s:searchpair_endpos_end(first, middle, end, pos)
	let pos = searchpairpos(a:first, a:middle, a:end, 'nW')
	if pos == s:nullpos
		return s:nullpos
	endif
	return searchpos(s:region_search_pattern(pos, a:pos, a:end), 'en')
endfunction


function! s:region_single(key, in)
	let end   = searchpos(s:regex_escape(a:key), a:in ? "nW" : "nWe")
	let start = searchpos(s:regex_escape(a:key), a:in ? "nbWe" : "nbW")
	return [start, end]
endfunction


function! s:region_pair(begin, end, in)
	let first = s:regex_escape(a:begin)
	let last  = s:regex_escape(a:end)
	let end = a:in
\		? searchpairpos(first, "", last, "nW")
\		: s:searchpair_endpos_end(first, "", last, getpos("."))

	let start = a:in
\		? s:searchpair_firstpos_end(first, "", last, getpos("."))
\		: searchpairpos(first, "", last, "nbW")

	return [start, end]
endfunction


function! s:search_region(begin, end, in)
	if a:begin ==# a:end
		return s:region_single(a:begin, a:in)
	else
		return s:region_pair(a:begin, a:end, a:in)
	endif
endfunction


function! s:select_block(in, blocks)
	let blocks = a:blocks
	let regions = map(copy(blocks), "[s:search_region(v:val[0], v:val[1], a:in), get(v:val, 2, 0)]")
	call map(filter(regions, "v:val[0][0] != s:nullpos && v:val[0][1] != s:nullpos && (v:val[1] ? v:val[0][0][0] == v:val[0][1][0] : 1)"), "v:val[0]")
	let regions = filter(copy(regions), 'empty(filter(copy(regions), "s:is_in(".string(v:val).", v:val)"))')
	return get(regions, 0, [s:nullpos, s:nullpos])
endfunction


function! s:to_cursorpos(pos)
	if a:pos == s:nullpos
		return [0, 0, 0, 0]
	endif
	return [0, a:pos[0], a:pos[1], 0]
endfunction


function! s:select(in, blocks)
	let [start, end] = s:select_block(a:in, a:blocks)
	if start == s:nullpos || end == s:nullpos
		return 0
	endif
	if a:in
		return ["v",
\			s:to_cursorpos(s:pos_next(start)),
\			s:to_cursorpos(s:pos_prev(end))
\		]
	else
		return ["v", s:to_cursorpos(start), s:to_cursorpos(end)]
	endif
endfunction


let g:textobj_multiblock_blocks = get(g:, "textobj_multiblock_blocks", s:default_blocks)
function! s:blocks()
	return s:uniq(get(b:, "textobj_multiblock_blocks", []) + g:textobj_multiblock_blocks)
endfunction


function! textobj#multiblock#select_a_forward()
	return s:select(0, s:blocks())
endfunction

function! textobj#multiblock#select_i_forward()
	return s:select(1, s:blocks())
endfunction


function! s:as_key(word)
	return exists("*sha256")  ? substitute(sha256(a:word)[:10], '\L', "x", "g") : a:word
endfunction

let s:mapexprs_i = {}
function! textobj#multiblock#mapexpr_i(blocks)
	let key = s:as_key(string(a:blocks))
	if has_key(s:mapexprs_i, key)
		return s:mapexprs_i[key]
	endif
	
	execute
\"	function! Textobj_multiblock_select_i_" . key . "()\n"
\"		return s:select(1, " . string(a:blocks) . ")\n"
\"	endfunction"
	call textobj#user#plugin('multiblock' . key . "i", {
\		"-" : {
\			'select-i': '',
\			'select-i-function': "Textobj_multiblock_select_i_" . key,
\		}
\	})
	let s:mapexprs_i[key] = "\<Plug>(textobj-multiblock". key . "i-i)"
	return s:mapexprs_i[key]
endfunction


let s:mapexprs_a = {}
function! textobj#multiblock#mapexpr_a(blocks)
	let key = s:as_key(string(a:blocks))
	if has_key(s:mapexprs_a, key)
		return s:mapexprs_a[key]
	endif
	
	execute
\"	function! Textobj_multiblock_select_a_" . key . "()\n"
\"		return s:select(0, " . string(a:blocks) . ")\n"
\"	endfunction"
	call textobj#user#plugin('multiblock' . key . "a", {
\		"-" : {
\			'select-a': '',
\			'select-a-function': "Textobj_multiblock_select_a_" . key,
\		}
\	})
	let s:mapexprs_a[key] = "\<Plug>(textobj-multiblock". key . "a-a)"
	return s:mapexprs_a[key]
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo


