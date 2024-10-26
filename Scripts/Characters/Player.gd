extends CharacterBody3D
class_name Player

signal died(player)

const LERP_VALUE : float = 0.15

var snap_vector : Vector3 = Vector3.DOWN
var speed : float

@export_group("Movement variables")
@export var walk_speed : float = 2.0
@export var run_speed : float = 5.0
@export var jump_strength : float = 15.0
@export var gravity : float = 50.0

var hp: int = 100 :
	set(value):
		$HPIndicator/HPBar.value = value
		hp = value
		if hp <= 0 and is_multiplayer_authority():
			die.rpc()

const ANIMATION_BLEND : float = 7.0

@onready var game_mgr : GameManager = $"/root/main/MultiPlayCore/Map/GameManager"

@onready var mpp : MPPlayer = $".." 
@onready var player_mesh : Node3D = $Model
@onready var spring_arm_pivot : Node3D = $SpringArmPivot
@onready var camera : Camera3D = $SpringArmPivot/SpringArm3D/Camera3D
@onready var animator : AnimationTree = $RusAnimationTree
@onready var hurtsound : AudioStreamPlayer3D = $RusSound

var team: String = "rus"
var member_id: int

var can_attack = false
var can_move = false

@rpc("any_peer", "call_local")
func change_team(new_team: String):
	if new_team == "lizards":
		$Model/RusModel.visible = false
		$Model/LizardModel.visible = true
		animator = $LizardAnimationTree
		hurtsound = $LizardHurtSound
	else:
		$Model/RusModel.visible = true
		$Model/LizardModel.visible = false
		animator = $RusAnimationTree
		hurtsound = $RusHurtSound
	remove_from_group(team + "_players")
	team = new_team
	add_to_group(team + "_players")
	member_id = get_tree().get_node_count_in_group(team + "_players") - 1
	MPIO.logdata("Member ID: %s" % [member_id])
	if is_multiplayer_authority():
		camera.make_current()

@rpc("any_peer", "call_local")
func respawn():
	animator.set("parameters/died_alive_transition/transition_request", "alive")
	if is_multiplayer_authority():
		print("RESPAWNED")
		hp = 100
		$HPIndicator.visible = true
		player_mesh.visible = true
		$CollisionShape.disabled = false
		transform.origin = get_tree().get_nodes_in_group(team + "_spawnpoints")[member_id].transform.origin
		can_attack = true
		can_move = true
		$DiedCollisionShape.disabled = true
		if team == "rus":
			$Model/RusModel.visible = true
			$Model/LizardModel.visible = false
		else:
			$Model/RusModel.visible = false
			$Model/LizardModel.visible = true

@rpc("any_peer", "call_local")
func hurt(damage: int):
	if is_multiplayer_authority():
		print("Damaged!")
		hp -= damage / 2 # FIXME
		hurtsound.play()
		print(hp)

@rpc("any_peer", "call_local")
func die():
	if is_multiplayer_authority():
		died.emit(self)
	animator.set("parameters/died_alive_transition/transition_request", "died")
	MPIO.logdata("DIED")
	can_move = false
	$CollisionShape.disabled = true
	$DiedCollisionShape.disabled = false

func _ready():
	if is_multiplayer_authority():
		if not game_mgr.is_node_ready():
			await game_mgr.ready
		died.connect(game_mgr._on_player_died)
		$SelectTeamMenu.visible = true
	else:
		game_mgr = $"/root/main/MultiPlayCore/Map/GameManager"
		$SelectTeamMenu.visible = false
		change_team(team)

func _physics_process(delta):
	if is_multiplayer_authority():
		if Input.is_action_just_pressed(mpp.ma("kill")):
			respawn()
		var move_direction : Vector3 = Vector3.ZERO
		move_direction.x = Input.get_action_strength(mpp.ma("move_right")) - Input.get_action_strength(mpp.ma("move_left"))
		move_direction.z = Input.get_action_strength(mpp.ma("move_backwards")) - Input.get_action_strength(mpp.ma("move_forwards"))
		move_direction = move_direction.rotated(Vector3.UP, spring_arm_pivot.rotation.y)
		
		velocity.y -= gravity * delta
		
		if Input.is_action_pressed("run"):
			speed = run_speed
		else:
			speed = walk_speed
		
		if can_move:
			velocity.x = move_direction.x * speed
			velocity.z = move_direction.z * speed
		
		if move_direction:
			player_mesh.rotation.y = lerp_angle(player_mesh.rotation.y, atan2(velocity.x, velocity.z), LERP_VALUE)
		
		var just_landed := is_on_floor() and snap_vector == Vector3.ZERO
		var is_jumping := is_on_floor() and Input.is_action_just_pressed("jump") and can_move
		if is_jumping:
			velocity.y = jump_strength
			snap_vector = Vector3.ZERO
		elif just_landed:
			snap_vector = Vector3.DOWN
		
		apply_floor_snap()
		move_and_slide()
		animate(delta)

func set_irw_blend(amount: float, delta: float):
	animator.set("parameters/iwr_blend/blend_amount", lerp(animator.get("parameters/iwr_blend/blend_amount"), amount, delta * ANIMATION_BLEND))
	animator.set("parameters/iwr_blend2/blend_amount", lerp(animator.get("parameters/iwr_blend/blend_amount"), amount, delta * ANIMATION_BLEND))

func animate(delta):
	#if hp <= 0:
	#	animator.set("parameters/died_alive_transition/transition_request", "died")
	#else:
	#	animator.set("parameters/died_alive_transition/transition_request", "alive")
	if is_on_floor():
		animator.set("parameters/ground_air_transition/transition_request", "grounded")
		if velocity.length() > 0:
			if speed == run_speed:
				if not $Stepsound.playing:
					$Stepsound.play()
				set_irw_blend(1.0, delta)
			else:
				$Stepsound.stop()
				set_irw_blend(0.0, delta)
		else:
			$Stepsound.stop()
			set_irw_blend(-1.0, delta)
	else:
		$Stepsound.stop()
		animator.set("parameters/ground_air_transition/transition_request", "air")
