class_name SimulationEngine
extends RefCounted


static func simulate(grid: GridModel, level: LevelData) -> SimulationResult:
	var result := SimulationResult.new()
	var states := {}
	var start := {}
	for train in level.trains:
		var source := level.get_station(train.start_station_id)
		states[train.id] = {"cell": source.cell, "entry": -1, "done": false}
		start[train.id] = source.cell
	result.steps.append(start)

	var max_steps := grid.get_used_budget() * grid.max_edges_per_cell + 2
	while not _all_done(states):
		if result.steps.size() > max_steps:
			return result.fail(SimulationResult.Outcome.LOOP, _first_moving(states))

		var previous: Dictionary = result.steps.back()
		var step := {}
		var problem := SimulationResult.Outcome.SUCCESS
		var failed_id := ""
		var moved := false

		for train in level.trains:
			var state: Dictionary = states[train.id]
			if not state["done"] and problem == SimulationResult.Outcome.SUCCESS:
				problem = _advance(grid, train, state)
				if problem != SimulationResult.Outcome.SUCCESS:
					failed_id = train.id
			step[train.id] = state["cell"]
			moved = moved or state["cell"] != previous[train.id]

		if problem == SimulationResult.Outcome.SUCCESS:
			failed_id = _find_collision(previous, step)
			if not failed_id.is_empty():
				problem = SimulationResult.Outcome.COLLISION

		if moved:
			result.steps.append(step)
		if problem != SimulationResult.Outcome.SUCCESS:
			return result.fail(problem, failed_id)

	return result


static func route(grid: GridModel, level: LevelData, train: Train) -> Array[Vector2i]:
	var source := level.get_station(train.start_station_id)
	var state := {"cell": source.cell, "entry": -1, "done": false}
	var path: Array[Vector2i] = [source.cell]
	var max_steps := grid.get_used_budget() * grid.max_edges_per_cell + 2

	while not state["done"] and path.size() <= max_steps:
		var problem := _advance(grid, train, state)
		if state["cell"] != path[-1]:
			path.append(state["cell"])
		if problem != SimulationResult.Outcome.SUCCESS:
			break

	return path


static func _advance(grid: GridModel, train: Train, state: Dictionary) -> SimulationResult.Outcome:
	var cell: Vector2i = state["cell"]
	var exit_edge := -1

	if state["entry"] == -1:
		var exits := grid.get_station_exits(cell)
		if exits.is_empty():
			return SimulationResult.Outcome.NO_DEPARTURE
		if exits.size() > 1:
			return SimulationResult.Outcome.AMBIGUOUS_DEPARTURE
		exit_edge = _edge_towards(cell, exits[0])
	else:
		exit_edge = grid.exit_edge(cell, state["entry"])
		if exit_edge == -1:
			return SimulationResult.Outcome.DEAD_END

	var next: Vector2i = cell + TrackPiece.direction(exit_edge)
	if grid.is_station(next):
		if grid.get_station(next).id != train.target_station_id:
			state["cell"] = next
			return SimulationResult.Outcome.WRONG_STATION
		state["done"] = true

	state["cell"] = next
	state["entry"] = TrackPiece.opposite(exit_edge)
	return SimulationResult.Outcome.SUCCESS


static func _edge_towards(from: Vector2i, to: Vector2i) -> int:
	for edge in TrackPiece.Edge.values():
		if from + TrackPiece.direction(edge) == to:
			return edge
	return -1


static func _find_collision(previous: Dictionary, current: Dictionary) -> String:
	var ids := current.keys()
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			var a = ids[i]
			var b = ids[j]
			if current[a] == current[b]:
				return a
			if current[a] == previous[b] and current[b] == previous[a]:
				return a
	return ""


static func _all_done(states: Dictionary) -> bool:
	for state in states.values():
		if not state["done"]:
			return false
	return true


static func _first_moving(states: Dictionary) -> String:
	for train_id in states:
		if not states[train_id]["done"]:
			return train_id
	return ""
