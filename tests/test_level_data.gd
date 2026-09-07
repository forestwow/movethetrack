extends GutTest

const LEVEL_01 := "res://levels/level_01.json"
const FULL := "res://tests/fixtures/level_with_everything.json"


func test_loads_level_01():
	var level := LevelData.load_from_file(LEVEL_01)
	assert_not_null(level)
	assert_eq(level.id, "level_01")
	assert_eq(level.segment_budget, 6)
	assert_eq(level.stations.size(), 2)
	assert_eq(level.trains.size(), 1)
	assert_eq(level.obstacles.size(), 0)
	assert_eq(level.win_conditions, ["basic_delivery"])
	assert_eq(level.available_tools, [])
	assert_eq(level.bonus_min_segments, -1)


func test_parses_station_fields():
	var level := LevelData.load_from_file(LEVEL_01)
	var station := level.get_station("A")
	assert_not_null(station)
	assert_eq(station.cell, Vector2i(2, 4))
	assert_eq(station.color, "red")
	assert_eq(station.role, Station.Role.SOURCE)
	assert_eq(level.get_station("B").role, Station.Role.DESTINATION)


func test_get_station_returns_null_for_unknown_id():
	var level := LevelData.load_from_file(LEVEL_01)
	assert_null(level.get_station("nope"))


func test_train_takes_its_colour_from_the_source_station():
	var level := LevelData.load_from_file(FULL)
	assert_eq(level.trains[0].color, "red")
	assert_eq(level.trains[1].color, "blue")


func test_parses_train_references():
	var level := LevelData.load_from_file(LEVEL_01)
	var train := level.trains[0]
	assert_eq(train.id, "train_1")
	assert_eq(train.start_station_id, "A")
	assert_eq(train.target_station_id, "B")


func test_parses_obstacles_tools_and_bonus():
	var level := LevelData.load_from_file(FULL)
	assert_eq(level.obstacles, [Vector2i(4, 4), Vector2i(4, 5)])
	assert_eq(level.available_tools, ["crossing", "switch"])
	assert_eq(level.win_conditions, ["basic_delivery", "color_match"])
	assert_eq(level.bonus_min_segments, 12)


func test_create_grid_carries_size_budget_obstacles_and_stations():
	var level := LevelData.load_from_file(FULL)
	var grid := level.create_grid()
	assert_eq(grid.width, LevelData.GRID_WIDTH)
	assert_eq(grid.height, LevelData.GRID_HEIGHT)
	assert_eq(grid.segment_budget, 14)
	assert_true(grid.is_blocked(Vector2i(4, 4)))
	assert_true(grid.is_blocked(Vector2i(0, 0)))
	assert_false(grid.is_blocked(Vector2i(5, 5)))
	assert_eq(grid.get_station(Vector2i(9, 9)).id, "D")


func test_create_grid_returns_a_fresh_grid_each_time():
	var level := LevelData.load_from_file(LEVEL_01)
	var first := level.create_grid()
	first.connect_cells(Vector2i(3, 4), Vector2i(4, 4))
	assert_false(level.create_grid().has_track(Vector2i(3, 4)))
