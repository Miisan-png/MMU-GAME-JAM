extends Node

@onready var output_label = $output
@onready var run_button = $run_py

var process_id = -1
var timer: Timer
var is_recording = false

func _on_run_py_pressed() -> void:
	if not is_recording:
		start_recording()
	else:
		stop_recording()

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
	run_button.text = "Stop"

func stop_recording():
	if timer:
		timer.queue_free()
	if process_id != -1:
		OS.execute("taskkill", ["/F", "/IM", "python.exe"])
		process_id = -1
	
	is_recording = false
	run_button.text = "Run"
	print("Stopped speech recognition")

func _check_transcription_file():
	var file = FileAccess.open("res://mic_system/transcription.txt", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		output_label.text = content
