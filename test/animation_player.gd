extends Node3D

@onready var anim_player: AnimationPlayer = $AnimationPlayer

@export var animation_to_play: String = "idle"  # Change this to your animation name

func _ready():
	anim_player.play(animation_to_play)
