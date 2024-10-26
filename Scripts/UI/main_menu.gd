extends Control


@export var mpc : MultiPlayCore

var is_escaped : bool = false :
	set(value):
		is_escaped = value
		$Background.visible = not is_escaped
		$EscapeBackground.visible = true
		$Music.stop()
		$VBoxContainer/Tutorial.visible = false


func _on_create_game_pressed() -> void:
	$CreatingGameMenu.popup_centered()

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_ip_text_submitted(ip: String) -> void:
	mpc.start_online_join(ip, {}, {})
	$"..".visible = false
	$CreatingGameMenu.hide()
	is_escaped = true

func _on_create_server_pressed() -> void:
	mpc.start_online_host(true, {}, {})
	$"..".visible = false
	$CreatingGameMenu.hide()
	is_escaped = true

func _on_creating_game_menu_close_requested() -> void:
	$CreatingGameMenu.hide()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("escape") and is_escaped:
		$"..".visible = not $"..".visible
		if $"..".visible:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_settings_pressed() -> void:
	$Settings.visible = true


func _on_tutorial_pressed() -> void:
	$TutorialWindow.visible = true
	$TutorialWindow/VideoStreamPlayer.play()



func _on_tutorial_window_close_requested() -> void:
	$TutorialWindow.hide()


func _on_settings_close_requested() -> void:
	$Settings.hide()


func _on_connect_to_official_server_pressed() -> void:
	mpc.start_online_join("37.228.89.39:4200", {}, {})
	$"..".visible = false
	$CreatingGameMenu.hide()
	is_escaped = true
