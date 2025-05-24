extends Node
class_name CSVDialogueLoader

class DialogueLine:
	var id: int
	var dialogue: String
	var type: String
	
	func _init(p_id: int, p_dialogue: String, p_type: String):
		id = p_id
		dialogue = p_dialogue
		type = p_type

var dialogue_data: Dictionary = {}
var csv_file_path: String = "res://csv/test.csv"

func _ready():
	load_dialogue_csv()

func load_dialogue_csv():
	var file = FileAccess.open(csv_file_path, FileAccess.READ)
	
	if not file:
		print("Error: Could not open file at ", csv_file_path)
		return
	
	var content = file.get_as_text()
	file.close()
	
	if content == "":
		print("Error: CSV file is empty")
		return
	
	var lines = content.split("\n")
	var line_count = 0
	
	for line in lines:
		line = line.strip_edges()
		if line == "":
			continue
		
		line_count += 1
		if line_count == 1:
			continue
		
		var parts = line.split(",")
		if parts.size() >= 3:
			var id_str = parts[0].strip_edges()
			var dialogue = parts[1].strip_edges()
			var type = parts[2].strip_edges()
			
			if id_str.is_valid_int():
				var id = int(id_str)
				dialogue_data[id] = DialogueLine.new(id, dialogue, type)
			else:
				print("Warning: Invalid ID in line: ", line)
	
	print("Dialogue CSV loaded! Found dialogue IDs: ", dialogue_data.keys())

func get_dialogue_sequence(start_id: int) -> Array:
	var sequence = []
	var current_id = start_id
	
	while dialogue_data.has(current_id):
		var line = dialogue_data[current_id]
		sequence.append(line)
		
		if line.type == "END":
			break
			
		current_id += 1
	
	if sequence.size() == 0:
		print("Warning: Dialogue ID ", start_id, " not found!")
	else:
		print("Built sequence from ID ", start_id, " with ", sequence.size(), " lines")
	
	return sequence

func get_dialogue_text_only(start_id: int) -> Array:
	var sequence = get_dialogue_sequence(start_id)
	var text_only = []
	for line in sequence:
		text_only.append(line.dialogue)
	return text_only

func debug_print_sequence(start_id: int):
	var sequence = get_dialogue_sequence(start_id)
	if sequence.size() > 0:
		print("=== Dialogue Sequence starting from ID ", start_id, " ===")
		for line in sequence:
			print("ID ", line.id, " - ", line.type, ": ", line.dialogue)
		print("========================")

func get_dialogue_line(dialogue_id: int) -> DialogueLine:
	if dialogue_data.has(dialogue_id):
		return dialogue_data[dialogue_id]
	return null

func has_dialogue(dialogue_id: int) -> bool:
	return dialogue_data.has(dialogue_id)
