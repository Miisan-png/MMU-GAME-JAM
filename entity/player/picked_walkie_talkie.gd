extends Node3D

var target_position: Vector3
var original_position: Vector3
var is_showing = false
var time_elapsed = 0.0
var bob_offset = 0.0
var sway_offset = 0.0
@onready var camera_3d: Camera3D = $"../Camera3D"


@export var slide_in_offset: Vector3 = Vector3(0, -2, 0)
@export var slide_speed: float = 5.0
@export var bob_amplitude: float = 0.02
@export var bob_speed: float = 3.0
@export var sway_amplitude: float = 0.01
@export var sway_speed: float = 2.0

func _ready():
	original_position = position
	target_position = original_position
	position = original_position + slide_in_offset
	visible = false

func _physics_process(delta: float) -> void:
	time_elapsed += delta
   
	if GM.i_walkie_picked_up and not is_showing:
		show_walkie()
	elif not GM.i_walkie_picked_up and is_showing:
		hide_walkie()
   
	if is_showing:
		update_movement_effects(delta)
		position = position.move_toward(target_position + Vector3(sway_offset, bob_offset, 0), slide_speed * delta)

func show_walkie():
	is_showing = true
	visible = true
	target_position = original_position

func hide_walkie():
	is_showing = false
	target_position = original_position + slide_in_offset
	await get_tree().create_timer(0.5).timeout
	visible = false

func update_movement_effects(delta):
	var player = get_parent()
	if player and player.has_method("get_velocity"):
		var velocity = player.get_velocity()
		var speed = velocity.length()
   	
		if speed > 0.1:
			bob_offset = sin(time_elapsed * bob_speed) * bob_amplitude * min(speed / 5.0, 1.0)
			sway_offset = cos(time_elapsed * sway_speed) * sway_amplitude * min(speed / 5.0, 1.0)
		else:
			bob_offset = lerp(bob_offset, 0.0, delta * 2.0)
			sway_offset = lerp(sway_offset, 0.0, delta * 2.0)
