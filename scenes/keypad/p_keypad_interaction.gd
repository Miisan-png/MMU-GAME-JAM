extends Node3D

@onready var key_1_mesh: MeshInstance3D = $"interactive_keypad/key_1/1"
@onready var key_2_mesh: MeshInstance3D = $"interactive_keypad/key_2/2"
@onready var key_3_mesh: MeshInstance3D = $"interactive_keypad/key_3/3"
@onready var key_4_mesh: MeshInstance3D = $"interactive_keypad/key_4/4"
@onready var key_5_mesh: MeshInstance3D = $"interactive_keypad/key_5/5"
@onready var key_6_mesh: MeshInstance3D = $"interactive_keypad/key_6/6"
@onready var key_7_mesh: MeshInstance3D = $"interactive_keypad/key_7/7"
@onready var key_8_mesh: MeshInstance3D = $"interactive_keypad/key_8/8"
@onready var key_9_mesh: MeshInstance3D = $"interactive_keypad/key_9/9"
@onready var key_0_mesh: MeshInstance3D = $"interactive_keypad/key_0/0"

@onready var key_1_area: Area3D = $interactive_keypad/key_1
@onready var key_2_area: Area3D = $interactive_keypad/key_2
@onready var key_3_area: Area3D = $interactive_keypad/key_3
@onready var key_4_area: Area3D = $interactive_keypad/key_4
@onready var key_5_area: Area3D = $interactive_keypad/key_5
@onready var key_6_area: Area3D = $interactive_keypad/key_6
@onready var key_7_area: Area3D = $interactive_keypad/key_7
@onready var key_8_area: Area3D = $interactive_keypad/key_8
@onready var key_9_area: Area3D = $interactive_keypad/key_9
@onready var key_0_area: Area3D = $interactive_keypad/key_0

@onready var number_1: Label3D = $display_labels/number_1
@onready var number_2: Label3D = $display_labels/number_2
@onready var number_3: Label3D = $display_labels/number_3

@onready var puzzle_camera: Camera3D = $PuzzleCamera

@export var CORRECT_KEY_CODE: Array
@export var NORMAL_COLOR: Color = Color.WHITE
@export var CORRECT_COLOR: Color = Color.GREEN
@export var player_camera: Camera3D
@export var puzzle_hud: Control

var original_positions: Dictionary = {}
var is_pressed: bool = false
var entered_code: Array = [0, 0, 0]
var current_position: int = 0
var is_opened: bool = false
var player_in_area: bool = false
var is_puzzle_active: bool = false
var return_button: Button
var original_player_pos: Vector3
var original_player_rot: Vector3
var puzzle_camera_base_pos: Vector3
var puzzle_camera_base_rot: Vector3

func _ready():
	original_positions[key_1_mesh] = key_1_mesh.position
	original_positions[key_2_mesh] = key_2_mesh.position
	original_positions[key_3_mesh] = key_3_mesh.position
	original_positions[key_4_mesh] = key_4_mesh.position
	original_positions[key_5_mesh] = key_5_mesh.position
	original_positions[key_6_mesh] = key_6_mesh.position
	original_positions[key_7_mesh] = key_7_mesh.position
	original_positions[key_8_mesh] = key_8_mesh.position
	original_positions[key_9_mesh] = key_9_mesh.position
	original_positions[key_0_mesh] = key_0_mesh.position
	
	key_1_area.input_event.connect(_on_key_area_input_event.bind(1, key_1_mesh))
	key_2_area.input_event.connect(_on_key_area_input_event.bind(2, key_2_mesh))
	key_3_area.input_event.connect(_on_key_area_input_event.bind(3, key_3_mesh))
	key_4_area.input_event.connect(_on_key_area_input_event.bind(4, key_4_mesh))
	key_5_area.input_event.connect(_on_key_area_input_event.bind(5, key_5_mesh))
	key_6_area.input_event.connect(_on_key_area_input_event.bind(6, key_6_mesh))
	key_7_area.input_event.connect(_on_key_area_input_event.bind(7, key_7_mesh))
	key_8_area.input_event.connect(_on_key_area_input_event.bind(8, key_8_mesh))
	key_9_area.input_event.connect(_on_key_area_input_event.bind(9, key_9_mesh))
	key_0_area.input_event.connect(_on_key_area_input_event.bind(0, key_0_mesh))
	
	number_1.modulate = NORMAL_COLOR
	number_2.modulate = NORMAL_COLOR
	number_3.modulate = NORMAL_COLOR
	
	puzzle_camera.current = false
	puzzle_camera_base_pos = puzzle_camera.global_position
	puzzle_camera_base_rot = puzzle_camera.global_rotation
	
	if puzzle_hud:
		puzzle_hud.visible = false
		return_button = puzzle_hud.get_node("return_btn")
		if return_button:
			return_button.pressed.connect(_on_return_btn_pressed)
	
	update_display()

