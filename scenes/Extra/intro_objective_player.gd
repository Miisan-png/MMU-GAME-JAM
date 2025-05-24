extends Control

@export var fade_in_duration: float = 1.0
@export var typewriter_delay: float = 0.05
@export var hold_duration: float = 3.0
@export var fade_out_duration: float = 1.0
@export var objective_text: String = "Your objective here"
@export var auto_start: bool = true

@onready var objective: Label = $objective

var tween: Tween

func _ready():
	objective.modulate.a = 0.0
	objective.text = ""
	if auto_start:
		start()

func start():
	show()
   
	tween = create_tween()
	tween.tween_property(objective, "modulate:a", 1.0, fade_in_duration)
	tween.tween_callback(_start_typewriter)

func _start_typewriter():
	var chars = objective_text.length()
	for i in range(chars + 1):
		objective.text = objective_text.substr(0, i)
		await get_tree().create_timer(typewriter_delay).timeout
   
	await get_tree().create_timer(hold_duration).timeout
	end()

func end():
	if tween:
		tween.kill()
   
	tween = create_tween()
	tween.tween_property(objective, "modulate:a", 0.0, fade_out_duration)
	tween.tween_callback(hide)
