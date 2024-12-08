extends Node3D

@onready var _camera = $Camera3D

var shake_degree = 0								# 当前摇晃程度
var shake_direction = 1							# 当前摇晃方向
var base_shake = Vector3.ZERO					# 手持方块基础位置
var base_shake_r = Vector3.ZERO					# 手持方块基础方向

var hand_have = 1								# 1表示宝剑，2表示方块
var gravity_mode = 0								# 0表示垂直向下，1表示球体

var plane = Vector3(0, 1, 0)

func _ready() -> void:
	# 记录初始手持方块位置及方向
	base_shake = $"Camera3D/手持".position
	base_shake_r = $"Camera3D/手持".rotation

func get_input(forward, right):					# 输入判断集成
	# 求出水平移动方向
	var direction = Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		direction += forward
	if Input.is_key_pressed(KEY_S):
		direction -= forward
	if Input.is_key_pressed(KEY_D):
		direction += right
	if Input.is_key_pressed(KEY_A):
		direction -= right
	# 水平速度不为0则开启摇晃视角
	if direction != Vector3.ZERO:
		hand_shake()
	# 可能要换手中的东西
	hand_switch()
	# 可能改变重力模式
	gravity_switch()
	# 手动调节任务朝向
	if Input.is_key_pressed(KEY_T):
		rotation_adapt()
	# 速度归一化
	var velocity = direction.normalized()
	# 疾跑特判
	if Input.is_key_pressed(KEY_CTRL):
		velocity *= 5
	# 速度赋值
	$".".linear_velocity.x = velocity.x * 5
	$".".linear_velocity.z = velocity.z * 5
	# 跳跃特判
	if Input.is_action_just_pressed("Action_Space"):
		f_jump()

func f_jump():									# 跳跃的回调函数
	# 直接给垂直方向加一个速度
	$".".linear_velocity.y += 35

func hand_switch():								# 换手上的东西
	if hand_have == 1 and Input.is_key_pressed(KEY_2):
		$"Camera3D/手持/方块".set_visible(true)
		$"Camera3D/手持/宝剑".set_visible(false)
		hand_have = 2
	if hand_have == 2 and Input.is_key_pressed(KEY_1):
		$"Camera3D/手持/方块".set_visible(false)
		$"Camera3D/手持/宝剑".set_visible(true)
		hand_have = 1

func gravity_switch():							# 切换重力模式
	if Input.is_key_pressed(KEY_G):
		gravity_mode = 1
	if Input.is_key_pressed(KEY_H):
		gravity_mode = 0

func rotation_adapt():							# 手动重力适应
	if gravity_mode == 1:
		# 旋转至对应位置
		# 求球心方向的abs
		var dir = $"Global".get_dir_to_core($".".position)
		if abs(dir.y) > abs(dir.x) and abs(dir.y) > abs(dir.z):
			$".".rotation = Vector3.ZERO
			plane = Vector3(0, 1, 0)
		if abs(dir.x) > abs(dir.y) and abs(dir.x) > abs(dir.z):
			if dir.x > 0:
				$".".rotation = Vector3(0, 0, PI / 2)
				# 法线方向待修改
				# plane = Vector3(1, 0, 0)
			else:
				$".".rotation = Vector3(0, 0, -PI / 2)
				# plane = Vector3(-1, 0, 0)
		if abs(dir.z) > abs(dir.y) and abs(dir.z) > abs(dir.x):
			if dir.z > 0:
				$".".rotation = Vector3(-PI / 2, 0, 0)
				# plane = Vector3(0, 0, -1)
			else:
				$".".rotation = Vector3(PI / 2, 0, 0)
				# plane = Vector3(0, 0, 1)

func hand_shake():								# 做出走路摇晃特效
	if shake_direction == 1:
		shake_degree += 0.0015
		if shake_degree > 0.1:
			shake_direction = -1
	else:
		shake_degree -= 0.0015
		if shake_degree < -0.05:
			shake_direction = 1
	if hand_have == 2:
		# x轴做左右摇晃
		$"Camera3D/手持".position.x = base_shake.x + shake_degree * 1.3
		# y轴做“U字型”
		$"Camera3D/手持".position.y = base_shake.y + abs(shake_degree)
		# z轴稍微运动即可
		$"Camera3D/手持".position.z = base_shake.z + abs(shake_degree) * 0.1
		# 带上一点旋转
		$"Camera3D/手持".rotation.x = base_shake_r.x - shake_degree
		$"Camera3D/手持".rotation.y = base_shake_r.y - shake_degree
	if hand_have == 1:
		# x轴做左右摇晃
		$"Camera3D/手持".position.x = base_shake.x + shake_degree * 0.5
		# y轴做“U字型”
		$"Camera3D/手持".position.y = base_shake.y + abs(shake_degree) * 0.5
		# z轴稍微运动即可
		$"Camera3D/手持".position.z = base_shake.z + abs(shake_degree) * 0.2
		# 带上一点旋转
		$"Camera3D/手持".rotation.x = base_shake_r.x + shake_degree
		$"Camera3D/手持".rotation.y = base_shake_r.y - shake_degree * 0.5

func _process(delta: float) -> void:
	
	# 获得方向向量
	var forward = _camera.basis.z*-1
	forward = Plane(plane, 0).project(forward).normalized()
	var right = _camera.basis.x
	
	# 输入判断模块
	get_input(forward, right)
	
	# 人工重力
	if gravity_mode == 0:						# 垂直重力
		if $".".linear_velocity.y > -10:
			$".".linear_velocity.y += -0.15 * delta * 500
	else:										# 球体重力
		# 求球心方向
		var dir = $"Global".get_dir_to_core($".".position) * 10
		# 求向心线速度
		var now_linear_v = $".".linear_velocity.project(dir)
		print(dir)
		if min(now_linear_v.x, now_linear_v.y, now_linear_v.z) > -10:
			$".".linear_velocity = $".".linear_velocity.move_toward(dir, delta * 80)
