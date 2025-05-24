extends Area3D
@export var polaroid_node: Node3D
@export var trigger_delay: float = 0.5
var player_in_area: bool = false
var show_timer: Timer

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
   
	show_timer = Timer.new()
	show_timer.wait_time = trigger_delay
	show_timer.one_shot = true
	show_timer.timeout.connect(_show_polaroid)
	add_child(show_timer)

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player" and polaroid_node:
		player_in_area = true
		show_timer.start()

func _on_body_exited(body: Node3D) -> void:
	if body.name == "Player" and polaroid_node:
		player_in_area = false
		show_timer.stop()
		_hide_polaroid()

func _show_polaroid():
	if player_in_area and polaroid_node:
		polaroid_node.show_polaroid()

func _hide_polaroid():
	if polaroid_node:
		polaroid_node.leave_polaroid()
