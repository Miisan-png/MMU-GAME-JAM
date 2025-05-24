extends Node3D

@export var dialogue_system_node: Control
@export var dialogue_ID: int = 1
@export var auto_trigger: bool = false  # Auto-start dialogue on enter
@export var can_retrigger: bool = false  # Can trigger multiple times

var player_in_range: bool = false
var has_been_triggered: bool = false

func _ready():
	if not dialogue_system_node:
		print("Warning: No dialogue system node assigned!")

func _input(event):
	# Manual trigger with interact key when not auto-triggering
	if not auto_trigger and player_in_range and not has_been_triggered:
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
			_trigger_dialogue()

func _on_proximity_area_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		player_in_range = true
		
		if auto_trigger and (can_retrigger or not has_been_triggered):
			_trigger_dialogue()
		else:
			print("Press [INTERACT] to start dialogue")  # Optional UI hint

func _on_proximity_area_body_exited(body: Node3D) -> void:
	if body.name == "Player":
		player_in_range = false

func _trigger_dialogue():
	if not dialogue_system_node:
		print("Error: No dialogue system assigned!")
		return
	
	if dialogue_system_node.is_playing_dialogue():
		print("Dialogue already playing!")
		return
	
	has_been_triggered = true
	dialogue_system_node.play_dialogue(dialogue_ID)
	
	# Connect to dialogue finished signal to reset if retrigger is enabled
	if can_retrigger and not dialogue_system_node.dialogue_finished.is_connected(_on_dialogue_finished):
		dialogue_system_node.dialogue_finished.connect(_on_dialogue_finished)

func _on_dialogue_finished():
	if can_retrigger:
		has_been_triggered = false
