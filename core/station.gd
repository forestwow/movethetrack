class_name Station
extends RefCounted

enum Role { SOURCE, DESTINATION }

var id: String
var cell: Vector2i
var color: String
var role: Role


func _init(station_id: String, station_cell: Vector2i, station_color: String, station_role: Role) -> void:
	id = station_id
	cell = station_cell
	color = station_color
	role = station_role


func is_source() -> bool:
	return role == Role.SOURCE


func is_destination() -> bool:
	return role == Role.DESTINATION
