extends Node2D

const FIRST_LEVEL := "res://levels/level_01.json"

var level: LevelData
var grid: GridModel

@onready var view: GridView = $GridView


func _ready() -> void:
	level = LevelData.load_from_file(FIRST_LEVEL)
	grid = level.create_grid()
	view.set_grid(grid)
	_build_demo_track()


func _build_demo_track() -> void:
	grid.connect_cells(Vector2i(2, 4), Vector2i(3, 4))
	grid.connect_cells(Vector2i(3, 4), Vector2i(4, 4))
	grid.connect_cells(Vector2i(4, 4), Vector2i(4, 5))
