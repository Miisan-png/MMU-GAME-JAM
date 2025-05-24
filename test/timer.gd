extends Node2D

@export var timer_duration: float = 5.0
@export var next_scene_path: String = "res://NextScene.tscn"

var timer: Timer

func _ready():
   timer = Timer.new()
   add_child(timer)
   timer.wait_time = timer_duration
   timer.one_shot = true
   timer.timeout.connect(_on_timer_timeout)
   timer.start()

func _on_timer_timeout():
   get_tree().change_scene_to_file(next_scene_path)
