extends GutTest

const N := TrackPiece.Edge.NORTH
const E := TrackPiece.Edge.EAST
const S := TrackPiece.Edge.SOUTH
const W := TrackPiece.Edge.WEST

const JUNCTION := Vector2i(3, 5)

var grid: GridModel


func before_each():
	grid = GridModel.new(10, 10, 99)
	grid.max_edges_per_cell = 3


func _build_junction():
	grid.connect_cells(JUNCTION, Vector2i(2, 5))
	grid.connect_cells(JUNCTION, Vector2i(4, 5))
	grid.connect_cells(JUNCTION, Vector2i(3, 4))


func test_a_third_edge_needs_the_switch_limit():
	var plain := GridModel.new(10, 10, 99)
	plain.connect_cells(JUNCTION, Vector2i(2, 5))
	plain.connect_cells(JUNCTION, Vector2i(4, 5))
	assert_false(plain.can_connect_cells(JUNCTION, Vector2i(3, 4)))
	_build_junction()
	assert_eq(grid.get_edges(JUNCTION), grid.edge_bit(N) | grid.edge_bit(E) | grid.edge_bit(W))


func test_a_fourth_edge_is_still_refused():
	_build_junction()
	assert_false(grid.can_connect_cells(JUNCTION, Vector2i(3, 6)))


func test_exit_edge_on_a_straight_piece():
	grid.connect_cells(JUNCTION, Vector2i(2, 5))
	grid.connect_cells(JUNCTION, Vector2i(4, 5))
	assert_eq(grid.exit_edge(JUNCTION, W), E)
	assert_eq(grid.exit_edge(JUNCTION, E), W)


func test_exit_edge_is_minus_one_for_a_dead_end_and_for_an_absent_edge():
	grid.connect_cells(JUNCTION, Vector2i(2, 5))
	assert_eq(grid.exit_edge(JUNCTION, W), -1)
	assert_eq(grid.exit_edge(Vector2i(0, 0), N), -1)


func test_a_switch_sends_branches_to_the_toe_and_the_toe_to_the_setting():
	_build_junction()
	grid.set_switch(JUNCTION, E, N)
	assert_eq(grid.exit_edge(JUNCTION, E), N)
	assert_eq(grid.exit_edge(JUNCTION, W), E)
	assert_eq(grid.exit_edge(JUNCTION, N), E)


func test_the_same_shape_can_be_configured_the_other_way():
	_build_junction()
	grid.set_switch(JUNCTION, W, E)
	assert_eq(grid.exit_edge(JUNCTION, W), E)
	assert_eq(grid.exit_edge(JUNCTION, N), W)
	assert_eq(grid.exit_edge(JUNCTION, E), W)


func test_get_switch_reports_the_configuration():
	_build_junction()
	grid.set_switch(JUNCTION, E, N)
	assert_eq(grid.get_switch(JUNCTION), {"toe": E, "setting": N})


func test_get_switch_is_empty_when_the_cell_is_not_a_switch():
	grid.connect_cells(JUNCTION, Vector2i(2, 5))
	grid.connect_cells(JUNCTION, Vector2i(4, 5))
	assert_eq(grid.get_switch(JUNCTION), {})


func test_cycling_visits_every_configuration_and_wraps():
	_build_junction()
	var seen := []
	for i in 6:
		seen.append(grid.get_switch(JUNCTION))
		grid.cycle_switch(JUNCTION)
	assert_eq(seen.size(), 6)
	for config in seen:
		assert_eq(seen.count(config), 1, "%s should appear once" % config)
	assert_eq(grid.get_switch(JUNCTION), seen[0])


func test_cycling_announces_the_change():
	_build_junction()
	watch_signals(grid)
	grid.cycle_switch(JUNCTION)
	assert_signal_emitted_with_parameters(grid, "track_changed", [JUNCTION], 0)


func test_cycling_a_cell_that_is_not_a_switch_does_nothing():
	watch_signals(grid)
	grid.cycle_switch(JUNCTION)
	assert_signal_not_emitted(grid, "track_changed")


func test_removing_a_switch_forgets_its_configuration():
	_build_junction()
	grid.set_switch(JUNCTION, E, N)
	grid.remove_track(JUNCTION)
	_build_junction()
	assert_eq(grid.get_switch(JUNCTION), grid.get_switch_configs(JUNCTION)[0])
