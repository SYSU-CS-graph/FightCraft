extends Camera3D

@export var _sensitive = 0.003
@export var _max_angle = deg_to_rad(10)
@export var _min_angle = deg_to_rad(-10)
@export var _distance = 1.0  # 摄像机与角色模型的距离

var _pitch := 0.0
var _yaw := 0.0

# 角色模型的节点路径，需要根据你的实际路径来设置
var character_node_path := "../../Camera3D/littlegirl"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var motion = event.relative * _sensitive
		_pitch -= motion.y
		_pitch = clamp(_pitch, _min_angle, _max_angle)
		_yaw -= motion.x

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var character = get_node(character_node_path)
	if character:
		# 获取角色模型的全局坐标
		var character_global_transform = character.global_transform
		
		# 计算摄像机的新位置
		var offset = Vector3(0.75, 1.5, 3)  # 默认相对于角色的距离
		offset = offset.rotated(Vector3(0, 1, 0), _yaw)  # 只旋转偏航（水平旋转）
		offset = offset.rotated(Vector3(1, 0, 0), _pitch)  # 只旋转俯仰（垂直旋转）

		# 更新摄像机的位置
		global_transform.origin = character_global_transform.origin + offset
		
		# 使用look_at使摄像机始终朝向角色模型
		look_at(Vector3(character_global_transform.origin.x,character_global_transform.origin.y + 1,character_global_transform.origin.z), Vector3(0, 1, 0))
