extends Node3D

# Rotation speed (radians per second)
@export var rotation_speed: float = 1.0

# Rotation axes - set to true for axes you want to rotate around
@export var rotate_x: bool = false
@export var rotate_y: bool = true
@export var rotate_z: bool = false

func _ready():
	# Any initialization code can go here
	pass

func _process(delta):
	# Calculate rotation amount for this frame
	var rotation_amount = rotation_speed * delta
	
	# Apply rotation to the specified axes
	if rotate_x:
		rotate_object_local(Vector3.RIGHT, rotation_amount)
	if rotate_y:
		rotate_object_local(Vector3.UP, rotation_amount)
	if rotate_z:
		rotate_object_local(Vector3.FORWARD, rotation_amount)

# Alternative method using rotation_degrees for easier tweaking
func _process_alternative(delta):
	# Uncomment this method and comment out the above _process if you prefer degree-based rotation
	var rotation_degrees_per_second = 30.0  # Adjust this value as needed
	
	if rotate_y:
		rotation_degrees.y += rotation_degrees_per_second * delta
