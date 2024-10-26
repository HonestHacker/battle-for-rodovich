extends Skeleton3D


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("kill"):
		physical_bones_start_simulation()
