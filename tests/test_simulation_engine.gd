extends GutTest

const A := Vector2i(2, 4)
const B := Vector2i(7, 4)

var level: LevelData
var grid: GridModel


func before_each():
	level = LevelData.load_from_file("res://levels/level_01.json")
	grid = level.create_grid()


func _build_straight_line():
	grid.connect_cells(A, Vector2i(3, 4))
	grid.connect_cells(Vector2i(3, 4), Vector2i(4, 4))
	grid.connect_cells(Vector2i(4, 4), Vector2i(5, 4))
	grid.connect_cells(Vector2i(5, 4), Vector2i(6, 4))
	grid.connect_cells(Vector2i(6, 4), B)


func test_straight_line_delivers_the_train():
	_build_straight_line()
	var result := SimulationEngine.simulate(grid, level)
	assert_eq(result.outcome, SimulationResult.Outcome.SUCCESS)
	assert_true(result.is_success())


func test_step_log_starts_on_the_source_station_and_ends_on_the_target():
	_build_straight_line()
	var result := SimulationEngine.simulate(grid, level)
	assert_eq(result.steps.size(), 6)
	assert_eq(result.steps[0]["train_1"], A)
	assert_eq(result.steps[5]["train_1"], B)


func test_step_log_walks_every_track_cell_in_order():
	_build_straight_line()
	var result := SimulationEngine.simulate(grid, level)
	var path := result.get_path("train_1")
	assert_eq(path, [A, Vector2i(3, 4), Vector2i(4, 4), Vector2i(5, 4), Vector2i(6, 4), B])


func test_a_detour_is_followed_exactly():
	grid.connect_cells(A, Vector2i(2, 3))
	grid.connect_cells(Vector2i(2, 3), Vector2i(3, 3))
	grid.connect_cells(Vector2i(3, 3), Vector2i(4, 3))
	grid.connect_cells(Vector2i(4, 3), Vector2i(4, 4))
	grid.connect_cells(Vector2i(4, 4), Vector2i(5, 4))
	grid.connect_cells(Vector2i(5, 4), Vector2i(6, 4))
	grid.connect_cells(Vector2i(6, 4), B)
	var result := SimulationEngine.simulate(grid, level)
	assert_eq(result.outcome, SimulationResult.Outcome.SUCCESS)
	assert_eq(result.get_path("train_1"), [
		A, Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3),
		Vector2i(4, 4), Vector2i(5, 4), Vector2i(6, 4), B,
	])


func test_a_station_with_no_track_next_to_it_fails():
	var result := SimulationEngine.simulate(grid, level)
	assert_eq(result.outcome, SimulationResult.Outcome.NO_DEPARTURE)
	assert_eq(result.failed_train_id, "train_1")
	assert_false(result.is_success())


func test_a_track_ending_in_the_middle_fails():
	grid.connect_cells(A, Vector2i(3, 4))
	grid.connect_cells(Vector2i(3, 4), Vector2i(4, 4))
	var result := SimulationEngine.simulate(grid, level)
	assert_eq(result.outcome, SimulationResult.Outcome.DEAD_END)
	assert_eq(result.get_path("train_1"), [A, Vector2i(3, 4), Vector2i(4, 4)])


func test_two_tracks_leaving_the_source_station_is_ambiguous():
	grid.connect_cells(A, Vector2i(3, 4))
	grid.connect_cells(A, Vector2i(2, 3))
	var result := SimulationEngine.simulate(grid, level)
	assert_eq(result.outcome, SimulationResult.Outcome.AMBIGUOUS_DEPARTURE)
	assert_eq(result.get_path("train_1"), [A])


func test_two_tracks_entering_the_target_station_are_fine():
	_build_straight_line()
	grid.connect_cells(Vector2i(7, 3), B)
	var result := SimulationEngine.simulate(grid, level)
	assert_eq(result.outcome, SimulationResult.Outcome.SUCCESS)


func test_arriving_at_a_station_that_is_not_the_target_fails():
	var wrong := LevelData.load_from_file("res://tests/fixtures/level_three_stations.json")
	var wrong_grid := wrong.create_grid()
	wrong_grid.connect_cells(Vector2i(0, 0), Vector2i(1, 0))
	wrong_grid.connect_cells(Vector2i(1, 0), Vector2i(2, 0))
	var result := SimulationEngine.simulate(wrong_grid, wrong)
	assert_eq(result.outcome, SimulationResult.Outcome.WRONG_STATION)
	assert_eq(result.get_path("train_1"), [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])


func test_a_loop_cannot_be_built_while_cells_hold_two_edges():
	grid.connect_cells(A, Vector2i(3, 4))
	grid.connect_cells(Vector2i(3, 4), Vector2i(3, 3))
	grid.connect_cells(Vector2i(3, 3), Vector2i(4, 3))
	grid.connect_cells(Vector2i(4, 3), Vector2i(4, 4))
	assert_false(grid.can_connect_cells(Vector2i(4, 4), Vector2i(3, 4)))
	assert_eq(SimulationEngine.simulate(grid, level).outcome, SimulationResult.Outcome.DEAD_END)


func test_route_walks_a_single_train_to_its_station():
	_build_straight_line()
	var train: Train = level.trains[0]
	assert_eq(SimulationEngine.route(grid, level, train), [
		A, Vector2i(3, 4), Vector2i(4, 4), Vector2i(5, 4), Vector2i(6, 4), B,
	])


func test_route_stops_where_the_track_stops():
	grid.connect_cells(A, Vector2i(3, 4))
	grid.connect_cells(Vector2i(3, 4), Vector2i(4, 4))
	var train: Train = level.trains[0]
	assert_eq(SimulationEngine.route(grid, level, train), [A, Vector2i(3, 4), Vector2i(4, 4)])


func test_route_reaches_the_wrong_station_when_the_track_leads_there():
	var wrong := LevelData.load_from_file("res://tests/fixtures/level_three_stations.json")
	var wrong_grid := wrong.create_grid()
	wrong_grid.connect_cells(Vector2i(0, 0), Vector2i(1, 0))
	wrong_grid.connect_cells(Vector2i(1, 0), Vector2i(2, 0))
	assert_eq(SimulationEngine.route(wrong_grid, wrong, wrong.trains[0]), [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
	])


func test_a_switch_can_trap_a_train_in_a_loop():
	var looping := LevelData.load_from_file("res://tests/fixtures/level_loop.json")
	var loop_grid := looping.create_grid()
	var junction := Vector2i(2, 2)
	loop_grid.connect_cells(junction, Vector2i(2, 1))
	loop_grid.connect_cells(junction, Vector2i(1, 2))
	loop_grid.connect_cells(junction, Vector2i(3, 2))
	for pair in [[[1, 2], [1, 3]], [[1, 3], [2, 3]], [[2, 3], [3, 3]], [[3, 3], [3, 2]]]:
		loop_grid.connect_cells(Vector2i(pair[0][0], pair[0][1]), Vector2i(pair[1][0], pair[1][1]))
	loop_grid.set_switch(junction, TrackPiece.Edge.WEST, TrackPiece.Edge.NORTH)

	var result := SimulationEngine.simulate(loop_grid, looping)
	assert_eq(result.outcome, SimulationResult.Outcome.LOOP)
	assert_eq(result.failed_train_id, "train_1")
