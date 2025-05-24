extends Node3D
@onready var door_mesh: CSGBox3D = $CSGCombiner3D/DoorMesh
@export var slide_distance: float = 3.0
@export var open_speed: float = 1.2
@export var close_speed: float = 1.5
var is_open: bool = false
var original_position: Vector3
var tween: Tween
var player_in_area: bool = false

func _ready():
	original_position = door_mesh.position

func _input(event):
	if event.is_action_pressed("interact") and player_in_area and GM.p_keycard_collected == true:
		if is_open:
			close_door()
		else:
			open_door()

func open_door():
	if is_open:
		return
	
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(door_mesh, "position", original_position + Vector3(slide_distance, 0, 0), open_speed)
	is_open = true

func close_door():
	if not is_open:
		return
	
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(door_mesh, "position", original_position, close_speed)
	is_open = false
