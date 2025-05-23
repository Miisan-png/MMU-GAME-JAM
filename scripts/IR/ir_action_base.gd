extends Node3D

signal interacted_with_action

@export var prompt_text: String = "Press E to interact"
@export var item_name_text: String = "Item"

@onready var interact_label: Label3D = $Interact_Label
@onready var item_name_label: Label3D = $Item_Name_Label
@onready var mesh_body_area: Area3D = $MeshBodyArea

var tween: Tween
var is_visible: bool = false

func _ready():
	interact_label.visible = false
	item_name_label.visible = false
	interact_label.modulate.a = 0
	item_name_label.modulate.a = 0
	is_visible = false

func show_labels():
	if is_visible:
		return
	
	is_visible = true
	interact_label.text = prompt_text
	item_name_label.text = item_name_text
	
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_parallel(true)
	
	interact_label.modulate.a = 0
	item_name_label.modulate.a = 0
	interact_label.visible = true
	item_name_label.visible = true
	
	tween.tween_property(interact_label, "modulate:a", 1.0, 0.3)
	tween.tween_property(item_name_label, "modulate:a", 1.0, 0.3)
	tween.tween_property(interact_label, "scale", Vector3.ONE, 0.3).from(Vector3(0.8, 0.8, 0.8))
	tween.tween_property(item_name_label, "scale", Vector3.ONE, 0.3).from(Vector3(0.8, 0.8, 0.8))

func hide_labels():
	if not is_visible:
		return
	
	is_visible = false
	
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(interact_label, "modulate:a", 0.0, 0.2)
	tween.tween_property(item_name_label, "modulate:a", 0.0, 0.2)
	tween.tween_property(interact_label, "scale", Vector3(0.8, 0.8, 0.8), 0.2)
	tween.tween_property(item_name_label, "scale", Vector3(0.8, 0.8, 0.8), 0.2)
	
	tween.tween_callback(func(): 
		interact_label.visible = false
		item_name_label.visible = false
	).set_delay(0.2)

func interact():
	print("Interacted with: " + item_name_text)
	interacted_with_action.emit()
