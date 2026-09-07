class_name GridModel
extends RefCounted

signal track_changed(cell: Vector2i)

const MAX_EDGES_PER_CELL := 2

var width: int
var height: int
var segment_budget: int

var _edges := {}
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
	return not is_station(cell) and _edge_count(cell) >= MAX_EDGES_PER_CELL


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
