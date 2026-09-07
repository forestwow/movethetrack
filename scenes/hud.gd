extends CanvasLayer

signal play_pressed

const HEIGHT := 80
const BAR := Color("#11141b")

var _budget_label: Label
var _status_label: Label
var _play_button: Button


func _ready() -> void:
	var width := get_viewport().get_visible_rect().size.x

	var bar := ColorRect.new()
	bar.color = BAR
	bar.size = Vector2(width, HEIGHT)
	add_child(bar)

	_budget_label = Label.new()
	_budget_label.position = Vector2(16, 12)
	add_child(_budget_label)

	_status_label = Label.new()
	_status_label.position = Vector2(16, 42)
	_status_label.modulate = Color("#8d97ab")
	add_child(_status_label)

	_play_button = Button.new()
	_play_button.text = "Play"
	_play_button.position = Vector2(width - 108, 22)
	_play_button.size = Vector2(92, 36)
	_play_button.pressed.connect(func(): play_pressed.emit())
	add_child(_play_button)


func show_budget(used: int, total: int) -> void:
	_budget_label.text = "Segments  %d / %d" % [used, total]


func show_status(text: String) -> void:
	_status_label.text = text


func set_play_enabled(enabled: bool) -> void:
	_play_button.disabled = not enabled