func _input(event):
	if event.is_action_pressed("interact") and player_in_area and not is_puzzle_active:
		activate_puzzle()
	
	if is_puzzle_active and event is InputEventMouseMotion:
		var mouse_pos = get_viewport().get_mouse_position()
		var viewport_size = get_viewport().get_visible_rect().size
		
		var mouse_offset_x = (mouse_pos.x / viewport_size.x - 0.5) * 0.02
		var mouse_offset_y = (mouse_pos.y / viewport_size.y - 0.5) * 0.02
		
		puzzle_camera.global_position = puzzle_camera_base_pos + Vector3(mouse_offset_x, mouse_offset_y, 0)
		puzzle_camera.global_rotation = puzzle_camera_base_rot + Vector3(mouse_offset_y * 0.5, mouse_offset_x * 0.5, 0)

func _process(_delta):
	if not is_opened and entered_code == CORRECT_KEY_CODE:
		opened()

func activate_puzzle():
	is_puzzle_active = true
	original_player_pos = player_camera.global_position
	original_player_rot = player_camera.global_rotation
	GM.in_keypad_state = true
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if puzzle_hud:
		puzzle_hud.visible = true
	
	var camera_tween = create_tween()
	camera_tween.set_parallel(true)
	
	camera_tween.tween_method(interpolate_camera_transform, 0.0, 1.0, 0.8)
	camera_tween.set_trans(Tween.TRANS_CUBIC)
	camera_tween.set_ease(Tween.EASE_IN_OUT)
	
	camera_tween.tween_callback(func(): 
		puzzle_camera.current = true
		player_camera.current = false
	).set_delay(0.8)

func interpolate_camera_transform(progress: float):
	if player_camera:
		player_camera.global_position = original_player_pos.lerp(puzzle_camera_base_pos, progress)
		player_camera.global_rotation = original_player_rot.lerp(puzzle_camera_base_rot, progress)

func deactivate_puzzle():
	if not is_puzzle_active:
		return
		
	is_puzzle_active = false
	GM.in_keypad_state = false
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if puzzle_hud:
		puzzle_hud.visible = false
	
	player_camera.current = true
	puzzle_camera.current = false
	player_camera.global_position = original_player_pos
	player_camera.global_rotation = original_player_rot

func interpolate_camera_back(progress: float):
	if player_camera:
		player_camera.global_position = puzzle_camera_base_pos.lerp(original_player_pos, progress)
		player_camera.global_rotation = puzzle_camera_base_rot.lerp(original_player_rot, progress)

func _on_key_area_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int, key_number: int, key_mesh: MeshInstance3D):
	if event is InputEventMouseButton and is_puzzle_active:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not is_pressed and not is_opened:
			press_key(key_number, key_mesh)

func press_key(key_number: int, key_mesh: MeshInstance3D):
	if is_pressed:
		return
	
	is_pressed = true
	
	entered_code[current_position] = key_number
	current_position += 1
	
	if current_position >= 3:
		current_position = 0
	
	update_display()
	
	var tween = create_tween()
	var original_pos = original_positions[key_mesh]
	
	tween.tween_property(key_mesh, "position", original_pos + Vector3(0, 0, -0.011), 0.1)
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(key_mesh, "position", original_pos, 0.2)
	
	tween.tween_callback(func(): is_pressed = false)

func update_display():
	number_1.text = str(entered_code[0])
	number_2.text = str(entered_code[1])
	number_3.text = str(entered_code[2])

func opened():
	is_opened = true
	print("Keypad opened successfully!")
	GM.keypad_true = true
	var color_tween = create_tween()
	color_tween.tween_property(number_1, "modulate", CORRECT_COLOR, 0.3)
	color_tween.tween_interval(0.2)
	color_tween.tween_property(number_2, "modulate", CORRECT_COLOR, 0.3)
	color_tween.tween_interval(0.2)
	color_tween.tween_property(number_3, "modulate", CORRECT_COLOR, 0.3)
	
	color_tween.tween_callback(func(): print("Color animation complete!"))



func _on_detection_area_body_entered(body: Node3D) -> void:
	if body.has_method("is_player"):
		player_in_area = true

func _on_detection_area_body_exited(body: Node3D) -> void:
	if body.has_method("is_player"):
		player_in_area = false
		if is_puzzle_active:
			deactivate_puzzle()

func _on_return_btn_pressed() -> void:
	deactivate_puzzle()
