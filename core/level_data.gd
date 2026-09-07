class_name LevelData
extends RefCounted

const GRID_WIDTH := 10
const GRID_HEIGHT := 10

const KNOWN_TOOLS := ["crossing", "switch", "transfer_station", "tunnel"]
const KNOWN_WIN_CONDITIONS := ["basic_delivery", "color_match"]

const ROLES := {
	"source": Station.Role.SOURCE,
	"destination": Station.Role.DESTINATION,
}

var id: String
var segment_budget: int
var obstacles: Array[Vector2i] = []
var stations: Array[Station] = []
var trains: Array[Train] = []
var available_tools: Array[String] = []
var win_conditions: Array[String] = []
var bonus_min_segments := -1


static func load_from_file(path: String) -> LevelData:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("LevelData: cannot read %s" % path)
		return null

	var raw = JSON.parse_string(text)
	if typeof(raw) != TYPE_DICTIONARY:
		push_error("LevelData: %s is not a JSON object" % path)
		return null

	var level := LevelData.new()
	level.id = raw.get("id", "")
	level.segment_budget = int(raw.get("segment_budget", 0))
	level.bonus_min_segments = int(raw.get("bonus_min_segments", -1))
	level.available_tools.assign(raw.get("available_tools", []))
	level.win_conditions.assign(raw.get("win_conditions", []))

	for entry in raw.get("obstacles", []):
		level.obstacles.append(Vector2i(int(entry.get("x", 0)), int(entry.get("y", 0))))

	for entry in raw.get("stations", []):
		level.stations.append(Station.new(
			entry.get("id", ""),
			Vector2i(int(entry.get("x", 0)), int(entry.get("y", 0))),
			entry.get("color", ""),
			ROLES.get(entry.get("role", ""), Station.Role.SOURCE)))

	for entry in raw.get("trains", []):
		var start_id: String = entry.get("start_station", "")
		var source := level.get_station(start_id)
		level.trains.append(Train.new(
			entry.get("id", ""),
			start_id,
			entry.get("target_station", ""),
			source.color if source else ""))

	return level


func get_station(station_id: String) -> Station:
	for station in stations:
		if station.id == station_id:
			return station
	return null


func create_grid() -> GridModel:
	var grid := GridModel.new(GRID_WIDTH, GRID_HEIGHT, segment_budget)
	for cell in obstacles:
		grid.add_obstacle(cell)
	for station in stations:
		grid.add_station(station)
	return grid
