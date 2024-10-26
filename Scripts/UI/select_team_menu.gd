extends Control

@onready var player = $".."



func update_mouse_mode():
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	if Input.is_action_just_pressed(player.mpp.ma("select_team")) :
		visible = not visible
		update_mouse_mode()

func _on_rus_pressed() -> void:
	if is_multiplayer_authority():
		player.change_team.rpc("rus")
		player.respawn()
		visible = false
		update_mouse_mode()


func _on_lizard_pressed() -> void:
	if is_multiplayer_authority():
		player.change_team.rpc("lizards")
		player.respawn()
		visible = false
		update_mouse_mode()


func _on_visibility_changed() -> void:
	if visible:
		$DictorReplica.play()
