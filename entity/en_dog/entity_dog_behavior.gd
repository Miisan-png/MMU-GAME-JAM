extends CharacterBody3D
@export var player: Node3D
@onready var metarig: Node3D = $metarig
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var label_3d: Label3D = $Label3D
@onready var dog_face_direction_ray: RayCast3D = $DogFaceDirectionRay

@onready var dog_body_collision: CollisionShape3D = $CollisionShape3D

var obstacles_detected: Array = []
var avoidance_direction: Vector3 = Vector3.ZERO
var is_avoiding: bool = false

enum AnimationState {
	IDLE,
	WALK,
	SIT,
	ORDERS,
	FETCH
}

var current_state: AnimationState = AnimationState.IDLE
var last_player_position: Vector3

var follow_speed: float = 4.0
var max_follow_speed: float = 6.0
var acceleration: float = 8.0
var deceleration: float = 12.0
var current_speed: float = 0.0
var movement_smoothing: float = 0.15

var min_follow_distance: float = 2.5
var max_follow_distance: float = 15.0
var close_distance: float = 1.2
var very_close_distance: float = 0.8

var rotation_speed: float = 8.0
var idle_rotation_speed: float = 2.0
var target_rotation: float = 0.0

var lerp_speed: float = 6.0
var target_walk_blend: float = 0.0
var target_sit_blend: float = 0.0
var current_walk_blend: float = 0.0
var current_sit_blend: float = 0.0

var wander_speed: float = 1.8
var wander_radius: float = 2.5
var wander_timer: float = 0.0
var wander_duration: float = 0.0
var idle_duration: float = 0.0
var wander_target: Vector3
var home_position: Vector3
var is_wandering: bool = false

var player_very_close: bool = false
var player_at_max_distance: bool = false
var sit_timer: float = 0.0
var sit_duration: float = 0.0
var state_change_cooldown: float = 0.0

var in_orders_mode: bool = false
var orders_mode_timer: float = 0.0
var orders_mode_duration: float = 10.0

var is_leading: bool = false
var leading_distance: float = 4.0
var leading_timer: float = 0.0
var leading_check_interval: float = 2.0
var player_running_threshold: float = 4.0

var movement_offset: Vector2 = Vector2.ZERO
var offset_speed: float = 1.5
var offset_strength: float = 0.3
var time_accumulator: float = 0.0

var fetch_target: Vector3
var is_fetching: bool = false
var fetch_wait_timer: float = 0.0
var fetch_wait_duration: float = 2.0
var fetch_speed: float = 2.0
var is_returning: bool = false

signal fetch_command_received(target_position: Vector3)

func _ready():
	animation_tree.active = true
	set_idle_state()
	if player:
		last_player_position = player.global_position
		home_position = player.global_position
	wander_duration = randf_range(2.0, 5.0)
	idle_duration = randf_range(1.5, 4.0)
	
	if player:
		player.connect("fetch_command_received", _on_fetch_command_received)

func _physics_process(delta):
	time_accumulator += delta
	
	if Input.is_action_just_pressed("whistle"):
		toggle_orders_mode()
	
	if in_orders_mode:
		orders_mode_timer += delta
		if orders_mode_timer >= orders_mode_duration:
			deactivate_orders_mode()
	
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	else:
		velocity.y = 0
	
	if not player:
		move_and_slide()
		return
	
	var player_velocity = (player.global_position - last_player_position) / delta
	var player_speed = player_velocity.length()
	last_player_position = player.global_position
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	leading_timer += delta
	if leading_timer >= leading_check_interval:
		check_leading_behavior(player_speed)
		leading_timer = 0.0
	
	state_change_cooldown = max(0.0, state_change_cooldown - delta)
	
	if is_fetching:
		handle_fetch_behavior(delta)
	elif in_orders_mode:
		handle_orders_mode(delta, distance_to_player)
	elif is_leading:
		handle_leading_behavior(delta, player_speed)
	elif distance_to_player < very_close_distance:
		handle_very_close_behavior(delta, player_speed)
	elif distance_to_player > max_follow_distance:
		handle_max_distance_behavior(delta)
	elif distance_to_player > min_follow_distance:
		handle_follow_behavior(delta, distance_to_player, player_speed)
	else:
		handle_nearby_behavior(delta, player_speed)
	
	move_and_slide()
	update_animation_blends(delta)

