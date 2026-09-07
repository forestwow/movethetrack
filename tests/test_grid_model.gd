extends GutTest

const N := TrackPiece.Edge.NORTH
const E := TrackPiece.Edge.EAST
const S := TrackPiece.Edge.SOUTH
const W := TrackPiece.Edge.WEST

var grid: GridModel


func before_each():
	grid = GridModel.new(10, 10, 99)


func test_new_grid_has_no_track():
	assert_false(grid.has_track(Vector2i(0, 0)))
	assert_eq(grid.get_edges(Vector2i(0, 0)), 0)


func test_connect_marks_both_cells_with_mirrored_edges():
	assert_true(grid.connect_cells(Vector2i(3, 3), Vector2i(3, 4)))
	assert_eq(grid.get_edges(Vector2i(3, 3)), grid.edge_bit(S))
	assert_eq(grid.get_edges(Vector2i(3, 4)), grid.edge_bit(N))


func test_connect_rejects_non_adjacent_cells():
	assert_false(grid.can_connect_cells(Vector2i(0, 0), Vector2i(2, 0)))
	assert_false(grid.can_connect_cells(Vector2i(0, 0), Vector2i(1, 1)))
	assert_false(grid.connect_cells(Vector2i(0, 0), Vector2i(2, 0)))
	assert_false(grid.has_track(Vector2i(0, 0)))


func test_connect_rejects_cell_outside_the_grid():
	assert_false(grid.can_connect_cells(Vector2i(0, 0), Vector2i(-1, 0)))
	assert_false(grid.can_connect_cells(Vector2i(9, 9), Vector2i(10, 9)))


func test_connect_rejects_obstacle_cell():
	grid.add_obstacle(Vector2i(5, 5))
	assert_false(grid.can_connect_cells(Vector2i(5, 4), Vector2i(5, 5)))
	assert_false(grid.can_connect_cells(Vector2i(5, 5), Vector2i(5, 6)))


func test_connecting_to_a_station_only_marks_the_track_cell():
	grid.add_station(Station.new("A", Vector2i(2, 2), "red", Station.Role.SOURCE))
	assert_true(grid.connect_cells(Vector2i(2, 1), Vector2i(2, 2)))
	assert_eq(grid.get_edges(Vector2i(2, 1)), grid.edge_bit(S))
	assert_false(grid.has_track(Vector2i(2, 2)))


func test_a_station_still_cannot_hold_track():
	grid.add_station(Station.new("A", Vector2i(2, 2), "red", Station.Role.SOURCE))
	grid.connect_cells(Vector2i(2, 1), Vector2i(2, 2))
	grid.connect_cells(Vector2i(2, 2), Vector2i(2, 3))
	assert_false(grid.has_track(Vector2i(2, 2)))
	assert_eq(grid.get_edges(Vector2i(2, 3)), grid.edge_bit(N))


func test_connect_rejects_two_stations():
	grid.add_station(Station.new("A", Vector2i(2, 2), "red", Station.Role.SOURCE))
	grid.add_station(Station.new("B", Vector2i(2, 3), "red", Station.Role.DESTINATION))
	assert_false(grid.can_connect_cells(Vector2i(2, 2), Vector2i(2, 3)))


func test_connect_rejects_a_repeated_station_connection():
	grid.add_station(Station.new("A", Vector2i(2, 2), "red", Station.Role.SOURCE))
	grid.connect_cells(Vector2i(2, 1), Vector2i(2, 2))
	assert_false(grid.can_connect_cells(Vector2i(2, 1), Vector2i(2, 2)))
	assert_false(grid.can_connect_cells(Vector2i(2, 2), Vector2i(2, 1)))


func test_station_exits_list_neighbouring_track_facing_the_station():
	grid.add_station(Station.new("A", Vector2i(2, 2), "red", Station.Role.SOURCE))
	assert_eq(grid.get_station_exits(Vector2i(2, 2)), [])
	grid.connect_cells(Vector2i(2, 1), Vector2i(2, 2))
	grid.connect_cells(Vector2i(3, 2), Vector2i(2, 2))
	assert_eq(grid.get_station_exits(Vector2i(2, 2)), [Vector2i(2, 1), Vector2i(3, 2)])


