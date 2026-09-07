extends Node2D

const LEVELS_DIR := "res://levels"
const STEP_SECONDS := 0.28
const RESTART_DELAY := 1.1

const FAILURES := {
	SimulationResult.Outcome.NO_DEPARTURE: "No track leaves the station",
	SimulationResult.Outcome.AMBIGUOUS_DEPARTURE: "Two tracks leave the same station",
	SimulationResult.Outcome.DEAD_END: "Track ends in the middle",
	SimulationResult.Outcome.WRONG_STATION: "Wrong station",
	SimulationResult.Outcome.COLLISION: "Trains collided",
	SimulationResult.Outcome.LOOP: "Train never arrives",
}

var level: LevelData
var grid: GridModel

var _level_paths: Array[String] = []
var _level_index := 0
var _result: SimulationResult
var _step := 0

@onready var view: GridView = $GridView
@onready var hud: CanvasLayer = $Hud
@onready var _timer: Timer = Timer.new()


func _ready() -> void:
	add_child(_timer)
	_timer.wait_time = STEP_SECONDS
	_timer.timeout.connect(_on_step)
	hud.play_pressed.connect(_on_play_pressed)
	hud.reset_pressed.connect(_on_reset_pressed)
	hud.level_step_requested.connect(_on_level_step_requested)

	for file_name in DirAccess.get_files_at(LEVELS_DIR):
		if file_name.ends_with(".json"):
			_level_paths.append("%s/%s" % [LEVELS_DIR, file_name])
	_level_paths.sort()
	_load_level()


func _load_level() -> void:
	level = LevelData.load_from_file(_level_paths[_level_index])
	grid = level.create_grid()
	grid.track_changed.connect(_on_track_changed)

	var colors := {}
	for train in level.trains:
		colors[train.id] = train.color

	view.set_grid(grid)
	view.set_train_colors(colors)
	view.clear_trains()
	hud.show_level(_level_index + 1, _level_paths.size())
	_enter_build_phase(_build_hint())


func _build_hint() -> String:
	if level.available_tools.has("switch"):
		return "Drag to build, click a junction to set it"
	return "Drag to build track"


func _enter_build_phase(status: String) -> void:
	view.editable = true
	hud.set_buttons_enabled(true)
	hud.show_status(status)
	_refresh_budget()
	_refresh_preview()


func _on_level_step_requested(delta: int) -> void:
	_level_index = wrapi(_level_index + delta, 0, _level_paths.size())
	_load_level()


func _on_reset_pressed() -> void:
	grid.clear_track()
	hud.show_status("Track cleared")


func _on_track_changed(_cell: Vector2i) -> void:
	_refresh_budget()
	_refresh_preview()


func _refresh_budget() -> void:
	hud.show_budget(grid.get_used_budget(), grid.segment_budget)


func _refresh_preview() -> void:
	var routes := {}
	for train in level.trains:
		routes[train.id] = SimulationEngine.route(grid, level, train)
	view.show_routes(routes)


func _on_play_pressed() -> void:
	_result = SimulationEngine.simulate(grid, level)
	_step = 0
	view.editable = false
	view.show_routes({})
	hud.set_buttons_enabled(false)
	hud.show_status("Running")
	view.show_trains(_result.steps[0])
	_timer.start()


func _on_step() -> void:
	_step += 1
	if _step >= _result.steps.size():
		_timer.stop()
		_finish()
		return
	view.show_trains(_result.steps[_step])


func _finish() -> void:
	if not _result.is_success():
		hud.show_status(FAILURES[_result.outcome])
		await get_tree().create_timer(RESTART_DELAY).timeout
		view.clear_trains()
		_enter_build_phase("Try again")
		return

	if _level_index + 1 >= _level_paths.size():
		hud.show_status("All levels complete")
		return
	hud.show_status("Delivered")
	await get_tree().create_timer(RESTART_DELAY).timeout
	_level_index += 1
	_load_level()