func handle_very_close_behavior(delta, player_speed):
	current_speed = lerp(current_speed, 0.0, deceleration * delta)
	velocity.x = 0
	velocity.z = 0
	is_wandering = false
	
	if player:
		var direction_to_player = (player.global_position - global_position).normalized()
		target_rotation = atan2(direction_to_player.x, direction_to_player.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, idle_rotation_speed * delta)
	
	sit_timer += delta
	
	if sit_timer >= sit_duration and state_change_cooldown <= 0.0:
		set_sit_state()
	elif current_state != AnimationState.SIT:
		set_idle_state()

func handle_max_distance_behavior(delta):
	if global_position.distance_to(player.global_position) > max_follow_distance * 1.5:
		var spawn_offset = Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
		global_position = player.global_position + spawn_offset
		home_position = player.global_position
		return
	
	current_speed = lerp(current_speed, 0.0, deceleration * delta)
	velocity.x = 0
	velocity.z = 0
	is_wandering = false
	
	set_idle_state()
	
	if player:
		var direction_to_player = (player.global_position - global_position).normalized()
		target_rotation = atan2(direction_to_player.x, direction_to_player.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, idle_rotation_speed * delta)

func handle_follow_behavior(delta, distance_to_player, player_speed):
	var distance_factor = (distance_to_player - min_follow_distance) / (max_follow_distance - min_follow_distance)
	var desired_speed = lerp(follow_speed, max_follow_speed, distance_factor)
	
	if player_speed > 3.0:
		desired_speed *= 1.3
	
	current_speed = lerp(current_speed, desired_speed, acceleration * delta)
	
	var base_direction = (player.global_position - global_position).normalized()
	
	movement_offset += Vector2(
		sin(time_accumulator * offset_speed) * offset_strength,
		cos(time_accumulator * offset_speed * 0.7) * offset_strength
	) * delta
	movement_offset = movement_offset.normalized() * min(movement_offset.length(), offset_strength)
	
	var movement_direction = Vector3(
		base_direction.x + movement_offset.x,
		0,
		base_direction.z + movement_offset.y
	).normalized()
	
	velocity.x = movement_direction.x * current_speed
	velocity.z = movement_direction.z * current_speed
	
	if movement_direction.length() > 0.1:
		target_rotation = atan2(movement_direction.x, movement_direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
	
	set_walk_state()
	is_wandering = false
	home_position = player.global_position

func handle_nearby_behavior(delta, player_speed):
	if player_speed > 0.5:
		var player_direction = (player.global_position - last_player_position).normalized()
		var side_offset = Vector3(-player_direction.z, 0, player_direction.x) * randf_range(-1.5, 1.5)
		var target_pos = player.global_position + side_offset
		
		var direction_to_target = (target_pos - global_position).normalized()
		current_speed = lerp(current_speed, follow_speed * 0.7, acceleration * delta)
		
		velocity.x = direction_to_target.x * current_speed
		velocity.z = direction_to_target.z * current_speed
		
		if direction_to_target.length() > 0.1:
			target_rotation = atan2(direction_to_target.x, direction_to_target.z)
			rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
		
		set_walk_state()
		is_wandering = false
	else:
		handle_idle_behavior(delta)

func handle_idle_behavior(delta):
	wander_timer += delta
	
	if not is_wandering:
		if wander_timer >= idle_duration:
			start_wandering()
			wander_timer = 0.0
		else:
			current_speed = lerp(current_speed, 0.0, deceleration * delta)
			velocity.x = lerp(velocity.x, 0.0, deceleration * delta)
			velocity.z = lerp(velocity.z, 0.0, deceleration * delta)
			set_idle_state()
	else:
		if wander_timer >= wander_duration or global_position.distance_to(wander_target) < 0.8:
			stop_wandering()
			wander_timer = 0.0
		else:
			wander_towards_target(delta)

func start_wandering():
	is_wandering = true
	var random_angle = randf() * TAU
	var random_distance = randf_range(0.8, wander_radius)
	wander_target = home_position + Vector3(cos(random_angle) * random_distance, 0, sin(random_angle) * random_distance)
	set_walk_state()

func stop_wandering():
	is_wandering = false
	wander_duration = randf_range(2.0, 5.0)
	idle_duration = randf_range(1.5, 4.0)

func wander_towards_target(delta):
	var direction = (wander_target - global_position).normalized()
	
	current_speed = lerp(current_speed, wander_speed, acceleration * 0.5 * delta)
	
	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed
	
	if direction.length() > 0.1:
		target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * 0.6 * delta)

