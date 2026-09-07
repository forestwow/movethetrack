extends GutTest

const VALID := {
	"id": "test_level",
	"segment_budget": 6,
	"obstacles": [],
	"stations": [
		{ "id": "A", "x": 2, "y": 4, "color": "red", "role": "source" },
		{ "id": "B", "x": 7, "y": 4, "color": "red", "role": "destination" },
	],
	"trains": [
		{ "id": "train_1", "start_station": "A", "target_station": "B" },
	],
	"available_tools": [],
	"win_conditions": ["basic_delivery"],
}

var _paths: Array[String] = []


func after_each():
	for path in _paths:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_paths.clear()


func _write_level(overrides: Dictionary) -> String:
	var data := VALID.duplicate(true)
	data.merge(overrides, true)
	var path := "user://level_%d.json" % _paths.size()
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	_paths.append(path)
	return path


func _assert_rejected(overrides: Dictionary, reason: String) -> void:
	assert_null(LevelData.load_from_file(_write_level(overrides)))
	assert_push_error(reason)


func test_the_unmodified_fixture_is_valid():
	assert_not_null(LevelData.load_from_file(_write_level({})))


func test_missing_file_returns_null():
	assert_null(LevelData.load_from_file("res://levels/does_not_exist.json"))
	assert_push_error("cannot read")


func test_malformed_json_returns_null():
	var path := "user://broken.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{ not json")
	file.close()
	_paths.append(path)
	assert_null(LevelData.load_from_file(path))
	assert_push_error("not valid JSON")


func test_missing_id_returns_null():
	_assert_rejected({"id": ""}, "missing id")


func test_non_positive_budget_returns_null():
	_assert_rejected({"segment_budget": 0}, "segment_budget must be positive")


func test_no_stations_returns_null():
	_assert_rejected({"stations": []}, "no stations")


func test_no_trains_returns_null():
	_assert_rejected({"trains": []}, "no trains")


func test_duplicate_station_id_returns_null():
	_assert_rejected({"stations": [
		{ "id": "A", "x": 2, "y": 4, "color": "red", "role": "source" },
		{ "id": "A", "x": 7, "y": 4, "color": "red", "role": "destination" },
	]}, "duplicate station id A")


func test_two_stations_on_the_same_cell_returns_null():
	_assert_rejected({"stations": [
		{ "id": "A", "x": 2, "y": 4, "color": "red", "role": "source" },
		{ "id": "B", "x": 2, "y": 4, "color": "red", "role": "destination" },
	]}, "share cell")


func test_station_outside_the_grid_returns_null():
	_assert_rejected({"stations": [
		{ "id": "A", "x": 2, "y": 4, "color": "red", "role": "source" },
		{ "id": "B", "x": 10, "y": 4, "color": "red", "role": "destination" },
	]}, "outside the grid")


func test_unknown_station_role_returns_null():
	_assert_rejected({"stations": [
		{ "id": "A", "x": 2, "y": 4, "color": "red", "role": "depot" },
		{ "id": "B", "x": 7, "y": 4, "color": "red", "role": "destination" },
	]}, "unknown role depot")


func test_obstacle_outside_the_grid_returns_null():
	_assert_rejected({"obstacles": [{ "x": -1, "y": 0 }]}, "outside the grid")


func test_obstacle_on_a_station_returns_null():
	_assert_rejected({"obstacles": [{ "x": 2, "y": 4 }]}, "sits on a station")


func test_train_pointing_at_an_unknown_station_returns_null():
	_assert_rejected({"trains": [
		{ "id": "train_1", "start_station": "A", "target_station": "Z" },
	]}, "unknown station Z")


func test_train_starting_at_a_destination_returns_null():
	_assert_rejected({"trains": [
		{ "id": "train_1", "start_station": "B", "target_station": "A" },
	]}, "not a source")


func test_duplicate_train_id_returns_null():
	_assert_rejected({"trains": [
		{ "id": "train_1", "start_station": "A", "target_station": "B" },
		{ "id": "train_1", "start_station": "A", "target_station": "B" },
	]}, "duplicate train id train_1")


func test_unknown_tool_returns_null():
	_assert_rejected({"available_tools": ["teleporter"]}, "unknown tool teleporter")


func test_unknown_win_condition_returns_null():
	_assert_rejected({"win_conditions": ["vibes"]}, "unknown win condition vibes")


func test_empty_win_conditions_returns_null():
	_assert_rejected({"win_conditions": []}, "no win conditions")


func test_bonus_larger_than_the_budget_returns_null():
	_assert_rejected({"segment_budget": 6, "bonus_min_segments": 8}, "exceeds segment_budget")


func test_bonus_equal_to_the_budget_is_allowed():
	assert_not_null(LevelData.load_from_file(
		_write_level({"segment_budget": 6, "bonus_min_segments": 6})))


func test_every_shipped_level_file_loads():
	for file_name in DirAccess.get_files_at("res://levels"):
		if file_name.ends_with(".json"):
			assert_not_null(
				LevelData.load_from_file("res://levels/" + file_name),
				"%s should load" % file_name)
