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
	var csv_data = parse_csv_robust(csv_file_path)
	
	if csv_data.size() <= 1:  
		print("Error: No dialogue data found in CSV")
		return
	
	for i in range(1, csv_data.size()):
		var row = csv_data[i]
		if row.size() >= 3:  
			var id = int(row[0])
			var dialogue = row[1]
			var type = row[2]
			
			dialogue_data[id] = DialogueLine.new(id, dialogue, type)
	
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

func parse_csv_robust(file_path: String) -> Array:
	var file = FileAccess.open(file_path, FileAccess.READ)
	var result = []
	
	if not file:
		print("Error: Could not open file at ", file_path)
		return result
	
	var content = file.get_as_text()
	file.close()
	
	var lines = content.split("\n")
	for line in lines:
		if line.strip_edges() == "":
			continue
			
		var row = []
		var current_field = ""
		var in_quotes = false
		var i = 0
		
		while i < line.length():
			var char = line[i]
			
			if char == '"':
				in_quotes = !in_quotes
			elif char == ',' and not in_quotes:
				row.append(current_field.strip_edges())
				current_field = ""
			else:
				current_field += char
			i += 1
		
		row.append(current_field.strip_edges())
		result.append(row)
	
	return result