func update_animation_blends(delta):
	current_walk_blend = lerp(current_walk_blend, target_walk_blend, lerp_speed * delta)
	current_sit_blend = lerp(current_sit_blend, target_sit_blend, lerp_speed * delta)
	
	var movement_intensity = clamp(current_speed / max_follow_speed, 0.0, 1.0)
	var walk_blend_value = lerp(-1.0, 1.0, movement_intensity) if target_walk_blend > 0 else -1.0
	
	animation_tree["parameters/Walk/blend_position"] = lerp(current_walk_blend, walk_blend_value, delta * 3.0)
	animation_tree["parameters/sit_blend/blend_amount"] = current_sit_blend

func set_idle_state():
	if current_state == AnimationState.IDLE:
		return
	current_state = AnimationState.IDLE
	target_walk_blend = -1.0
	target_sit_blend = 0.0
	label_3d.text = "State: IDLE"
	state_change_cooldown = 0.2

func set_walk_state():
	if current_state == AnimationState.WALK:
		return
	current_state = AnimationState.WALK
	target_walk_blend = 1.0
	target_sit_blend = 0.0
	label_3d.text = "State: WALK"
	state_change_cooldown = 0.1

func set_sit_state():
	if current_state == AnimationState.SIT:
		return
	current_state = AnimationState.SIT
	target_sit_blend = 1.0
	label_3d.text = "State: SIT"
	state_change_cooldown = 0.5

func set_orders_state():
	current_state = AnimationState.ORDERS
	target_walk_blend = -1.0
	target_sit_blend = 0.0
	label_3d.text = "State: ORDERS - Awaiting Command!"
	state_change_cooldown = 0.3

func set_fetch_state():
	current_state = AnimationState.FETCH
	target_walk_blend = 1.0
	target_sit_blend = 0.0
	label_3d.text = "State: FETCH"
	state_change_cooldown = 0.1

func toggle_orders_mode():
	if in_orders_mode:
		deactivate_orders_mode()
	else:
		activate_orders_mode()

func activate_orders_mode():
	in_orders_mode = true
	orders_mode_timer = 0.0
	is_leading = false
	is_wandering = false
	is_fetching = false
	
	GM.whistle_mode_enabled = true
	
	var offset = Vector3(randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5))
	var target_position = player.global_position + offset
	
	var distance_to_target = global_position.distance_to(target_position)
	if distance_to_target > 8.0:
		global_position = target_position
	else:
		var direction = (target_position - global_position).normalized()
		velocity.x = direction.x * max_follow_speed * 2.0
		velocity.z = direction.z * max_follow_speed * 2.0
	
	set_orders_state()

func deactivate_orders_mode():
	in_orders_mode = false
	orders_mode_timer = 0.0
	home_position = player.global_position
	GM.whistle_mode_enabled = false
	set_idle_state()

