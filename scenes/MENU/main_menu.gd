extends Node3D


@onready var menuplayer: AnimationPlayer = $menuplayer
@onready var fade: AnimationPlayer = $fade_in/AnimationPlayer

func _ready() -> void:
	fade.play("fadein")
	menuplayer.play("logo_modulate")

func _on_start_btn_pressed() -> void:
	fade.play("fadeout")

func _on_settings_btn_pressed() -> void:
	pass # Replace with function body.

func _on_quit_btn_pressed() -> void:
	get_tree().quit()


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "fadeout":
		get_tree().change_scene_to_file("res://test/test_map.tscn")
