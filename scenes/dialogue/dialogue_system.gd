extends Control

@onready var dialogue_box: Panel = $DialogueBox
@onready var content_label: Label = $DialogueBox/ContentLabel
@onready var csv_loader: CSVDialogueLoader = $CSV_LOADER
@onready var voice_player: AudioStreamPlayer = $voice_line_player

var current_sequence: Array = []
var current_line_index: int = 0
var is_dialogue_active: bool = false
var is_typing: bool = false

var typing_speed: float = 0.05 
var typing_timer: float = 0.0
var current_text: String = ""
var target_text: String = ""
var current_char_index: int = 0

var voice_lines: Dictionary = {}
var audio_duration: float = 0.0
var audio_wait_timer: float = 0.0
var waiting_for_audio: bool = false

signal dialogue_finished
signal line_finished
signal dialogue_line_started(dialogue_id: int, dialogue_text: String, dialogue_type: String)

func _ready():
	dialogue_box.visible = false
	_load_voice_lines()

func _load_voice_lines():
	for i in range(1, 100):
		var path = "res://audio/voice_lines/vl_%d.mp3" % i
		if ResourceLoader.exists(path):
			voice_lines[i] = load(path)

func _process(delta):
	if is_typing:
		typing_timer += delta
		if typing_timer >= typing_speed:
			typing_timer = 0.0
			_type_next_character()
	
	if waiting_for_audio:
		audio_wait_timer += delta
		if audio_wait_timer >= audio_duration + 3.0:
			waiting_for_audio = false
			_check_line_completion()

func play_dialogue(dialogue_id: int):
	if is_dialogue_active:
		print("Dialogue already active!")
		return
	
	current_sequence = csv_loader.get_dialogue_sequence(dialogue_id)
	if current_sequence.size() == 0:
		print("No dialogue found for ID: ", dialogue_id)
		return
	
	current_line_index = 0
	is_dialogue_active = true
	dialogue_box.visible = true
	
	_play_current_line()

func _play_current_line():
	if current_line_index >= current_sequence.size():
		_end_dialogue()
		return
	
	var current_line = current_sequence[current_line_index]
	dialogue_line_started.emit(current_line.id, current_line.dialogue, current_line.type)
	
	target_text = current_line.dialogue
	current_text = ""
	current_char_index = 0
	content_label.text = ""
	
	_play_voice_line(current_line.id)
	
	is_typing = true
	typing_timer = 0.0

func _play_voice_line(dialogue_id: int):
	if voice_lines.has(dialogue_id):
		var audio_stream = voice_lines[dialogue_id]
		voice_player.stream = audio_stream
		voice_player.play()
		audio_duration = audio_stream.get_length()
	else:
		audio_duration = 2.0

func _type_next_character():
	if current_char_index < target_text.length():
		current_text += target_text[current_char_index]
		content_label.text = current_text
		current_char_index += 1
	else:
		is_typing = false
		line_finished.emit()
		waiting_for_audio = true
		audio_wait_timer = 0.0

func _check_line_completion():
	var current_line = current_sequence[current_line_index]
	
	if current_line.type == "END":
		_end_dialogue()
	else:
		_next_line()

func _next_line():
	current_line_index += 1
	_play_current_line()

func _end_dialogue():
	is_dialogue_active = false
	is_typing = false
	waiting_for_audio = false
	voice_player.stop()
	dialogue_box.visible = false
	current_sequence.clear()
	dialogue_finished.emit()

func skip_typing():
	if is_typing:
		is_typing = false
		content_label.text = target_text
		line_finished.emit()
		waiting_for_audio = true
		audio_wait_timer = 0.0

func _input(event):
	if not is_dialogue_active:
		return
	
	if event.is_action_pressed("ui_accept"):  
		if is_typing:
			skip_typing()

func is_playing_dialogue() -> bool:
	return is_dialogue_active
