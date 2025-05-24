extends Control

@export var buttons: Array[Button] = []
var default_scale = Vector2.ONE
var hover_scale = Vector2(1.15, 1.15)
var scale_speed = 0.15
var bounce_strength = 1.25

func _ready():
	if buttons.is_empty():
		var found_buttons = find_children("*", "Button", true, false)
		for node in found_buttons:
			if node is Button:
				buttons.append(node as Button)
   
	for button in buttons:
		button.pivot_offset = button.size / 2
		setup_button(button)

func setup_button(button: Button):
	button.mouse_entered.connect(func(): animate_button(button, true))
	button.mouse_exited.connect(func(): animate_button(button, false))
	button.focus_entered.connect(func(): animate_button(button, true))
	button.focus_exited.connect(func(): animate_button(button, false))

func animate_button(button: Button, grow: bool):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.set_ease(Tween.EASE_OUT)
   
	if grow:
		tween.tween_property(button, "scale", hover_scale * bounce_strength, scale_speed * 0.5)
		tween.tween_property(button, "scale", hover_scale, scale_speed * 0.5)
	else:
		tween.tween_property(button, "scale", default_scale * 0.9, scale_speed * 0.5)
		tween.tween_property(button, "scale", default_scale, scale_speed * 0.5)
