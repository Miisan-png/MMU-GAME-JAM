extends Node3D

@onready var interact_label: Label3D = $Interact_Label
@onready var item_name_label: Label3D = $Item_Name_Label

var player_nearby = false
var tween: Tween

func _ready():
	interact_label.visible = false
	item_name_label.visible = true
	item_name_label.modulate.a = 1.0

func _input(event):
	if event.is_action_pressed("interact") and player_nearby:
		pickup_item()

func _on_pickup_area_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		player_nearby = true
		show_interact_label()

func _on_pickup_area_body_exited(body: Node3D) -> void:
	if body.name == "Player":
		player_nearby = false
		hide_interact_label()

func show_interact_label():
	interact_label.visible = true
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(interact_label, "modulate:a", 1.0, 0.3)

func hide_interact_label():
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(interact_label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): interact_label.visible = false)

func pickup_item():
	GM.i_walkie_picked_up = true
   
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_callback(func(): queue_free())
