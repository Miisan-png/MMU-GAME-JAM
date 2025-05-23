extends CharacterBody3D

@export var walk_speed = 5.0
@export var sprint_speed = 8.0
@export var crouch_speed = 2.5
@export var jump_velocity = 4.5
@export var sensitivity = 0.003
@export var acceleration = 10.0

@export var crouch_height = 0.5
@export var normal_height = 1.0

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var collision_shape = $CollisionShape3D

var current_speed = 0.0
var is_crouched = false

var target_collision_height = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	target_collision_height = normal_height

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * sensitivity)
		camera.rotate_x(-event.relative.y * sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _physics_process(delta: float) -> void:
	handle_gravity(delta)
	handle_jump()
	handle_crouch(delta)
	handle_movement(delta)
	move_and_slide()

func handle_gravity(delta: float):
	if not is_on_floor():
		velocity += get_gravity() * delta

func handle_jump():
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not is_crouched:
		velocity.y = jump_velocity

func handle_crouch(delta: float):
	if Input.is_action_pressed("crouch"):
		if not is_crouched:
			is_crouched = true
			target_collision_height = crouch_height
	else:
		if is_crouched and not is_ceiling_above():
			is_crouched = false
			target_collision_height = normal_height
	
	var shape = collision_shape.shape as CapsuleShape3D
	if shape:
		shape.height = lerp(shape.height, target_collision_height, delta * 10.0)
		head.position.y = lerp(head.position.y, (shape.height - normal_height) * 0.5, delta * 10.0)

func is_ceiling_above() -> bool:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		global_position,
		global_position + Vector3.UP * (normal_height + 0.1)
	)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	return result.size() > 0

func handle_movement(delta: float):
	var input_dir = Vector2.ZERO
	
	if Input.is_action_pressed("left"):
		input_dir.x -= 1
	if Input.is_action_pressed("right"):
		input_dir.x += 1
	if Input.is_action_pressed("forward"):
		input_dir.y -= 1
	if Input.is_action_pressed("back"):
		input_dir.y += 1
	
	input_dir = input_dir.normalized()
	
	if is_crouched:
		current_speed = crouch_speed
	elif Input.is_action_pressed("sprint") and input_dir.length() > 0:
		current_speed = sprint_speed
	else:
		current_speed = walk_speed
	
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction.length() > 0:
		velocity.x = lerp(velocity.x, direction.x * current_speed, acceleration * delta)
		velocity.z = lerp(velocity.z, direction.z * current_speed, acceleration * delta)
	else:
		velocity.x = 0
		velocity.z = 0
