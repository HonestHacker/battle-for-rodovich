extends StaticBody3D
class_name Idol


signal planted
signal exploded
signal defused

var is_planted = false
var defusers : Dictionary = {}

@onready var game_mgr : GameManager = $"../../GameManager"

func is_idols_planted():
	for x in get_tree().get_nodes_in_group("idols"):
		if x.is_planted:
			return true
	return false

func _ready() -> void:
	add_to_group("idols")
	if multiplayer.is_server():
		planted.connect(game_mgr._on_idol_planted)
		exploded.connect(game_mgr._on_idol_exploded)
		defused.connect(game_mgr._on_idol_defused)
		$Timer.timeout.connect(explode)

func plant():
	if not is_idols_planted():
		is_planted = true
		planted.emit()
		$Fire.emitting = true
		$Fire/OmniLight3D.visible = true
		$Timer.start()

func explode():
	exploded.emit()
	is_planted = false
	$Fire.emitting = false
	$Fire/OmniLight3D.visible = false

func defuse(defuser: Player):
	if is_planted:
		if not defusers.get(defuser.name):
			defusers[defuser.name] = 0
		defusers[defuser.name] += 1
		if defusers[defuser.name] == 5:
			print("DEFUSED")
			defused.emit()
			reset()

func reset():
	$Timer.stop()
	is_planted = false
	$Fire.emitting = false
	$Fire/OmniLight3D.visible = false
	for x in defusers.keys():
		defusers[x] = 0
