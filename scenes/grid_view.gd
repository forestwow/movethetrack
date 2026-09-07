class_name GridView
extends Node2D

const CELL := 80
const NO_CELL := Vector2i(-1, -1)

const GRASS := Color("#5e8f42")
const GRASS_TUFT := Color("#537f3a")
const GRASS_LINE := Color("#568139")
const BALLAST := Color("#8f8676")
const SLEEPER := Color("#5e4129")
const RAIL := Color("#e6e6da")
const ROUTE := Color("#f7dc7d")
const ROUTE_MERGE := Color("#c19a34")

const TUFTS := [
	[Vector2(14, 22), Vector2(52, 46), Vector2(33, 63)],
	[Vector2(60, 18), Vector2(22, 52), Vector2(44, 68)],
	[Vector2(26, 14), Vector2(64, 40), Vector2(16, 66)],
	[Vector2(40, 26), Vector2(12, 44), Vector2(58, 60)],
]
const TREE_TRUNK := Color("#4a3524")
const TREE_LEAF := Color("#2d6b2a")
const TREE_SHADE := Color("#20501e")
const PLATFORM := Color("#c6c1b1")
const PLATFORM_EDGE := Color("#8a8678")
const OUTLINE := Color("#2a2118")
const WINDOW := Color("#dfe7ef")

const COLORS := {
	"red": Color("#d13b32"),
	"blue": Color("#2f6fc4"),
	"green": Color("#3f9d52"),
	"yellow": Color("#e0a92c"),
}

var grid: GridModel
var editable := true

var _drag_cell := NO_CELL
var _press_cell := NO_CELL
var _dragged := false
var _train_colors := {}
var _train_cells := {}
var _train_headings := {}


func set_grid(new_grid: GridModel) -> void:
	if grid != null and grid.track_changed.is_connected(_on_track_changed):
		grid.track_changed.disconnect(_on_track_changed)
	grid = new_grid
	grid.track_changed.connect(_on_track_changed)
	queue_redraw()


func set_train_colors(colors: Dictionary) -> void:
	_train_colors = colors


func show_trains(cells: Dictionary) -> void:
	for train_id in cells:
		if _train_cells.has(train_id) and cells[train_id] != _train_cells[train_id]:
			_train_headings[train_id] = cells[train_id] - _train_cells[train_id]
	_train_cells = cells
	queue_redraw()


func clear_trains() -> void:
	_train_headings.clear()
	show_trains({})


func cell_at(position: Vector2) -> Vector2i:
	return Vector2i(int(position.x) / CELL, int(position.y) / CELL)


func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * CELL + CELL / 2.0, cell.y * CELL + CELL / 2.0)


func board_size() -> Vector2:
	return Vector2(grid.width * CELL, grid.height * CELL)


func _on_track_changed(_cell: Vector2i) -> void:
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if grid == null or not editable:
		return

	var local := make_input_local(event)

	if local is InputEventMouseButton:
		var cell := cell_at(local.position)
		if local.button_index == MOUSE_BUTTON_LEFT:
			if local.pressed:
				_drag_cell = cell
				_press_cell = cell
				_dragged = false
			else:
				if not _dragged and cell == _press_cell:
					grid.cycle_switch(cell)
				_drag_cell = NO_CELL
		elif local.button_index == MOUSE_BUTTON_RIGHT and local.pressed:
			grid.remove_track(cell)

	elif local is InputEventMouseMotion and _drag_cell != NO_CELL:
		var cell := cell_at(local.position)
		if cell != _drag_cell:
			_dragged = true
			if grid.is_inside(cell):
				grid.connect_cells(_drag_cell, cell)
			_drag_cell = cell


func _draw() -> void:
	if grid == null:
		return
	_draw_ground()
	for cell in grid.get_obstacles():
		_draw_tree(cell)
	for cell in grid.get_track_cells():
		_draw_ballast(cell)
	for cell in grid.get_track_cells():
		_draw_rails(cell)
	for cell in grid.get_track_cells():
		_draw_route(cell)
	for station in grid.get_stations():
		_draw_station(station)
	for train_id in _train_cells:
		_draw_train(train_id, _train_cells[train_id])


func _draw_ground() -> void:
	var size := board_size()
	draw_rect(Rect2(Vector2.ZERO, size), GRASS)
	for y in grid.height:
		for x in grid.width:
			var origin := Vector2(x, y) * CELL
			for offset in TUFTS[(x * 7 + y * 13) % TUFTS.size()]:
				draw_rect(Rect2(origin + offset, Vector2(4, 3)), GRASS_TUFT)
	for x in grid.width + 1:
		draw_line(Vector2(x * CELL, 0), Vector2(x * CELL, size.y), GRASS_LINE)
	for y in grid.height + 1:
		draw_line(Vector2(0, y * CELL), Vector2(size.x, y * CELL), GRASS_LINE)


