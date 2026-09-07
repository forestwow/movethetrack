class_name GridView
extends Node2D

const CELL := 64

const BACKGROUND := Color("#161a23")
const GRID_LINE := Color("#252b38")
const OBSTACLE := Color("#39404f")
const TRACK := Color("#c9d2e3")
const STATION_RING := Color("#0f121a")

const COLORS := {
	"red": Color("#e0574f"),
	"blue": Color("#4d94e0"),
	"green": Color("#4fb87a"),
	"yellow": Color("#e0b64d"),
}

var grid: GridModel


func set_grid(new_grid: GridModel) -> void:
	if grid != null and grid.track_changed.is_connected(_on_track_changed):
		grid.track_changed.disconnect(_on_track_changed)
	grid = new_grid
	grid.track_changed.connect(_on_track_changed)
	queue_redraw()


func cell_at(position: Vector2) -> Vector2i:
	return Vector2i(int(position.x) / CELL, int(position.y) / CELL)


func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * CELL + CELL / 2.0, cell.y * CELL + CELL / 2.0)


func board_size() -> Vector2:
	return Vector2(grid.width * CELL, grid.height * CELL)


func _on_track_changed(_cell: Vector2i) -> void:
	queue_redraw()


func _draw() -> void:
	if grid == null:
		return
	draw_rect(Rect2(Vector2.ZERO, board_size()), BACKGROUND)
	_draw_grid_lines()
	for cell in grid.get_obstacles():
		draw_rect(Rect2(Vector2(cell) * CELL + Vector2(4, 4), Vector2(CELL - 8, CELL - 8)), OBSTACLE)
	for cell in grid.get_track_cells():
		_draw_track(cell)
	for station in grid.get_stations():
		_draw_station(station)


func _draw_grid_lines() -> void:
	var size := board_size()
	for x in grid.width + 1:
		draw_line(Vector2(x * CELL, 0), Vector2(x * CELL, size.y), GRID_LINE)
	for y in grid.height + 1:
		draw_line(Vector2(0, y * CELL), Vector2(size.x, y * CELL), GRID_LINE)


func _draw_track(cell: Vector2i) -> void:
	var center := cell_center(cell)
	for edge in TrackPiece.Edge.values():
		if grid.get_edges(cell) & GridModel.edge_bit(edge) != 0:
			draw_line(center, center + Vector2(TrackPiece.direction(edge)) * CELL / 2.0, TRACK, 6.0)


func _draw_station(station: Station) -> void:
	var center := cell_center(station.cell)
	var color: Color = COLORS.get(station.color, Color.WHITE)
	draw_circle(center, CELL * 0.34, color)
	if station.is_destination():
		draw_circle(center, CELL * 0.18, STATION_RING)
