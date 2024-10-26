extends State
class_name MeleeWeapon

@export var weapon_name: String
@export var weapon_type: String
@export var slot: String
@export var range: float
@export var damage: int
@export var can_plant: bool = false
@export var can_defuse: bool = false

@onready var player: Player = $"../.."
@onready var attack_timer: Timer = $AttackTimer
@onready var parry_timer: Timer = $ParryTimer
@onready var melee_zone: MeleeZone = $"../../Model/MeleeZone"

func _ready() -> void:
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	parry_timer.timeout.connect(_on_parry_timer_timeout)

@rpc("authority", "call_local")
func start_attack_timer():
	attack_timer.start()

@rpc("authority", "call_local")
func start_parry_timer():
	parry_timer.start()

@rpc("authority", "call_local")
func switch_weapon(new_slot: String):
	transitioned.emit("Weapon" + new_slot)

@rpc("authority", "call_local")
func set_weapon_attack_state(state: String):
	player.animator["parameters/%s_attack_state/transition_request" % [weapon_type]] = state

@rpc("authority", "call_local")
func set_weapon_range():
	melee_zone.set_range(range)

func _on_attack_timer_timeout():
	attack()
	set_weapon_attack_state("idle")

func _on_parry_timer_timeout():
	parry()
	set_weapon_attack_state("idle")


func attack():
	for x in melee_zone.get_overlapping_players():
		x.hurt.rpc(damage)
	var idol = melee_zone.get_overlapping_idol()
	if idol != null:
		if can_plant and $"../..".team == "lizards":
			idol.plant()
		elif can_defuse and $"../..".team == "rus":
			idol.defuse($"../..")

@rpc("authority", "call_local")
func start_parrying():
	$"../../Model/ParryShield/CollisionShape".disabled = false

func parry():
	$"../../Model/ParryShield/CollisionShape".disabled = true

func enter():
	if not player.is_node_ready():
		await player.ready
	print(player.animator)
	player.animator["parameters/weapon_type/transition_request"] = weapon_type
	set_weapon_attack_state.rpc("idle")
	set_weapon_range.rpc()

func physics_update(delta: float):
	if is_multiplayer_authority():
		if Input.is_action_just_pressed(owner.mpp.ma("switch")):
			switch_weapon.rpc(("2" if slot == "1" else "1"))
		if Input.is_action_just_pressed(owner.mpp.ma("attack")) and player.can_attack and attack_timer.time_left <= 0 and parry_timer.time_left <= 0:
			set_weapon_attack_state.rpc("attack")
			start_attack_timer.rpc()
		if Input.is_action_just_pressed(owner.mpp.ma("parry")) and player.can_attack and attack_timer.time_left <= 0 and parry_timer.time_left <= 0:
			set_weapon_attack_state.rpc("parry")
			start_parrying.rpc()
			start_parry_timer.rpc()


func exit():
	attack_timer.stop()