func _edges_of(cell: Vector2i) -> Array:
	return TrackPiece.Edge.values().filter(
		func(edge): return grid.get_edges(cell) & GridModel.edge_bit(edge) != 0)


func _draw_ballast(cell: Vector2i) -> void:
	var center := cell_center(cell)
	var width := CELL * 0.46
	for edge in _edges_of(cell):
		var dir := Vector2(TrackPiece.direction(edge))
		var span := dir * CELL / 2.0
		var perp := Vector2(-dir.y, dir.x) * width / 2.0
		draw_colored_polygon([
			center - perp, center + perp, center + span + perp, center + span - perp,
		], BALLAST)
	draw_rect(Rect2(center - Vector2(width, width) / 2.0, Vector2(width, width)), BALLAST)


func _draw_rails(cell: Vector2i) -> void:
	var center := cell_center(cell)
	var offset := CELL * 0.1
	var edges := _edges_of(cell)
	for edge in edges:
		var dir := Vector2(TrackPiece.direction(edge))
		var perp := Vector2(-dir.y, dir.x)
		for distance in [0.26, 0.62, 0.96]:
			var at: Vector2 = center + dir * CELL / 2.0 * distance
			draw_line(at - perp * CELL * 0.145, at + perp * CELL * 0.145, SLEEPER, 5.0)
	for edge in edges:
		var dir := Vector2(TrackPiece.direction(edge))
		var perp := Vector2(-dir.y, dir.x)
		for side in [-1.0, 1.0]:
			var from: Vector2 = center + perp * offset * side
			draw_line(from, from + dir * CELL / 2.0, RAIL, 3.0)


func _draw_route(cell: Vector2i) -> void:
	var config := grid.get_switch(cell)
	if config.is_empty():
		return
	var center := cell_center(cell)
	var toe := Vector2(TrackPiece.direction(config["toe"]))
	var setting := Vector2(TrackPiece.direction(config["setting"]))

	for edge in _edges_of(cell):
		if edge == config["toe"] or edge == config["setting"]:
			continue
		var merging := Vector2(TrackPiece.direction(edge))
		draw_polyline(PackedVector2Array([
			center + merging * CELL / 2.0, center, center + toe * CELL / 2.0,
		]), ROUTE_MERGE, 3.0)
		_draw_arrow(center + merging * CELL * 0.3, -merging, ROUTE_MERGE)

	draw_polyline(PackedVector2Array([
		center + toe * CELL / 2.0, center, center + setting * CELL / 2.0,
	]), ROUTE, 3.0)


func _draw_arrow(tip: Vector2, dir: Vector2, color: Color) -> void:
	var back := tip - dir * CELL * 0.13
	var side := Vector2(-dir.y, dir.x) * CELL * 0.075
	draw_colored_polygon(PackedVector2Array([tip, back + side, back - side]), color)


func _draw_tree(cell: Vector2i) -> void:
	var center := cell_center(cell)
	draw_rect(Rect2(center + Vector2(-3, 6), Vector2(6, 18)), TREE_TRUNK)
	draw_circle(center + Vector2(0, -4), CELL * 0.25, TREE_SHADE)
	draw_circle(center + Vector2(-3, -9), CELL * 0.21, TREE_LEAF)


func _draw_station(station: Station) -> void:
	var color: Color = COLORS.get(station.color, Color.WHITE)
	var origin := Vector2(station.cell) * CELL
	var platform := Rect2(origin + Vector2(5, 5), Vector2(CELL - 10, CELL - 10))
	draw_rect(platform, PLATFORM)
	draw_rect(platform, PLATFORM_EDGE, false, 2.0)

	var building := Rect2(origin + Vector2(16, 18), Vector2(CELL - 32, CELL - 34))
	draw_rect(building, color.darkened(0.25))
	draw_rect(Rect2(building.position + Vector2(0, 12), building.size - Vector2(0, 12)), color)
	if station.is_destination():
		draw_rect(building.grow(-9), PLATFORM)
	draw_rect(building, OUTLINE, false, 2.0)


func _draw_train(train_id: String, cell: Vector2i) -> void:
	var color: Color = COLORS.get(_train_colors.get(train_id, ""), Color.WHITE)
	var heading: Vector2i = _train_headings.get(train_id, Vector2i(1, 0))
	var dir := Vector2(heading)
	var perp := Vector2(-dir.y, dir.x)
	var center := cell_center(cell)
	var length := CELL * 0.31
	var width := CELL * 0.19

	var body := PackedVector2Array([
		center - dir * length - perp * width,
		center + dir * length - perp * width,
		center + dir * length + perp * width,
		center - dir * length + perp * width,
	])
	draw_colored_polygon(body, color)
	draw_polyline(body + PackedVector2Array([body[0]]), OUTLINE, 2.0)

	var cab := center + dir * length * 0.45
	draw_line(cab - perp * width * 0.7, cab + perp * width * 0.7, WINDOW, 5.0)
