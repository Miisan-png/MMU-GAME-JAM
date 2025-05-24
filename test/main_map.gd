extends Node3D

@onready var animation_player: AnimationPlayer = $CORE_GAMEPlAY/FadeIn/AnimationPlayer
@onready var fade_in: Control = $CORE_GAMEPlAY/FadeIn

func _ready() -> void:
	animation_player.play("fade_in")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "fade_in":
		fade_in.queue_free()
