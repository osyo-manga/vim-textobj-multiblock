
function! s:test_next_pos()
	let owl_SID = owl#filename_to_SID("vim-textobj-multiblock/autoload/textobj/multiblock.vim")
	OwlCheck s:pos_next([3, 2], "homu") == [3, 3]
	OwlCheck s:pos_next([3, 5], "homu") == [4, 1]
	OwlCheck s:pos_next([3, 7], "homu") == [4, 1]
	OwlCheck s:pos_next([3, 7], "ああa") == [4, 1]
	OwlCheck s:pos_next([3, 8], "	ああa") == [4, 1]
	OwlCheck s:pos_next([3, 1], "ああa") == [3, 4]
	OwlCheck s:pos_next([3, 4], "ああa") == [3, 7]
	OwlCheck s:pos_next([3, 8], "aああああa") == [3, 11]
endfunction

function! s:test_prev_pos()
	let owl_SID = owl#filename_to_SID("vim-textobj-multiblock/autoload/textobj/multiblock.vim")
	OwlCheck s:pos_prev([3, 2], "homu", "mami") == [3, 1]
	OwlCheck s:pos_prev([3, 1], "homu", "mami") == [2, 4]
	OwlCheck s:pos_prev([3, 1], "homu", "まみ") == [2, 6]
	OwlCheck s:pos_prev([3, 8], "まみmado", "まみ") == [3, 7]
	OwlCheck s:pos_prev([3, 4], "まみmado", "まみ") == [3, 1]
	OwlCheck s:pos_prev([3, 3], "maみmado", "まみ") == [3, 2]
	OwlCheck s:pos_prev([3, 6], "maみmado", "まみ") == [3, 3]
	OwlCheck s:pos_prev([3, 1], "まみmado", "まみ") == [2, 6]
endfunction



