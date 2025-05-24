extends Control

@onready var dialogue_box: Panel = $DialogueBox
@onready var content_label: Label = $DialogueBox/ContentLabel
@onready var csv_loader: CSVDialogueLoader = $CSV_LOADER

# Dialogue playback state
var current_sequence: Array = []
var current_line_index: int = 0
var is_dialogue_active: bool = false
var is_typing: bool = false

# Typewriter effect settings
var typing_speed: float = 0.05 
var typing_timer: float = 0.0
var current_text: String = ""
var target_text: String = ""
var current_char_index: int = 0

signal dialogue_finished
signal line_finished
signal dialogue_line_started(dialogue_id: int, dialogue_text: String, dialogue_type: String)

func _ready():
	dialogue_box.visible = false

func _process(delta):
	if is_typing:
		typing_timer += delta
		if typing_timer >= typing_speed:
			typing_timer = 0.0
			_type_next_character()

func play_dialogue(dialogue_id: int):
	if is_dialogue_active:
		print("Dialogue already active!")
		return
	
	current_sequence = csv_loader.get_dialogue_sequence(dialogue_id)
	if current_sequence.size() == 0:
		print("No dialogue found for ID: ", dialogue_id)
		return
	
	print("Starting dialogue sequence with ", current_sequence.size(), " lines")
	for i in range(current_sequence.size()):
		var line = current_sequence[i]
		print("Line ", i, ": ", line.dialogue, " (", line.type, ")")
	
	current_line_index = 0
	is_dialogue_active = true
	dialogue_box.visible = true
	
	_play_current_line()

func _play_current_line():
	if current_line_index >= current_sequence.size():
		print("Reached end of sequence, ending dialogue")
		_end_dialogue()
		return
	
	var current_line = current_sequence[current_line_index]
	print("Playing line ", current_line_index, ": ID=", current_line.id, " ", current_line.dialogue, " (", current_line.type, ")")
	
	dialogue_line_started.emit(current_line.id, current_line.dialogue, current_line.type)
	
	target_text = current_line.dialogue
	current_text = ""
	current_char_index = 0
	content_label.text = ""
	
	is_typing = true
	typing_timer = 0.0

func _type_next_character():
	if current_char_index < target_text.length():
		current_text += target_text[current_char_index]
		content_label.text = current_text
		current_char_index += 1
	else:
		is_typing = false
		line_finished.emit()
		_check_line_completion()

func _check_line_completion():
	var current_line = current_sequence[current_line_index]
	print("Completed line: ", current_line.dialogue, " (Type: ", current_line.type, ")")
	
	await get_tree().create_timer(1.0).timeout
	
	if current_line.type == "END":
		print("Ending dialogue sequence")
		_end_dialogue()
	else:
		print("Moving to next line...")
		_next_line()

func _next_line():
	current_line_index += 1
	_play_current_line()

func _end_dialogue():
	is_dialogue_active = false
	is_typing = false
	dialogue_box.visible = false
	current_sequence.clear()
	dialogue_finished.emit()

func skip_typing():
	if is_typing:
		is_typing = false
		content_label.text = target_text
		line_finished.emit()
		_check_line_completion()

func _input(event):
	if not is_dialogue_active:
		return
	
	if event.is_action_pressed("ui_accept"):  
		if is_typing:
			skip_typing()

func is_playing_dialogue() -> bool:
	return is_dialogue_active
