class_name Train
extends RefCounted

var id: String
var start_station_id: String
var target_station_id: String
var color: String


func _init(train_id: String, start_id: String, target_id: String, train_color: String) -> void:
	id = train_id
	start_station_id = start_id
	target_station_id = target_id
	color = train_color
