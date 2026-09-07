extends SceneTree


func _initialize() -> void:
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	_run.bind(main).call_deferred()


func _run(main) -> void:
	await process_frame
	await process_frame
	for x in range(2, 7):
		main.grid.connect_cells(Vector2i(x, 4), Vector2i(x + 1, 4))
	main._on_play_pressed()
	await create_timer(0.75).timeout
	root.get_texture().get_image().save_png("user://running.png")
	await create_timer(2.5).timeout
	root.get_texture().get_image().save_png("user://after.png")
	quit()
