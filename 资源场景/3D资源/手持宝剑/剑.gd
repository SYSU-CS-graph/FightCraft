extends RigidBody3D

signal hit_plane

func _ready() -> void:
	# 信号连接
	$"计时器".timeout.connect(time_over)
	# 开始计时
	$"计时器".start(3)

func time_over():							# 计时到了视为接触地面
	hit_plane.emit()

func _process(_delta: float) -> void:
	# 接触地面或物体发出信号
	if global_position.y < -1 or linear_velocity.y > -1:
		hit_plane.emit()
