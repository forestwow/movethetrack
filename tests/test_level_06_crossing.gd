extends GutTest

const CROSSING := Vector2i(4, 4)

const BLUE_LINE := [[4,0],[4,1],[4,2],[4,3],[4,4],[4,5],[4,6],[4,7],[4,8],[4,9]]
const RED_STRAIGHT := [[0,4],[1,4],[2,4],[3,4],[4,4],[5,4],[6,4],[7,4],[8,4],[9,4]]
const RED_DETOUR := [[0,4],[1,4],[1,3],[2,3],[2,4],[3,4],[4,4],[5,4],[6,4],[7,4],[8,4],[9,4]]

var level: LevelData
var grid: GridModel


func before_each():
	level = LevelData.load_from_file("res://levels/level_06_crossing.json")
	grid = level.create_grid()


func _lay(path: Array) -> void:
	for i in range(path.size() - 1):
		var from := Vector2i(path[i][0], path[i][1])
		var to := Vector2i(path[i + 1][0], path[i + 1][1])
		assert_true(grid.connect_cells(from, to), "%s -> %s" % [from, to])


func test_the_level_unlocks_the_crossing():
	assert_eq(grid.max_edges_per_cell, 4)


func test_the_two_lines_share_one_cell_as_a_crossing():
	_lay(RED_STRAIGHT)
	_lay(BLUE_LINE)
	assert_eq(grid.get_edges(CROSSING), 0b1111)
	assert_eq(grid.get_switch(CROSSING), {})


func test_the_shortest_layout_collides_on_the_crossing():
	_lay(RED_STRAIGHT)
	_lay(BLUE_LINE)
	var result := SimulationEngine.simulate(grid, level)
	assert_eq(result.outcome, SimulationResult.Outcome.COLLISION)
	assert_eq(result.steps[4]["train_1"], CROSSING)
	assert_eq(result.steps[4]["train_2"], CROSSING)


func test_a_detour_lets_the_blue_train_clear_the_crossing_first():
	_lay(RED_DETOUR)
	_lay(BLUE_LINE)
	assert_eq(grid.get_used_budget(), 17)
	assert_true(grid.get_used_budget() <= level.segment_budget)
	var result := SimulationEngine.simulate(grid, level)
	assert_eq(result.outcome, SimulationResult.Outcome.SUCCESS)
	assert_eq(result.steps[4]["train_2"], CROSSING)
	assert_eq(result.steps[6]["train_1"], CROSSING)


func test_each_train_still_runs_straight_through_the_crossing():
	_lay(RED_DETOUR)
	_lay(BLUE_LINE)
	assert_eq(SimulationEngine.route(grid, level, level.trains[0]).back(), Vector2i(9, 4))
	assert_eq(SimulationEngine.route(grid, level, level.trains[1]).back(), Vector2i(4, 9))
