extends SceneTree


func _initialize() -> void:
	root.add_child(load("res://scenes/Main.tscn").instantiate())
	_capture.call_deferred()


func _capture() -> void:
	await create_timer(0.4).timeout
	await process_frame
	root.get_texture().get_image().save_png("user://shot.png")
	quit()
