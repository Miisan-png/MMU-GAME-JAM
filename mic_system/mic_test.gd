extends Node3D

@onready var door_mesh: CSGBox3D = $CSGCombiner3D/DoorMesh

@export var open_height: float = 3.0
@export var open_speed: float = 2.0
@export var open_duration: float = 3.0
@export var ease_type: Tween.EaseType = Tween.EASE_OUT
@export var transition_type: Tween.TransitionType = Tween.TRANS_QUART

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
   tween.set_ease(ease_type)
   tween.set_trans(transition_type)
   
   tween.tween_property(door_mesh, "position", original_position + Vector3(0, open_height, 0), open_speed)
   is_open = true
   
   close_timer.start(open_duration)

func _auto_close_door():
   if tween:
   	tween.kill()
   
   tween = create_tween()
   tween.set_ease(ease_type)
   tween.set_trans(transition_type)
   
   tween.tween_property(door_mesh, "position", original_position, open_speed)
   is_open = false
