extends OmniLight3D

@export var rotation_speed: float = 0.3      # 公转速度

@export var orbit_radius: float = 280.0+40.1       # 公转半径

# 当前的公转角度
var angle: float = 0.0
# 这一角度用于后左光源和后右光源，偏移角度，以确保整个太阳的模型被照亮
var angle_delta:float = 0.2


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# 更新公转角度
	angle += rotation_speed * delta 
	
	# 计算公转路径的位置，使节点绕着一个重心点公转
	var z = orbit_radius * cos(angle+angle_delta)
	var y = orbit_radius * sin(angle+angle_delta)
	position = Vector3(position.x, y, z)
	