func handle_orders_mode(delta, distance_to_player):
	if distance_to_player > 2.0:
		var direction = (player.global_position - global_position).normalized()
		current_speed = lerp(current_speed, follow_speed, acceleration * delta)
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		set_walk_state()
	else:
		current_speed = lerp(current_speed, 0.0, deceleration * delta)
		velocity.x = 0
		velocity.z = 0
		set_orders_state()
	
	if player:
		var direction_to_player = (player.global_position - global_position).normalized()
		target_rotation = atan2(direction_to_player.x, direction_to_player.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)

func check_leading_behavior(player_speed):
	if player_speed > player_running_threshold and not in_orders_mode and not player_very_close:
		if not is_leading and randf() < 0.3:
			is_leading = true
			var player_direction = (player.global_position - last_player_position).normalized()
			if player_direction.length() > 0.1:
				var leading_position = player.global_position + player_direction * leading_distance
				leading_position += Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
				wander_target = leading_position
	else:
		if is_leading and player_speed < player_running_threshold * 0.7:
			is_leading = false

func handle_leading_behavior(delta, player_speed):
	var direction_to_target = (wander_target - global_position).normalized()
	var distance_to_target = global_position.distance_to(wander_target)
	
	if distance_to_target > 1.0:
		current_speed = lerp(current_speed, max_follow_speed * 1.2, acceleration * delta)
		velocity.x = direction_to_target.x * current_speed
		velocity.z = direction_to_target.z * current_speed
		
		target_rotation = atan2(direction_to_target.x, direction_to_target.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
		
		set_walk_state()
	else:
		current_speed = lerp(current_speed, 0.0, deceleration * delta)
		velocity.x = 0
		velocity.z = 0
		
		if player:
			var direction_to_player = (player.global_position - global_position).normalized()
			target_rotation = atan2(direction_to_player.x, direction_to_player.z)
			rotation.y = lerp_angle(rotation.y, target_rotation, idle_rotation_speed * delta)
		
		set_idle_state()
	
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player < close_distance or player_speed < player_running_threshold * 0.8:
		is_leading = false

func _on_fetch_command_received(target_position: Vector3):
	if in_orders_mode:
		start_fetch(target_position)

func start_fetch(target_position: Vector3):
	is_fetching = true
	is_returning = false
	fetch_target = target_position
	fetch_wait_timer = 0.0
	is_leading = false
	is_wandering = false
	set_fetch_state()

func handle_fetch_behavior(delta):
	if not is_returning:
		var distance_to_target = global_position.distance_to(fetch_target)
		
		if distance_to_target > 1.0:
			var direction = (fetch_target - global_position).normalized()
			current_speed = lerp(current_speed, fetch_speed, acceleration * delta)
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
			
			target_rotation = atan2(direction.x, direction.z)
			rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
			
			set_walk_state()
		else:
			current_speed = lerp(current_speed, 0.0, deceleration * delta)
			velocity.x = 0
			velocity.z = 0
			set_idle_state()
			
			fetch_wait_timer += delta
			if fetch_wait_timer >= fetch_wait_duration:
				is_returning = true
				fetch_wait_timer = 0.0
	else:
		var distance_to_player = global_position.distance_to(player.global_position)
		
		if distance_to_player > 2.0:
			var direction = (player.global_position - global_position).normalized()
			current_speed = lerp(current_speed, fetch_speed, acceleration * delta)
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
			
			target_rotation = atan2(direction.x, direction.z)
			rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
			
			set_walk_state()
		else:
			current_speed = lerp(current_speed, 0.0, deceleration * delta)
			velocity.x = 0
			velocity.z = 0
			is_fetching = false
			is_returning = false
			set_orders_state()

func _on_player_near_trigger_body_entered(body: Node3D) -> void:
	if body == player:
		player_very_close = true
		sit_timer = 0.0
		sit_duration = randf_range(2.0, 4.0)

func _on_player_near_trigger_body_exited(body: Node3D) -> void:
	if body == player:
		player_very_close = false
		sit_timer = 0.0

func _collect_keycard():
	GM.p_keycard_collected = true
