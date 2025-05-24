extends Node3D

@export var shake_intensity: float = 0.1
@export var shake_speed: float = 20.0

var time := 0.0
var original_position := Vector3.ZERO

func _ready():
	original_position = global_position

func _process(delta):
	time += delta * shake_speed
	var random_offset = Vector3(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	).normalized() * sin(time) * shake_intensity
	global_position = original_position + random_offset
