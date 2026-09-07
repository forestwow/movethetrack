extends GutTest

const N := TrackPiece.Edge.NORTH
const E := TrackPiece.Edge.EAST
const S := TrackPiece.Edge.SOUTH
const W := TrackPiece.Edge.WEST

const CROSSING := Vector2i(4, 4)

var grid: GridModel


func before_each():
	grid = GridModel.new(10, 10, 99)
	grid.max_edges_per_cell = 4


func _build_crossing():
	for neighbour in [Vector2i(3, 4), Vector2i(5, 4), Vector2i(4, 3), Vector2i(4, 5)]:
		grid.connect_cells(CROSSING, neighbour)


func test_a_fourth_edge_needs_the_crossing_limit():
	var switch_grid := GridModel.new(10, 10, 99)
	switch_grid.max_edges_per_cell = 3
	for neighbour in [Vector2i(3, 4), Vector2i(5, 4), Vector2i(4, 3)]:
		switch_grid.connect_cells(CROSSING, neighbour)
	assert_false(switch_grid.can_connect_cells(CROSSING, Vector2i(4, 5)))
	_build_crossing()
	assert_eq(grid.get_edges(CROSSING), 0b1111)


func test_a_crossing_always_sends_a_train_straight_through():
	_build_crossing()
	assert_eq(grid.exit_edge(CROSSING, W), E)
	assert_eq(grid.exit_edge(CROSSING, E), W)
	assert_eq(grid.exit_edge(CROSSING, N), S)
	assert_eq(grid.exit_edge(CROSSING, S), N)


func test_a_crossing_has_nothing_to_configure():
	_build_crossing()
	assert_eq(grid.get_switch(CROSSING), {})
	assert_eq(grid.get_switch_configs(CROSSING), [])


func test_cycling_a_crossing_does_nothing():
	_build_crossing()
	watch_signals(grid)
	grid.cycle_switch(CROSSING)
	assert_signal_not_emitted(grid, "track_changed")
