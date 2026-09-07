extends GutTest

var grid: GridModel


func before_each():
	grid = GridModel.new(10, 10, 3)


func test_new_grid_uses_no_budget():
	assert_eq(grid.get_used_budget(), 0)
	assert_eq(grid.get_budget_remaining(), 3)


func test_first_connection_costs_two_cells():
	grid.connect_cells(Vector2i(0, 0), Vector2i(0, 1))
	assert_eq(grid.get_used_budget(), 2)
	assert_eq(grid.get_budget_remaining(), 1)


func test_extending_an_existing_track_costs_one_cell():
	grid.connect_cells(Vector2i(0, 0), Vector2i(0, 1))
	grid.connect_cells(Vector2i(0, 1), Vector2i(0, 2))
	assert_eq(grid.get_used_budget(), 3)
	assert_eq(grid.get_budget_remaining(), 0)


func test_closing_a_loop_between_two_existing_cells_is_free():
	var loop_grid := GridModel.new(10, 10, 4)
	loop_grid.connect_cells(Vector2i(0, 0), Vector2i(1, 0))
	loop_grid.connect_cells(Vector2i(0, 0), Vector2i(0, 1))
	loop_grid.connect_cells(Vector2i(1, 0), Vector2i(1, 1))
	assert_eq(loop_grid.get_used_budget(), 4)
	assert_true(loop_grid.connect_cells(Vector2i(0, 1), Vector2i(1, 1)))
	assert_eq(loop_grid.get_used_budget(), 4)


func test_connection_is_rejected_when_budget_is_too_small():
	grid.connect_cells(Vector2i(0, 0), Vector2i(0, 1))
	grid.connect_cells(Vector2i(0, 1), Vector2i(0, 2))
	assert_false(grid.can_connect_cells(Vector2i(0, 2), Vector2i(0, 3)))
	assert_false(grid.connect_cells(Vector2i(0, 2), Vector2i(0, 3)))
	assert_false(grid.has_track(Vector2i(0, 3)))


func test_a_single_connection_needing_two_cells_is_rejected_with_one_left():
	grid.connect_cells(Vector2i(0, 0), Vector2i(0, 1))
	assert_eq(grid.get_budget_remaining(), 1)
	assert_false(grid.can_connect_cells(Vector2i(5, 5), Vector2i(5, 6)))


func test_removing_track_frees_budget():
	grid.connect_cells(Vector2i(0, 0), Vector2i(0, 1))
	grid.connect_cells(Vector2i(0, 1), Vector2i(0, 2))
	grid.remove_track(Vector2i(0, 0))
	assert_eq(grid.get_used_budget(), 2)
	assert_eq(grid.get_budget_remaining(), 1)


func test_removing_a_middle_cell_frees_only_that_cell():
	var line := _straight_line(5)
	line.remove_track(Vector2i(0, 2))
	assert_eq(line.get_used_budget(), 4)
	assert_true(line.has_track(Vector2i(0, 1)))
	assert_true(line.has_track(Vector2i(0, 3)))


func test_removing_a_cell_also_clears_neighbours_left_without_connections():
	grid.connect_cells(Vector2i(0, 0), Vector2i(0, 1))
	grid.remove_track(Vector2i(0, 0))
	assert_eq(grid.get_used_budget(), 0)
	assert_false(grid.has_track(Vector2i(0, 1)))


func _straight_line(length: int) -> GridModel:
	var line := GridModel.new(10, 10, length)
	for y in range(length - 1):
		line.connect_cells(Vector2i(0, y), Vector2i(0, y + 1))
	return line


func test_track_changed_fires_for_both_cells_of_a_connection():
	watch_signals(grid)
	grid.connect_cells(Vector2i(0, 0), Vector2i(0, 1))
	assert_signal_emitted_with_parameters(grid, "track_changed", [Vector2i(0, 0)], 0)
	assert_signal_emitted_with_parameters(grid, "track_changed", [Vector2i(0, 1)], 1)


func test_track_changed_fires_when_a_cell_only_changes_shape():
	grid.connect_cells(Vector2i(0, 0), Vector2i(0, 1))
	watch_signals(grid)
	grid.connect_cells(Vector2i(0, 1), Vector2i(1, 1))
	assert_signal_emit_count(grid, "track_changed", 2)


func test_track_changed_fires_for_removed_cell_and_its_neighbour():
	grid.connect_cells(Vector2i(0, 0), Vector2i(0, 1))
	watch_signals(grid)
	grid.remove_track(Vector2i(0, 1))
	assert_signal_emit_count(grid, "track_changed", 2)


func test_track_changed_does_not_fire_on_a_rejected_connection():
	watch_signals(grid)
	grid.connect_cells(Vector2i(0, 0), Vector2i(5, 5))
	assert_signal_not_emitted(grid, "track_changed")


func test_track_changed_does_not_fire_on_removing_empty_cell():
	watch_signals(grid)
	grid.remove_track(Vector2i(7, 7))
	assert_signal_not_emitted(grid, "track_changed")


func test_connecting_to_a_station_costs_only_the_track_cell():
	grid.add_station(Station.new("A", Vector2i(2, 2), "red", Station.Role.SOURCE))
	grid.connect_cells(Vector2i(2, 1), Vector2i(2, 2))
	assert_eq(grid.get_used_budget(), 1)
	assert_eq(grid.get_budget_remaining(), 2)
