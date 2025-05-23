extends Node3D

@onready var door_mesh: CSGBox3D = $CSGCombiner3D/DoorMesh

@export var open_height: float = 3.0
@export var open_speed: float = 1.2
@export var close_speed: float = 1.5
@export var emergency_close_speed: float = 0.3
@export var open_duration: float = 2.0

var is_open: bool = false
var original_position: Vector3
var tween: Tween
var close_timer: Timer

func _ready():
	original_position = door_mesh.position
   
	close_timer = Timer.new()
	add_child(close_timer)
	close_timer.timeout.connect(_auto_close_door)

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		action_door_open()

func action_door_open():
	if is_open:
		return
   
	if tween:
		tween.kill()
   
	tween = create_tween()
	tween.tween_property(door_mesh, "position", original_position + Vector3(0, open_height, 0), open_speed)
	is_open = true
   
	close_timer.start(open_duration)

func _auto_close_door():
	if tween:
		tween.kill()
   
	tween = create_tween()
	tween.tween_property(door_mesh, "position", original_position, close_speed)
	is_open = false

func _emergency_close():
	close_timer.stop()
   
	if tween:
		tween.kill()
   
	tween = create_tween()
	tween.tween_property(door_mesh, "position", original_position, emergency_close_speed)
	is_open = false

func _on_player_trigger_area_body_entered(body: Node3D) -> void:
	if body.name == "Player" and is_open:
		_emergency_close()

func _on_player_trigger_area_body_exited(body: Node3D) -> void:
	if body.name == "Player" and is_open:
		_emergency_close()
