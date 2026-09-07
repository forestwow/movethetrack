class_name GridModel
extends RefCounted

signal track_changed(cell: Vector2i)

const MAX_EDGES_PER_CELL := 2

var width: int
var height: int
var segment_budget: int
var max_edges_per_cell := MAX_EDGES_PER_CELL

var _edges := {}
var _switches := {}
var _obstacles := {}
var _stations := {}


func _init(grid_width: int, grid_height: int, budget: int) -> void:
	width = grid_width
	height = grid_height
	segment_budget = budget


static func edge_bit(edge: TrackPiece.Edge) -> int:
	return 1 << edge


func add_obstacle(cell: Vector2i) -> void:
	_obstacles[cell] = true


func add_station(station: Station) -> void:
	_stations[station.cell] = station


func get_station(cell: Vector2i) -> Station:
	return _stations.get(cell)


func get_stations() -> Array[Station]:
	var all: Array[Station] = []
	all.assign(_stations.values())
	return all


func get_obstacles() -> Array[Vector2i]:
	var all: Array[Vector2i] = []
	all.assign(_obstacles.keys())
	return all


func get_track_cells() -> Array[Vector2i]:
	var all: Array[Vector2i] = []
	all.assign(_edges.keys())
	return all


func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height


func is_blocked(cell: Vector2i) -> bool:
	return _obstacles.has(cell) or _stations.has(cell)


func is_station(cell: Vector2i) -> bool:
	return _stations.has(cell)


func get_edges(cell: Vector2i) -> int:
	return _edges.get(cell, 0)


func has_track(cell: Vector2i) -> bool:
	return get_edges(cell) != 0


func get_piece(cell: Vector2i) -> TrackPiece:
	var present := _edges_of(cell)
	if present.size() != 2:
		return null
	return TrackPiece.new(present[0], present[1])


func can_connect_cells(from: Vector2i, to: Vector2i) -> bool:
	if not is_inside(from) or not is_inside(to):
		return false
	if _obstacles.has(from) or _obstacles.has(to):
		return false
	if is_station(from) and is_station(to):
		return false
	var edge := _edge_towards(from, to)
	if edge == -1:
		return false
	if _has_edge(from, edge) or _has_edge(to, TrackPiece.opposite(edge)):
		return false
	if _is_full(from) or _is_full(to):
		return false
	return _new_cell_cost(from, to) <= get_budget_remaining()


func connect_cells(from: Vector2i, to: Vector2i) -> bool:
	if not can_connect_cells(from, to):
		return false
	var edge := _edge_towards(from, to)
	_add_edge(from, edge)
	_add_edge(to, TrackPiece.opposite(edge))
	track_changed.emit(from)
	track_changed.emit(to)
	return true


func exit_edge(cell: Vector2i, entry: TrackPiece.Edge) -> int:
	var edges := _edges_of(cell)
	if not edges.has(entry):
		return -1
	if edges.size() == 2:
		return edges[0] if edges[1] == entry else edges[1]
	if edges.size() == 3:
		var config := get_switch(cell)
		return config["setting"] if entry == config["toe"] else config["toe"]
	return -1


func get_switch(cell: Vector2i) -> Dictionary:
	var configs := get_switch_configs(cell)
	if configs.is_empty():
		return {}
	return configs[_switches.get(cell, 0) % configs.size()]


func get_switch_configs(cell: Vector2i) -> Array:
	var edges := _edges_of(cell)
	if edges.size() != 3:
		return []
	var configs := []
	for toe in edges:
		for setting in edges:
			if setting != toe:
				configs.append({"toe": toe, "setting": setting})
	return configs


func set_switch(cell: Vector2i, toe: TrackPiece.Edge, setting: TrackPiece.Edge) -> void:
	var index := get_switch_configs(cell).find({"toe": toe, "setting": setting})
	if index == -1:
		return
	_switches[cell] = index
	track_changed.emit(cell)


func cycle_switch(cell: Vector2i) -> void:
	var configs := get_switch_configs(cell)
	if configs.is_empty():
		return
	_switches[cell] = (_switches.get(cell, 0) + 1) % configs.size()
	track_changed.emit(cell)


func get_station_exits(station_cell: Vector2i) -> Array[Vector2i]:
	var exits: Array[Vector2i] = []
	for edge in TrackPiece.Edge.values():
		var neighbour: Vector2i = station_cell + TrackPiece.direction(edge)
		if _has_edge(neighbour, TrackPiece.opposite(edge)):
			exits.append(neighbour)
	return exits


func remove_track(cell: Vector2i) -> void:
	if not has_track(cell):
		return
	var neighbours := _edges_of(cell).map(func(edge): return cell + TrackPiece.direction(edge))
	for edge in _edges_of(cell):
		_remove_edge(cell + TrackPiece.direction(edge), TrackPiece.opposite(edge))
	_edges.erase(cell)
	_switches.erase(cell)
	track_changed.emit(cell)
	for neighbour in neighbours:
		track_changed.emit(neighbour)


func get_used_budget() -> int:
	return _edges.size()


func get_budget_remaining() -> int:
	return segment_budget - get_used_budget()


func _new_cell_cost(from: Vector2i, to: Vector2i) -> int:
	return _cell_cost(from) + _cell_cost(to)


func _cell_cost(cell: Vector2i) -> int:
	return int(not is_station(cell) and not has_track(cell))


func _has_edge(cell: Vector2i, edge: TrackPiece.Edge) -> bool:
	return get_edges(cell) & edge_bit(edge) != 0


func _is_full(cell: Vector2i) -> bool:
	return not is_station(cell) and _edge_count(cell) >= max_edges_per_cell


func clear_track() -> void:
	var cleared := get_track_cells()
	_edges.clear()
	_switches.clear()
	for cell in cleared:
		track_changed.emit(cell)


func _edge_towards(from: Vector2i, to: Vector2i) -> int:
	for edge in TrackPiece.Edge.values():
		if from + TrackPiece.direction(edge) == to:
			return edge
	return -1


func _edges_of(cell: Vector2i) -> Array:
	var mask := get_edges(cell)
	return TrackPiece.Edge.values().filter(func(edge): return mask & edge_bit(edge) != 0)


func _edge_count(cell: Vector2i) -> int:
	return _edges_of(cell).size()


func _add_edge(cell: Vector2i, edge: TrackPiece.Edge) -> void:
	if is_station(cell):
		return
	_edges[cell] = get_edges(cell) | edge_bit(edge)


func _remove_edge(cell: Vector2i, edge: TrackPiece.Edge) -> void:
	var mask := get_edges(cell) & ~edge_bit(edge)
	if mask == 0:
		_edges.erase(cell)
	else:
		_edges[cell] = mask
