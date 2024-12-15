extends Node3D

# 导出参数，可以在编辑器中调整
@export var rotation_speed: float = 0.3    # 公转速度
@export var self_rotation_speed: float = 1.0 # 自转速度
@export var orbit_radius: float = 280.0        # 公转半径

# 当前的公转角度
var angle: float = 0.0

func _process(delta: float) -> void:
	# 更新公转角度
	angle += rotation_speed * delta
	
	# 计算公转路径的位置，使节点绕着一个重心点公转
	var z = orbit_radius * cos(angle)
	var y = orbit_radius * sin(angle)
	position = Vector3(position.x, y, z)
	
	# 自转（让节点自身旋转）
	rotation.y += self_rotation_speed * delta
