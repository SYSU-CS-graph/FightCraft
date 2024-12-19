extends Camera3D

# 装饰器方便修改
@export var _sensitive = 0.003
@export var _max_angle = 1.57
@export var _min_angle = -1.57

var _pitch := 0.0
var _yaw := 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		var motion = event.relative * _sensitive
		_pitch -= motion.y
		_pitch = clamp(_pitch, _min_angle, _max_angle)
		_yaw -= motion.x

		rotation = Vector3()
		rotate_x(_pitch)
		rotate_y(_yaw)
