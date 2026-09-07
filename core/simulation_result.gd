class_name SimulationResult
extends RefCounted

enum Outcome { SUCCESS, NO_DEPARTURE, AMBIGUOUS_DEPARTURE, DEAD_END, WRONG_STATION, COLLISION, LOOP }

var outcome: Outcome = Outcome.SUCCESS
var failed_train_id := ""
var steps: Array[Dictionary] = []


func is_success() -> bool:
	return outcome == Outcome.SUCCESS


func get_path(train_id: String) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	for step in steps:
		if step.has(train_id):
			path.append(step[train_id])
	return path


func fail(reason: Outcome, train_id: String) -> SimulationResult:
	outcome = reason
	failed_train_id = train_id
	return self
