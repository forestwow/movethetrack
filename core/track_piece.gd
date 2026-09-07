class_name TrackPiece
extends RefCounted

enum Edge { NORTH, EAST, SOUTH, WEST }

const DIRECTIONS := {
	Edge.NORTH: Vector2i(0, -1),
	Edge.EAST: Vector2i(1, 0),
	Edge.SOUTH: Vector2i(0, 1),
	Edge.WEST: Vector2i(-1, 0),
}

var edge_a: Edge
var edge_b: Edge


func _init(a: Edge, b: Edge) -> void:
	edge_a = a
	edge_b = b


static func is_valid_pair(a: Edge, b: Edge) -> bool:
	return a != b


static func opposite(edge: Edge) -> Edge:
	match edge:
		Edge.NORTH: return Edge.SOUTH
		Edge.SOUTH: return Edge.NORTH
		Edge.EAST: return Edge.WEST
		_: return Edge.EAST


static func direction(edge: Edge) -> Vector2i:
	return DIRECTIONS[edge]


func connects(edge: Edge) -> bool:
	return edge == edge_a or edge == edge_b


func other_edge(edge: Edge) -> int:
	if edge == edge_a:
		return edge_b
	if edge == edge_b:
		return edge_a
	return -1
