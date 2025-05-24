extends Control
@onready var walkie_talkie_ic: TextureRect = $walkie_talkie_ic
@onready var keycard_ic: TextureRect = $keycard_ic

func _ready():
	walkie_talkie_ic.scale = Vector2.ZERO
	keycard_ic.scale = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if GM.p_keycard_collected == true:
		show_icon("keycard")


func show_icon(icon_name: String):
	var icon_to_show: TextureRect
	
	match icon_name:
		"walkie_talkie":
			icon_to_show = walkie_talkie_ic
		"keycard":
			icon_to_show = keycard_ic
		_:
			return
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	icon_to_show.scale = Vector2.ZERO
	tween.tween_property(icon_to_show, "scale", Vector2.ONE, 0.6)

func hide_icon(icon_name: String):
	var icon_to_hide: TextureRect
	
	match icon_name:
		"walkie_talkie":
			icon_to_hide = walkie_talkie_ic
		"keycard":
			icon_to_hide = keycard_ic
		_:
			return
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(icon_to_hide, "scale", Vector2.ZERO, 0.4)

func hide_all_icons():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(walkie_talkie_ic, "scale", Vector2.ZERO, 0.4)
	tween.tween_property(keycard_ic, "scale", Vector2.ZERO, 0.4)
