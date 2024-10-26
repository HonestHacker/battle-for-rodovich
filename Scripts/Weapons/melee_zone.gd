extends Node3D
class_name MeleeZone


func set_range(range: float):
	for x in get_children():
		x.target_position = Vector3.FORWARD * range

func get_overlapping_players() -> Array:
	var players = []
	for x in get_children():
		var collider = x.get_collider()
		if collider is Player and not (collider in players):
			players.push_front(collider)
	return players

func get_overlapping_idol() -> Idol:
	for x in get_children():
		var collider = x.get_collider()
		if collider is Idol:
			return collider
	return null
