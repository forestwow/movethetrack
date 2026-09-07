extends GutTest

const JUNCTION := Vector2i(3, 5)

var view: GridView
var grid: GridModel


func before_each():
	view = GridView.new()
	add_child_autofree(view)
	grid = GridModel.new(10, 10, 99)
	grid.max_edges_per_cell = 3
	view.set_grid(grid)


func _button(cell: Vector2i, pressed: bool, index := MOUSE_BUTTON_LEFT) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = index
	event.pressed = pressed
	event.position = view.cell_center(cell)
	return event


func _motion(cell: Vector2i) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.position = view.cell_center(cell)
	return event


func _drag(path: Array) -> void:
	view._unhandled_input(_button(path[0], true))
	for i in range(1, path.size()):
		view._unhandled_input(_motion(path[i]))
	view._unhandled_input(_button(path[-1], false))


func _click(cell: Vector2i) -> void:
	view._unhandled_input(_button(cell, true))
	view._unhandled_input(_button(cell, false))


func test_dragging_lays_track_along_the_path():
	_drag([Vector2i(1, 5), Vector2i(2, 5), Vector2i(3, 5)])
	assert_eq(grid.get_used_budget(), 3)
	assert_true(grid.has_track(Vector2i(2, 5)))


func test_clicking_a_junction_cycles_its_switch():
	_drag([Vector2i(2, 5), JUNCTION, Vector2i(4, 5)])
	_drag([JUNCTION, Vector2i(3, 4)])
	var before := grid.get_switch(JUNCTION)
	_click(JUNCTION)
	assert_ne(grid.get_switch(JUNCTION), before)
	assert_eq(grid.get_switch(JUNCTION), grid.get_switch_configs(JUNCTION)[1])


func test_a_drag_that_ends_on_a_junction_does_not_cycle_it():
	_drag([Vector2i(2, 5), JUNCTION, Vector2i(4, 5)])
	_drag([JUNCTION, Vector2i(3, 4)])
	var before := grid.get_switch(JUNCTION)
	_drag([Vector2i(3, 4), JUNCTION])
	assert_eq(grid.get_switch(JUNCTION), before)


func test_clicking_a_plain_track_cell_changes_nothing():
	_drag([Vector2i(1, 5), Vector2i(2, 5), Vector2i(3, 5)])
	_click(Vector2i(2, 5))
	assert_eq(grid.get_used_budget(), 3)


func test_right_click_removes_track():
	_drag([Vector2i(1, 5), Vector2i(2, 5), Vector2i(3, 5)])
	view._unhandled_input(_button(Vector2i(2, 5), true, MOUSE_BUTTON_RIGHT))
	assert_false(grid.has_track(Vector2i(2, 5)))


func test_nothing_happens_while_the_board_is_locked():
	view.editable = false
	_drag([Vector2i(1, 5), Vector2i(2, 5)])
	assert_eq(grid.get_used_budget(), 0)
