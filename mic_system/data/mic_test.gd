extends Node

var process_id = -1
var timer: Timer
var is_recording = false
@export var keywords: Array[String] = []

# Add a signal for voice commands
signal voice_fetch_triggered

func _ready() -> void:
	start_recording()
	
func start_recording():
	var file = FileAccess.open("res://mic_system/transcription.txt", FileAccess.WRITE)
	if file:
		file.close()
	
	var bat_script_path = ProjectSettings.globalize_path("res://run_py.bat")
	
	process_id = OS.create_process(bat_script_path, [])
	print("Started speech recognition script, process ID: ", process_id)
	
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = 0.1
	timer.timeout.connect(_check_transcription_file)
	timer.start()
	
	is_recording = true

func stop_recording():
	if timer:
		timer.queue_free()
	if process_id != -1:
		OS.execute("taskkill", ["/F", "/IM", "python.exe"])
		process_id = -1
	
	is_recording = false
	print("Stopped speech recognition")

func _check_transcription_file():
	var file = FileAccess.open("res://mic_system/transcription.txt", FileAccess.READ)
	if file:
		var content = file.get_as_text().to_lower() 
		file.close()
		print("Transcription: ", content)
		
		for keyword in keywords:
			var keyword_lower = keyword.to_lower()
			
			if keyword_lower != "" and content.find(keyword_lower) != -1:
				print("Keyword detected: '", keyword, "'")
				
				# Trigger action specifically for "fetch"
				if keyword_lower == "fetch":
					trigger_action(keyword)
		
func add_keyword(keyword: String):
	keywords.append(keyword)

func trigger_action(keyword: String):
	print("Triggering action for keyword: ", keyword)
	if keyword.to_lower() == "fetch":
		emit_signal("voice_fetch_triggered")
		print("Voice fetch signal emitted!")
