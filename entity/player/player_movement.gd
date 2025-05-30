extends CharacterBody3D

@export var walk_speed = 5.0
@export var sprint_speed = 8.0
@export var crouch_speed = 2.5
@export var jump_velocity = 4.5
@export var sensitivity = 0.003
@export var acceleration = 10.0

@export var crouch_height = 2.0
@export var normal_height = 3.0
@export var interaction_range = 5.0

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var collision_shape = $CollisionShape3D

@export var crosshair_highlight_color:Color
@onready var fetch_item_label: Label = $CanvasLayer/player_hud/fetch_item_label
@onready var crosshair_rect: ColorRect = $CanvasLayer/player_hud/crosshair_rect
@onready var player_hud: Control = $CanvasLayer/player_hud
@onready var mic_system: Control = $CanvasLayer/mic_test
@onready var picked_walkie_talkie: Node3D = $Head/PickedWalkieTalkie
@onready var picked_polaroid_toggle: Node3D = $Head/Camera3D/PickedPolaroidToggle


@export var fetch_item_range = 20.0
var current_fetchable_item = null
var is_fetch_raycast_active = false

var current_speed = 0.0
var is_crouched = false
var current_interactable = null

var target_collision_height = 0.0

signal fetch_command_received(target_position: Vector3)

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	target_collision_height = normal_height
	if mic_system:
		mic_system.voice_fetch_triggered.connect(_on_voice_fetch_command)

func _unhandled_input(event):
	if GM.in_keypad_state:
		crosshair_rect.visible = false
		player_hud.visible = false
		player_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return
	
	crosshair_rect.visible = true
	player_hud.visible = true
	player_hud.mouse_filter = Control.MOUSE_FILTER_PASS
		
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * sensitivity)
		camera.rotate_x(-event.relative.y * sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	handle_gravity(delta)
	handle_jump()
	handle_crouch(delta)
	handle_movement(delta)
	handle_raycast()
	move_and_slide()
	handle_fetch_item_raycast()

func handle_gravity(delta: float):
	if not is_on_floor():
		velocity += get_gravity() * delta

func handle_jump():
	if GM.whistle_mode_enabled:
		return
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not is_crouched:
		velocity.y = jump_velocity

func handle_crouch(delta: float):
	if GM.whistle_mode_enabled:
		return
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
	if GM.whistle_mode_enabled:
		velocity.x = 0
		velocity.z = 0
		return
		
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

func handle_raycast():
	var space_state = get_world_3d().direct_space_state
	var from = camera.global_position
	var to = from + camera.global_transform.basis.z * -interaction_range
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var result = space_state.intersect_ray(query)
	
	if result:
		var collider = result.collider
		if collider is Area3D and collider.name == "MeshBodyArea":
			var interactable = collider.get_parent()
			if interactable and interactable.has_method("show_labels"):
				if current_interactable != interactable:
					if current_interactable:
						current_interactable.hide_labels()
					current_interactable = interactable
					current_interactable.show_labels()
			else:
				if current_interactable:
					current_interactable.hide_labels()
					current_interactable = null
		else:
			if current_interactable:
				current_interactable.hide_labels()
				current_interactable = null
	else:
		if current_interactable:
			current_interactable.hide_labels()
			current_interactable = null
	
	if Input.is_action_just_pressed("interact") and current_interactable and not GM.whistle_mode_enabled:
		current_interactable.interact()

func handle_fetch_item_raycast():
	is_fetch_raycast_active = GM.whistle_mode_enabled
	
	if not is_fetch_raycast_active:
		if current_fetchable_item:
			hide_fetch_ui()
			current_fetchable_item = null
		return
	
	var space_state = get_world_3d().direct_space_state
	var from = camera.global_position
	var to = from + camera.global_transform.basis.z * -fetch_item_range
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	query.collide_with_areas = true
	query.collide_with_bodies = false  # Only check areas, not bodies
	var result = space_state.intersect_ray(query)
	
	var found_fetchable = null
	
	if result:
		var collider = result.collider
		if collider is Area3D and collider.is_in_group("fetchable_items"):
			var fetchable_item = collider.get_parent()
			if fetchable_item and is_valid_fetchable_item(fetchable_item):
				found_fetchable = fetchable_item
	
	if found_fetchable:
		if current_fetchable_item != found_fetchable:
			if current_fetchable_item:
				hide_fetch_ui()
			current_fetchable_item = found_fetchable
			show_fetch_ui()
	else:
		if current_fetchable_item:
			hide_fetch_ui()
			current_fetchable_item = null

func is_valid_fetchable_item(item) -> bool:
	return item != null and is_instance_valid(item)

func _on_voice_fetch_command():
	if current_fetchable_item and GM.whistle_mode_enabled:
		var fetch_position = current_fetchable_item.global_position
		emit_signal("fetch_command_received", fetch_position)
		print("Voice fetch command executed!")

func show_fetch_ui():
	fetch_item_label.visible = true
	fetch_item_label.text = "[F] FETCH ITEM"
	fetch_item_label.modulate = crosshair_highlight_color
	crosshair_rect.color = crosshair_highlight_color

func hide_fetch_ui():
	fetch_item_label.visible = false
	crosshair_rect.color = Color.WHITE

func is_player() -> bool:
	return true
