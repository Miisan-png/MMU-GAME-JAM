extends Node3D

@onready var fade_in_player: AnimationPlayer = $FadeIn/AnimationPlayer

func _ready() -> void:
	fade_in_player.play("fade_in")
	GM.show_polaroid_icon = true
