extends GutTest

var level: LevelData
var grid: GridModel


func _load(fixture: String):
	level = LevelData.load_from_file("res://tests/fixtures/%s.json" % fixture)
	grid = level.create_grid()


func test_two_separate_lanes_both_arrive():
	_load("level_two_lanes")
	grid.connect_cells(Vector2i(0, 0), Vector2i(0, 1))
	grid.connect_cells(Vector2i(0, 1), Vector2i(0, 2))
	grid.connect_cells(Vector2i(0, 2), Vector2i(0, 3))
	grid.connect_cells(Vector2i(2, 0), Vector2i(2, 1))
	grid.connect_cells(Vector2i(2, 1), Vector2i(2, 2))
	grid.connect_cells(Vector2i(2, 2), Vector2i(2, 3))
	var result := SimulationEngine.simulate(grid, level)
	assert_eq(result.outcome, SimulationResult.Outcome.SUCCESS)
	assert_eq(result.get_path("train_1"), [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)])
	assert_eq(result.get_path("train_2"), [Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2), Vector2i(2, 3)])


func test_both_trains_move_in_the_same_step():
	_load("level_two_lanes")
	grid.connect_cells(Vector2i(0, 0), Vector2i(0, 1))
	grid.connect_cells(Vector2i(0, 1), Vector2i(0, 2))
	grid.connect_cells(Vector2i(0, 2), Vector2i(0, 3))
	grid.connect_cells(Vector2i(2, 0), Vector2i(2, 1))
	grid.connect_cells(Vector2i(2, 1), Vector2i(2, 2))
	grid.connect_cells(Vector2i(2, 2), Vector2i(2, 3))
	var result := SimulationEngine.simulate(grid, level)
	assert_eq(result.steps[1], {"train_1": Vector2i(0, 1), "train_2": Vector2i(2, 1)})


func test_trains_meeting_on_the_same_cell_collide():
	_load("level_two_lanes")
	grid.connect_cells(Vector2i(0, 0), Vector2i(1, 0))
	grid.connect_cells(Vector2i(1, 0), Vector2i(2, 0))
	var result := SimulationEngine.simulate(grid, level)
	assert_eq(result.outcome, SimulationResult.Outcome.COLLISION)
	assert_eq(result.steps.back()["train_1"], Vector2i(1, 0))
	assert_eq(result.steps.back()["train_2"], Vector2i(1, 0))


func test_trains_swapping_places_collide():
	_load("level_swap")
	grid.connect_cells(Vector2i(0, 0), Vector2i(1, 0))
	grid.connect_cells(Vector2i(1, 0), Vector2i(2, 0))
	grid.connect_cells(Vector2i(2, 0), Vector2i(3, 0))
	var result := SimulationEngine.simulate(grid, level)
	assert_eq(result.outcome, SimulationResult.Outcome.COLLISION)
	assert_eq(result.steps.back()["train_1"], Vector2i(2, 0))
	assert_eq(result.steps.back()["train_2"], Vector2i(1, 0))


func test_a_train_failing_on_its_own_is_reported_before_any_collision():
	_load("level_two_lanes")
	grid.connect_cells(Vector2i(0, 0), Vector2i(0, 1))
	var result := SimulationEngine.simulate(grid, level)
	assert_eq(result.outcome, SimulationResult.Outcome.NO_DEPARTURE)
	assert_eq(result.failed_train_id, "train_2")
