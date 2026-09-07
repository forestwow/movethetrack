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

	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("LevelData: %s is not valid JSON (line %d: %s)" % [path, json.get_error_line(), json.get_error_message()])
		return null
	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("LevelData: %s is not a JSON object" % path)
		return null
	var raw: Dictionary = json.data

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

	var problem := level._find_problem(raw)
	if not problem.is_empty():
		push_error("LevelData: %s — %s" % [path, problem])
		return null

	return level


func _find_problem(raw: Dictionary) -> String:
	if id.is_empty():
		return "missing id"
	if segment_budget <= 0:
		return "segment_budget must be positive"
	if stations.is_empty():
		return "no stations"
	if trains.is_empty():
		return "no trains"
	if bonus_min_segments > segment_budget:
		return "bonus_min_segments %d exceeds segment_budget %d" % [bonus_min_segments, segment_budget]

	for entry in raw.get("stations", []):
		if not ROLES.has(entry.get("role", "")):
			return "station %s has unknown role %s" % [entry.get("id", ""), entry.get("role", "")]

	var seen_cells := {}
	var seen_ids := {}
	for station in stations:
		if not _is_inside(station.cell):
			return "station %s is outside the grid" % station.id
		if seen_ids.has(station.id):
			return "duplicate station id %s" % station.id
		if seen_cells.has(station.cell):
			return "two stations share cell %s" % station.cell
		seen_ids[station.id] = true
		seen_cells[station.cell] = true

	for cell in obstacles:
		if not _is_inside(cell):
			return "obstacle %s is outside the grid" % cell
		if seen_cells.has(cell):
			return "obstacle %s sits on a station" % cell

	var seen_trains := {}
	for train in trains:
		if seen_trains.has(train.id):
			return "duplicate train id %s" % train.id
		seen_trains[train.id] = true
		var source := get_station(train.start_station_id)
		var target := get_station(train.target_station_id)
		if source == null:
			return "train %s starts at unknown station %s" % [train.id, train.start_station_id]
		if target == null:
			return "train %s targets unknown station %s" % [train.id, train.target_station_id]
		if not source.is_source():
			return "train %s starts at %s, which is not a source" % [train.id, source.id]
		if not target.is_destination():
			return "train %s targets %s, which is not a destination" % [train.id, target.id]

	for tool_name in available_tools:
		if not KNOWN_TOOLS.has(tool_name):
			return "unknown tool %s" % tool_name

	if win_conditions.is_empty():
		return "no win conditions"
	for condition in win_conditions:
		if not KNOWN_WIN_CONDITIONS.has(condition):
			return "unknown win condition %s" % condition

	return ""


static func _is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < GRID_WIDTH and cell.y < GRID_HEIGHT


func get_station(station_id: String) -> Station:
	for station in stations:
		if station.id == station_id:
			return station
	return null


func create_grid() -> GridModel:
	var grid := GridModel.new(GRID_WIDTH, GRID_HEIGHT, segment_budget)
	if available_tools.has("crossing"):
		grid.max_edges_per_cell = 4
	elif available_tools.has("switch"):
		grid.max_edges_per_cell = 3
	for cell in obstacles:
		grid.add_obstacle(cell)
	for station in stations:
		grid.add_station(station)
	return grid
