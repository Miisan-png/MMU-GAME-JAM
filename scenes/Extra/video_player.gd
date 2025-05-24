extends Control

@onready var video_stream_player: VideoStreamPlayer = $VideoStreamPlayer

func _ready():
	video_stream_player.finished.connect(_on_video_finished)

func _on_video_finished():
	get_tree().change_scene_to_file("res://test/game_cutscene.tscn")
