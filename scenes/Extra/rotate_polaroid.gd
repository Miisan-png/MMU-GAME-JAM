extends Node3D

@export var rotation_speed: float = 1.0
@export var rotate_x: bool = false
@export var rotate_y: bool = true
@export var rotate_z: bool = false
@export var animation_speed: float = 2.0

var original_position: Vector3 = Vector3(-0.004, -0.225, -0.738)
var hidden_position: Vector3 = Vector3(-0.004, -0.759, -0.738)
var current_t: float = 0.0
var is_showing: bool = false
var is_hiding: bool = false

func _ready():
	position = hidden_position
	visible = false

func _process(delta):
	var rotation_amount = rotation_speed * delta
	
	if rotate_x:
		rotate_object_local(Vector3.RIGHT, rotation_amount)
	if rotate_y:
		rotate_object_local(Vector3.UP, rotation_amount)
	if rotate_z:
		rotate_object_local(Vector3.FORWARD, rotation_amount)
	
	if is_showing:
		current_t += delta * animation_speed
		if current_t >= 1.0:
			current_t = 1.0
			is_showing = false
		position = hidden_position.lerp(original_position, ease_out_cubic(current_t))
	
	if is_hiding:
		current_t -= delta * animation_speed
		if current_t <= 0.0:
			current_t = 0.0
			is_hiding = false
			visible = false
		position = hidden_position.lerp(original_position, ease_in_cubic(current_t))

func ease_out_cubic(t: float) -> float:
	return 1.0 - pow(1.0 - t, 3.0)

func ease_in_cubic(t: float) -> float:
	return t * t * t

func show_polaroid():
	position = hidden_position
	visible = true
	current_t = 0.0
	is_showing = true
	is_hiding = false

func leave_polaroid():
	current_t = 1.0
	is_hiding = true
	is_showing = false
