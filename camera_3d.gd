extends Camera3D

@export var _sensitive = 0.004
@export var _max_angle = 1.57
@export var _min_angle = -1.57

var _pitch := 0.0
var _yaw := 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		var motion = event.relative * _sensitive
		_pitch -= motion.y
		_pitch = clamp(_pitch, _min_angle, _max_angle)
		_yaw -= motion.x

		rotation = Vector3()
		rotate_x(_pitch)
		rotate_y(_yaw)
