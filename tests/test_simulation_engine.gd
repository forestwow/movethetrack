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
