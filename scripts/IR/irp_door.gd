extends Node3D

@onready var door_mesh: CSGBox3D = $CSGCombiner3D/DoorMesh

@export var open_height: float = 4.0
@export var open_speed: float = 0.8
@export var close_speed: float = 1.2
@export var open_duration: float = 1.5
@export var ease_open: Tween.EaseType = Tween.EASE_OUT
@export var ease_close: Tween.EaseType = Tween.EASE_IN
@export var trans_open: Tween.TransitionType = Tween.TRANS_BACK
@export var trans_close: Tween.TransitionType = Tween.TRANS_QUINT

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
	if Input.is_action_just_pressed("interact") and not is_open:
		action_door_open()

func action_door_open():
	if tween:
		tween.kill()
   
	tween = create_tween()
	tween.set_ease(ease_open)
	tween.set_trans(trans_open)
   
	tween.tween_property(door_mesh, "position", original_position + Vector3(0, open_height, 0), open_speed)
	is_open = true
   
	close_timer.start(open_duration)

func _auto_close_door():
	if tween:
		tween.kill()
   
	tween = create_tween()
	tween.set_ease(ease_close)
	tween.set_trans(trans_close)
   
	tween.tween_property(door_mesh, "position", original_position, close_speed)
	is_open = false