func test_station_exits_ignore_neighbouring_track_that_does_not_face_it():
	grid.add_station(Station.new("A", Vector2i(2, 2), "red", Station.Role.SOURCE))
	grid.connect_cells(Vector2i(2, 1), Vector2i(1, 1))
	assert_eq(grid.get_station_exits(Vector2i(2, 2)), [])


func test_removing_track_next_to_a_station_clears_the_station_exit():
	grid.add_station(Station.new("A", Vector2i(2, 2), "red", Station.Role.SOURCE))
	grid.connect_cells(Vector2i(2, 1), Vector2i(2, 2))
	grid.connect_cells(Vector2i(2, 1), Vector2i(2, 0))
	grid.remove_track(Vector2i(2, 1))
	assert_eq(grid.get_station_exits(Vector2i(2, 2)), [])


func test_connect_rejects_an_existing_connection():
	grid.connect_cells(Vector2i(3, 3), Vector2i(3, 4))
	assert_false(grid.can_connect_cells(Vector2i(3, 3), Vector2i(3, 4)))
	assert_false(grid.can_connect_cells(Vector2i(3, 4), Vector2i(3, 3)))


func test_cell_cannot_hold_more_than_two_edges():
	grid.connect_cells(Vector2i(3, 3), Vector2i(2, 3))
	grid.connect_cells(Vector2i(3, 3), Vector2i(4, 3))
	assert_false(grid.can_connect_cells(Vector2i(3, 3), Vector2i(3, 4)))
	assert_false(grid.connect_cells(Vector2i(3, 3), Vector2i(3, 4)))
	assert_false(grid.has_track(Vector2i(3, 4)))


func test_dead_end_is_a_valid_state():
	grid.connect_cells(Vector2i(3, 3), Vector2i(3, 4))
	assert_true(grid.has_track(Vector2i(3, 4)))
	assert_null(grid.get_piece(Vector2i(3, 4)))


func test_get_piece_returns_a_track_piece_for_two_edges():
	grid.connect_cells(Vector2i(3, 3), Vector2i(3, 4))
	grid.connect_cells(Vector2i(3, 4), Vector2i(4, 4))
	var piece := grid.get_piece(Vector2i(3, 4))
	assert_not_null(piece)
	assert_true(piece.connects(N))
	assert_true(piece.connects(E))


func test_get_piece_returns_null_for_empty_cell():
	assert_null(grid.get_piece(Vector2i(0, 0)))


func test_remove_track_clears_the_cell_and_the_neighbour_edge():
	grid.connect_cells(Vector2i(3, 3), Vector2i(3, 4))
	grid.connect_cells(Vector2i(3, 4), Vector2i(4, 4))
	grid.remove_track(Vector2i(3, 4))
	assert_false(grid.has_track(Vector2i(3, 4)))
	assert_eq(grid.get_edges(Vector2i(3, 3)), 0)
	assert_eq(grid.get_edges(Vector2i(4, 4)), 0)


func test_remove_track_leaves_unrelated_track_alone():
	grid.connect_cells(Vector2i(0, 0), Vector2i(0, 1))
	grid.connect_cells(Vector2i(5, 5), Vector2i(5, 6))
	grid.remove_track(Vector2i(0, 0))
	assert_true(grid.has_track(Vector2i(5, 5)))
	assert_true(grid.has_track(Vector2i(5, 6)))


func test_remove_track_on_empty_cell_does_nothing():
	grid.remove_track(Vector2i(7, 7))
	assert_false(grid.has_track(Vector2i(7, 7)))


func test_lists_its_stations_obstacles_and_track_cells():
	grid.add_station(Station.new("A", Vector2i(1, 1), "red", Station.Role.SOURCE))
	grid.add_obstacle(Vector2i(5, 5))
	grid.connect_cells(Vector2i(8, 8), Vector2i(8, 9))
	assert_eq(grid.get_stations().size(), 1)
	assert_eq(grid.get_obstacles(), [Vector2i(5, 5)])
	assert_eq(grid.get_track_cells(), [Vector2i(8, 8), Vector2i(8, 9)])
