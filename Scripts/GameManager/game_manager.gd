extends Node
class_name GameManager

@export var round_time = 3 * 60

var rus_won_rounds = 0
var lizards_won_rounds = 0

var died_lizards_count: int = 0
var died_rus_count: int = 0

@onready var mpc : MultiPlayCore = $"/root/main/MultiPlayCore"

@onready var round_timer : Timer = $RoundTimer

func is_idols_planted():
	for x in get_tree().get_nodes_in_group("idols"):
		if x.is_planted:
			return true
	return false

func _ready() -> void:
	set_multiplayer_authority(1, true)
	if multiplayer.is_server():
		multiplayer.peer_connected.connect(_on_peer_connected)
		$RoundTimer.start()

@rpc("any_peer", "call_local")
func update_score(rus_score: int, lizards_score: int):
	rus_won_rounds = rus_score
	lizards_won_rounds = lizards_score
	print(str(rus_score))
	$CanvasLayer/Control/Hub/Score/RusRoundWins.text = str(rus_score)
	$CanvasLayer/Control/Hub/Score/LizardsRoundWins.text = str(lizards_score)

@rpc("any_peer", "call_local")
func update_round_time(time_left: float):
	$RoundTimer.start(time_left)

@rpc("any_peer", "call_local")
func add_death(team: String):
	if not is_multiplayer_authority(): 
		return
	if team == "rus":
		died_rus_count += 1
		if died_rus_count == get_tree().get_node_count_in_group("rus_players"):
			declare_win.rpc("lizards")
	else:
		died_lizards_count += 1
		if died_lizards_count == get_tree().get_node_count_in_group("lizards_players") and not is_idols_planted():
			declare_win.rpc("rus")
			
@rpc("any_peer", "call_local")
func declare_win(team: String):
	if not $RestartGameTimer.is_stopped():
		return
	$RestartGameTimer.start()
	MPIO.logdata("DECLARE WIN")
	if team == "rus":
		$CanvasLayer/Control/RusWin.visible = true
		$CanvasLayer/Control/LizardsWin.visible = false
		if is_multiplayer_authority():
			rus_won_rounds += 1
	else:
		$CanvasLayer/Control/RusWin.visible = false
		$CanvasLayer/Control/LizardsWin.visible = true
		if is_multiplayer_authority():
			lizards_won_rounds += 1
	set_idol_burning_notification(false)
	set_idol_burning_notification.rpc(false)
	if not multiplayer.is_server():
		return
	MPIO.logdata(str(rus_won_rounds) + ":" + str(lizards_won_rounds))
	# Why? FIXME
	update_score.rpc(rus_won_rounds, lizards_won_rounds)
	update_score(rus_won_rounds, lizards_won_rounds)

func _on_restart_game_timer_timeout() -> void:
	$CanvasLayer/Control/RusWin.visible = false
	$CanvasLayer/Control/LizardsWin.visible = false
	var players = get_tree().get_nodes_in_group("rus_players") + get_tree().get_nodes_in_group("lizards_players")
	print(players)
	for x in players:
		# Very dirty HACK
		# FIXME: single respawn() method
		if not is_multiplayer_authority():
			x.respawn.rpc()
	died_lizards_count = 0
	died_rus_count = 0
	set_idol_burning_notification.rpc(false)
	for x in get_tree().get_nodes_in_group("idols"):
		x.reset()
	round_timer.stop()
	update_round_time.rpc(round_time)
	round_timer.start()

func _on_peer_connected(id: int):
	print("Updating score for: ", id)
	await get_tree().create_timer(1.0).timeout
	print(rus_won_rounds)
	print(lizards_won_rounds)
	update_score.rpc_id(id, rus_won_rounds, lizards_won_rounds)
	update_round_time.rpc_id(id, round_timer.time_left)

func _on_player_died(player: Player):
	add_death.rpc(player.team)

func _on_round_timer_timeout() -> void:
	if is_multiplayer_authority():
		declare_win.rpc("rus")

@rpc("any_peer", "call_local")
func stop_round_time():
	$RoundTimer.stop()

@rpc("any_peer", "call_local")
func set_idol_burning_notification(is_visible: bool):
	$"CanvasLayer/Control/Hub/IdolNotification".visible = is_visible

func _on_idol_planted():
	stop_round_time.rpc()
	set_idol_burning_notification.rpc(true)

func _on_idol_exploded():
	$"CanvasLayer/Control/Hub/IdolNotification".visible = false
	if is_multiplayer_authority():
		declare_win.rpc("lizards")

func _on_idol_defused():
	$"CanvasLayer/Control/Hub/IdolNotification".visible = false
	set_idol_burning_notification.rpc(false)
	if is_multiplayer_authority():
		declare_win.rpc("rus")

func _process(delta: float) -> void:
	var time = round_timer.time_left
	$CanvasLayer/Control/Hub/Score/TimeLeft.text = str(int(time / 60.0)) + ":" + str(int(time) % 60)
