class_name PathfindingManager
extends RefCounted

var world: WorldManager
var buildings: BuildingManager
var trees := {}

func invalidate() -> void:
	trees.clear()

func reachable_from(start: Vector2i) -> Dictionary:
	if trees.has(start):
		return trees[start]
	if not walkable(start):
		return {}
	var queue: Array[Vector2i] = [start]
	var previous := {start: start}
	var cursor := 0
	while cursor < queue.size():
		var cell := queue[cursor]
		cursor += 1
		for step: Vector2i in WorldManager.STEPS:
			var next := cell + step
			if not previous.has(next) and walkable(next):
				previous[next] = cell
				queue.append(next)
	trees[start] = previous
	return previous

func route(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var previous := reachable_from(start)
	if not previous.has(goal):
		return result
	while goal != start:
		result.push_back(goal)
		goal = previous[goal]
	result.reverse()
	return result

func walkable(cell: Vector2i) -> bool:
	return world.road_cells.has(cell) and not world.water_cells.has(cell) and not buildings.occupied.has(cell)
