extends RefCounted

var definitions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/services.json"))
var instances := {}

func sync(buildings: BuildingManager) -> void:
	var active := {}
	for building in buildings.placed:
		var kind: String = building.def.id
		if not definitions.has(kind):
			continue
		var id: int = building.sprite.get_instance_id()
		var spec: Dictionary = definitions[kind]
		active[id] = instances.get(id, {"id":id, "kind":kind, "spec":spec, "building":building,
			"price":int(spec.price), "staff":int(spec.staff), "queue":[], "groups":[], "remaining":0.0})
	instances = active

func capacity(service: Dictionary) -> int:
	var staff: int = service.staff
	match service.kind:
		"dock":
			return int(service.spec.capacity) if staff > 0 else 0
		"ticket":
			return staff
		_:
			return mini(staff * int(service.spec.capacity), int(service.building.def.capacity))

func busy(service: Dictionary) -> int:
	var count := 0
	for job in service.groups:
		count += int(job.party)
	return count

func load_at(service: Dictionary) -> int:
	var count := busy(service)
	for guest in service.queue:
		count += int(guest.party)
	return count

