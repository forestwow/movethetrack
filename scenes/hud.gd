extends CanvasLayer

signal play_pressed
signal reset_pressed
signal level_step_requested(delta: int)

const HEIGHT := 80

const PANEL := Color("#a8a89c")
const PANEL_LIGHT := Color("#d4d4c8")
const PANEL_DARK := Color("#6a6a60")
const BUTTON := Color("#b4b4a6")
const TEXT := Color("#14140f")
const TEXT_DIM := Color("#4a4a40")
const TEXT_OFF := Color("#83837a")

var _budget_label: Label
var _status_label: Label
var _play_button: Button
var _reset_button: Button
var _prev_button: Button
var _next_button: Button
var _level_label: Label


func _ready() -> void:
	var width := get_viewport().get_visible_rect().size.x

	var bar := Panel.new()
	bar.size = Vector2(width, HEIGHT)
	bar.add_theme_stylebox_override("panel", _bevel(PANEL, PANEL_LIGHT, PANEL_DARK))
	add_child(bar)

	_budget_label = _make_label(Vector2(18, 14), TEXT)
	_status_label = _make_label(Vector2(18, 44), TEXT_DIM)

	_prev_button = _make_button("<", Vector2(width - 470, 20), 44)
	_prev_button.pressed.connect(func(): level_step_requested.emit(-1))

	_level_label = _make_label(Vector2(width - 416, 30), TEXT)
	_level_label.size = Vector2(80, 20)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_next_button = _make_button(">", Vector2(width - 330, 20), 44)
	_next_button.pressed.connect(func(): level_step_requested.emit(1))

	_reset_button = _make_button("Reset", Vector2(width - 218, 20))
	_reset_button.pressed.connect(func(): reset_pressed.emit())

	_play_button = _make_button("Play", Vector2(width - 112, 20))
	_play_button.pressed.connect(func(): play_pressed.emit())


func show_budget(used: int, total: int) -> void:
	_budget_label.text = "Segments  %d / %d" % [used, total]


func show_status(text: String) -> void:
	_status_label.text = text


func show_level(number: int, total: int) -> void:
	_level_label.text = "Level %d / %d" % [number, total]


func set_buttons_enabled(enabled: bool) -> void:
	for button in [_play_button, _reset_button, _prev_button, _next_button]:
		button.disabled = not enabled


func _make_label(position: Vector2, color: Color) -> Label:
	var label := Label.new()
	label.position = position
	label.add_theme_color_override("font_color", color)
	add_child(label)
	return label


func _make_button(text: String, position: Vector2, width := 96.0) -> Button:
	var button := Button.new()
	button.text = text
	button.position = position
	button.size = Vector2(width, 40)
	button.add_theme_stylebox_override("normal", _bevel(BUTTON, PANEL_LIGHT, PANEL_DARK))
	button.add_theme_stylebox_override("hover", _bevel(BUTTON.lightened(0.08), PANEL_LIGHT, PANEL_DARK))
	button.add_theme_stylebox_override("pressed", _bevel(BUTTON.darkened(0.08), PANEL_DARK, PANEL_LIGHT))
	button.add_theme_stylebox_override("disabled", _bevel(PANEL.darkened(0.05), PANEL_LIGHT, PANEL_DARK))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(state, TEXT)
	button.add_theme_color_override("font_disabled_color", TEXT_OFF)
	add_child(button)
	return button


func _bevel(fill: Color, light: Color, dark: Color) -> StyleBoxTexture:
	var image := Image.create(6, 6, false, Image.FORMAT_RGBA8)
	image.fill(fill)
	for i in 6:
		image.set_pixel(i, 0, light)
		image.set_pixel(0, i, light)
		image.set_pixel(i, 5, dark)
		image.set_pixel(5, i, dark)

	var box := StyleBoxTexture.new()
	box.texture = ImageTexture.create_from_image(image)
	box.set_texture_margin_all(2)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	return box
