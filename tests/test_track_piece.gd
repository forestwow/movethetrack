extends GutTest


func test_stores_both_edges():
	var piece := TrackPiece.new(TrackPiece.Edge.NORTH, TrackPiece.Edge.SOUTH)
	assert_eq(piece.edge_a, TrackPiece.Edge.NORTH)
	assert_eq(piece.edge_b, TrackPiece.Edge.SOUTH)


func test_connects_reports_its_own_edges():
	var piece := TrackPiece.new(TrackPiece.Edge.NORTH, TrackPiece.Edge.EAST)
	assert_true(piece.connects(TrackPiece.Edge.NORTH))
	assert_true(piece.connects(TrackPiece.Edge.EAST))
	assert_false(piece.connects(TrackPiece.Edge.SOUTH))
	assert_false(piece.connects(TrackPiece.Edge.WEST))


func test_other_edge_returns_the_opposite_end_of_the_piece():
	var piece := TrackPiece.new(TrackPiece.Edge.NORTH, TrackPiece.Edge.EAST)
	assert_eq(piece.other_edge(TrackPiece.Edge.NORTH), TrackPiece.Edge.EAST)
	assert_eq(piece.other_edge(TrackPiece.Edge.EAST), TrackPiece.Edge.NORTH)


func test_other_edge_returns_minus_one_for_unconnected_edge():
	var piece := TrackPiece.new(TrackPiece.Edge.NORTH, TrackPiece.Edge.EAST)
	assert_eq(piece.other_edge(TrackPiece.Edge.SOUTH), -1)


func test_same_edge_twice_is_not_a_valid_pair():
	assert_false(TrackPiece.is_valid_pair(TrackPiece.Edge.NORTH, TrackPiece.Edge.NORTH))
	assert_true(TrackPiece.is_valid_pair(TrackPiece.Edge.NORTH, TrackPiece.Edge.SOUTH))


func test_opposite_edge():
	assert_eq(TrackPiece.opposite(TrackPiece.Edge.NORTH), TrackPiece.Edge.SOUTH)
	assert_eq(TrackPiece.opposite(TrackPiece.Edge.SOUTH), TrackPiece.Edge.NORTH)
	assert_eq(TrackPiece.opposite(TrackPiece.Edge.EAST), TrackPiece.Edge.WEST)
	assert_eq(TrackPiece.opposite(TrackPiece.Edge.WEST), TrackPiece.Edge.EAST)


func test_direction_of_each_edge():
	assert_eq(TrackPiece.direction(TrackPiece.Edge.NORTH), Vector2i(0, -1))
	assert_eq(TrackPiece.direction(TrackPiece.Edge.EAST), Vector2i(1, 0))
	assert_eq(TrackPiece.direction(TrackPiece.Edge.SOUTH), Vector2i(0, 1))
	assert_eq(TrackPiece.direction(TrackPiece.Edge.WEST), Vector2i(-1, 0))
