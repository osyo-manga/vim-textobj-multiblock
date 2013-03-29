
function! s:pos(lnum, col)
	return [0, a:lnum, a:col, 0]
endfunction

function! s:test_test()
	let owl_SID = owl#filename_to_SID("vim-textobj-smart_block/autoload/textobj/smartblock.vim")
	let p1 = s:pos(2, 3)
	let p2 = s:pos(4, 2)
	let p3 = s:pos(4, 6)
	let p4 = s:pos(6, 1)

	OwlCheck s:pos_less_equal(p1, p2)
	OwlCheck s:pos_less_equal(p1, p1)
	OwlCheck s:pos_less_equal(p2, p3)
	
	OwlCheck  s:pos_equal(p1, p1)
	OwlCheck !s:pos_equal(p1, p3)
	OwlCheck !s:pos_equal(p2, p3)

	OwlCheck  s:pos_less(p1, p2)
	OwlCheck !s:pos_less(p1, p1)
	OwlCheck  s:pos_less(p2, p3)

	OwlCheck  s:is_in([p1, p4], p2)
	OwlCheck !s:is_in([p3, p2], p2)
	OwlCheck !s:is_in([p3, p2], p3)
	OwlCheck  s:is_in([p1, p4], [p2, p3])

endfunction

