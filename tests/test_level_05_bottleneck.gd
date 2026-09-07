extends GutTest

const N := TrackPiece.Edge.NORTH
const E := TrackPiece.Edge.EAST
const W := TrackPiece.Edge.WEST

const WEST_JUNCTION := Vector2i(3, 5)
const EAST_JUNCTION := Vector2i(7, 5)

const MAIN_LINE := [[0, 5], [1, 5], [2, 5], [3, 5], [4, 5], [5, 5], [6, 5], [7, 5], [8, 5], [9, 5]]
const APPROACH := [[9, 3], [9, 2], [8, 2], [8, 1], [7, 1], [7, 2], [7, 3], [7, 4], [7, 5]]
const EXIT := [[3, 5], [3, 4], [2, 4], [2, 3], [1, 3], [0, 3]]

var level: LevelData
var grid: GridModel


func before_each():
	level = LevelData.load_from_file("res://levels/level_05_bottleneck.json")
	grid = level.create_grid()


func _lay(path: Array) -> void:
	for i in range(path.size() - 1):
		var from := Vector2i(path[i][0], path[i][1])
		var to := Vector2i(path[i + 1][0], path[i + 1][1])
		assert_true(grid.connect_cells(from, to), "%s -> %s" % [from, to])


func _build_solution() -> void:
	_lay(MAIN_LINE)
	_lay(APPROACH)
	_lay(EXIT)
	grid.set_switch(WEST_JUNCTION, E, N)
	grid.set_switch(EAST_JUNCTION, W, E)


func test_the_level_unlocks_the_switch():
	assert_eq(level.available_tools, ["switch"])
	assert_eq(grid.max_edges_per_cell, 3)


func test_the_intended_solution_fits_the_budget():
	_build_solution()
	assert_eq(grid.get_used_budget(), 19)
	assert_true(grid.get_used_budget() <= level.segment_budget)


func test_both_junctions_are_switches():
	_build_solution()
	assert_eq(grid.get_switch(WEST_JUNCTION), {"toe": E, "setting": N})
	assert_eq(grid.get_switch(EAST_JUNCTION), {"toe": W, "setting": E})


func test_the_intended_solution_delivers_both_trains():
	_build_solution()
	var result := SimulationEngine.simulate(grid, level)
	assert_eq(result.outcome, SimulationResult.Outcome.SUCCESS)


func test_the_detour_is_what_keeps_the_trains_apart():
	_build_solution()
	var result := SimulationEngine.simulate(grid, level)
	assert_eq(result.steps[7]["train_1"], Vector2i(7, 5))
	assert_eq(result.steps[7]["train_2"], Vector2i(7, 4))
	assert_eq(result.steps[8]["train_1"], Vector2i(8, 5))
	assert_eq(result.steps[8]["train_2"], Vector2i(7, 5))


func test_without_the_detour_the_trains_collide_in_the_corridor():
	_lay(MAIN_LINE)
	_lay([[9, 3], [8, 3], [7, 3], [7, 4], [7, 5]])
	_lay(EXIT)
	grid.set_switch(WEST_JUNCTION, E, N)
	grid.set_switch(EAST_JUNCTION, W, E)
	var result := SimulationEngine.simulate(grid, level)
	assert_eq(result.outcome, SimulationResult.Outcome.COLLISION)


func test_the_author_layout_also_works():
	_lay(MAIN_LINE)
	_lay([[3, 5], [3, 4], [3, 3], [2, 3], [1, 3], [0, 3]])
	_lay([[9, 3], [9, 2], [9, 1], [9, 0], [8, 0], [7, 0], [7, 1], [7, 2], [7, 3], [7, 4], [7, 5]])
	grid.set_switch(Vector2i(3, 5), E, N)
	grid.set_switch(EAST_JUNCTION, W, E)
	assert_eq(grid.get_used_budget(), 21)
	var result := SimulationEngine.simulate(grid, level)
	assert_eq(result.outcome, SimulationResult.Outcome.SUCCESS)


func test_the_author_layout_fails_with_the_toe_on_the_wrong_arm():
	_lay(MAIN_LINE)
	_lay([[3, 5], [3, 4], [3, 3], [2, 3], [1, 3], [0, 3]])
	_lay([[9, 3], [9, 2], [9, 1], [9, 0], [8, 0], [7, 0], [7, 1], [7, 2], [7, 3], [7, 4], [7, 5]])
	grid.set_switch(Vector2i(3, 5), N, E)
	grid.set_switch(EAST_JUNCTION, N, E)
	var result := SimulationEngine.simulate(grid, level)
	assert_eq(result.outcome, SimulationResult.Outcome.WRONG_STATION)


func test_route_preview_ignores_the_other_train():
	_lay(MAIN_LINE)
	_lay([[9, 3], [8, 3], [7, 3], [7, 4], [7, 5]])
	_lay(EXIT)
	grid.set_switch(WEST_JUNCTION, E, N)
	grid.set_switch(EAST_JUNCTION, W, E)

	assert_eq(SimulationEngine.simulate(grid, level).outcome, SimulationResult.Outcome.COLLISION)
	assert_eq(SimulationEngine.route(grid, level, level.trains[0]).back(), Vector2i(9, 5))
	assert_eq(SimulationEngine.route(grid, level, level.trains[1]).back(), Vector2i(0, 3))
