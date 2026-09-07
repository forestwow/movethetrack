extends GutTest

const SOLUTIONS := {
	"level_01": {
		"train_1": [[2, 4], [3, 4], [4, 4], [5, 4], [6, 4], [7, 4]],
	},
	"level_02": {
		"train_1": [[2, 2], [3, 2], [4, 2], [5, 2], [6, 2], [6, 3], [6, 4], [6, 5], [6, 6]],
	},
	"level_03": {
		"train_1": [[1, 4], [2, 4], [3, 4], [3, 3], [3, 2], [4, 2], [5, 2], [5, 3], [5, 4], [6, 4], [7, 4], [8, 4]],
	},
	"level_04": {
		"train_1": [[0, 4], [1, 4], [2, 4], [3, 4], [3, 3], [4, 3], [5, 3], [5, 4], [6, 4], [7, 4], [8, 4], [9, 4]],
		"train_2": [[0, 5], [1, 5], [2, 5], [3, 5], [4, 5], [5, 5], [5, 6], [6, 6], [7, 6], [7, 5], [8, 5], [9, 5]],
	},
}


func test_every_level_is_solvable_within_its_budget():
	for level_id in SOLUTIONS:
		var level := LevelData.load_from_file("res://levels/%s.json" % level_id)
		assert_not_null(level, "%s should load" % level_id)
		var grid := level.create_grid()

		for train_id in SOLUTIONS[level_id]:
			var path: Array = SOLUTIONS[level_id][train_id]
			for i in range(path.size() - 1):
				var from := Vector2i(path[i][0], path[i][1])
				var to := Vector2i(path[i + 1][0], path[i + 1][1])
				assert_true(grid.connect_cells(from, to), "%s: %s -> %s" % [level_id, from, to])

		assert_true(grid.get_used_budget() <= level.segment_budget, "%s fits its budget" % level_id)

		var result := SimulationEngine.simulate(grid, level)
		assert_eq(result.outcome, SimulationResult.Outcome.SUCCESS, "%s should be solvable" % level_id)
		for train_id in SOLUTIONS[level_id]:
			var expected: Array[Vector2i] = []
			for point in SOLUTIONS[level_id][train_id]:
				expected.append(Vector2i(point[0], point[1]))
			assert_eq(result.get_path(train_id), expected, "%s / %s route" % [level_id, train_id])
