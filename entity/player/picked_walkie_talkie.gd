extends Node3D





func _physics_process(delta: float) -> void:
	if GM.i_walkie_picked_up:
		visible = true
	else:
		visible = false
