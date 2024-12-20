extends Node3D

@onready var _camera = $Camera3D
@onready var _hand_pos = $"Camera3D/littlegirl/手持"
@onready var _fang_kuai = $"Camera3D/littlegirl/手持/方块"
@onready var _bao_jian = $"Camera3D/littlegirl/手持/宝剑"
@onready var camara_third = $third
@onready var camara_third_real = $third/Camera3D2
var base_camera = Vector3.ZERO					# 摄影机位置

var shake_degree = 0								# 当前摇晃程度
var shake_direction = 1							# 当前摇晃方向
var base_shake = Vector3.ZERO					# 手持方块基础位置
var base_shake_r = Vector3.ZERO					# 手持方块基础方向



@export var  sens_horizonal = 0.2 #第三视角的水平灵敏度
@export var  sens_vertical = 0.2 #第三视角的垂直灵敏度

var hand_have = 1								# 1表示宝剑，2表示方块
var gravity_mode = 0								# 0表示垂直向下，1表示球体

var plane = Vector3(0, 1, 0)

func _ready() -> void:
	# 记录初始手持方块位置及方向
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	base_shake = _hand_pos.position
	base_shake_r = _hand_pos.rotation
	base_camera = $"Camera3D".position
	

func get_input(game_mode):
	
	#设置第一、三人称的摄像机、调整方向向量的获取
	if game_mode == 1:
		_camera =camara_third_real
	elif game_mode == 0:
		_camera = $Camera3D
		
	# 求出水平移动方向
	var forward = _camera.basis.z * -1
	forward = Plane(plane, 0).project(forward).normalized()
	var right = _camera.basis.x
	
	
	var direction = Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		direction += forward
	if Input.is_key_pressed(KEY_S):
		direction -= forward
	if Input.is_key_pressed(KEY_D):
		direction += right
	if Input.is_key_pressed(KEY_A):
		direction -= right
	# 可能要换手中的东西
	hand_switch()
	# 可能改变重力模式
	gravity_switch()
	# 手动调节人物朝向
	if Input.is_key_pressed(KEY_T):
		rotation_adapt()
	# 速度归一化
	var velocity = direction.normalized()
	# 疾跑与潜行特判
	var run = 1
	$"Camera3D".set_position(base_camera)
	if Input.is_key_pressed(KEY_SHIFT):
		run = 2.0 / 3
		$"Camera3D".set_position(base_camera - Vector3(0, 0.3, 0))
	elif Input.is_key_pressed(KEY_CTRL):
		run = 3
	velocity *= run
	# 水平速度不为0则开启摇晃视角

	if direction != Vector3.ZERO:
		hand_shake(run)
	
	# 速度赋值
	$".".linear_velocity.x = velocity.x * 5
	$".".linear_velocity.z = velocity.z * 5
	# 跳跃特判
	if Input.is_action_just_pressed("Action_Space"):
		f_jump()

func f_jump():									# 跳跃的回调函数
	# 直接给垂直方向加一个速度
	$".".linear_velocity.y += 35
	# 给跳跃速度一个上限
	$".".linear_velocity.y = min(30, $".".linear_velocity.y)

func hand_switch():								# 换手上的东西
	if hand_have != 2 and Input.is_key_pressed(KEY_2):
		_fang_kuai.set_visible(true)
		_bao_jian.set_visible(false)
		hand_have = 2
	if hand_have != 1 and Input.is_key_pressed(KEY_1):
		_fang_kuai.set_visible(false)
		_bao_jian.set_visible(true)
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
				pass
			else:
				$".".rotation = Vector3(0, 0, -PI / 2)
				plane = Vector3(-1, 0, 0)
		if abs(dir.z) > abs(dir.y) and abs(dir.z) > abs(dir.x):
			if dir.z > 0:
				$".".rotation = Vector3(-PI / 2, 0, 0)
			else:
				$".".rotation = Vector3(PI / 2, 0, 0)
				
func hand_shake(run):							# 做出走路摇晃特效
	if shake_direction == 1:
		shake_degree += 0.0015 * run
		if shake_degree > 0.1:
			shake_direction = -1
	else:
		shake_degree -= 0.0015 * run
		if shake_degree < -0.05:
			shake_direction = 1
	if hand_have == 2:
		# x轴做左右摇晃
		_hand_pos.position.x = base_shake.x + shake_degree * 1.3
		# y轴做“U字型”
		_hand_pos.position.y = base_shake.y + abs(shake_degree)
		# z轴稍微运动即可
		_hand_pos.position.z = base_shake.z + abs(shake_degree) * 0.1
		# 带上一点旋转
		_hand_pos.rotation.x = base_shake_r.x - shake_degree
		_hand_pos.rotation.y = base_shake_r.y - shake_degree
	if hand_have == 1:
		# x轴做左右摇晃
		_hand_pos.position.x = base_shake.x + shake_degree * 0.5
		# y轴做“U字型”
		_hand_pos.position.y = base_shake.y + abs(shake_degree) * 0.5
		# z轴稍微运动即可
		_hand_pos.position.z = base_shake.z + abs(shake_degree) * 0.2
		# 带上一点旋转
		_hand_pos.rotation.x = base_shake_r.x + shake_degree
		_hand_pos.rotation.y = base_shake_r.y - shake_degree * 0.5

func _process(delta: float) -> void:
	
	
	#切换一、三视角
	if Input.is_key_pressed(KEY_F1):
		get_node("third/Camera3D2").make_current()
		_camera = camara_third_real
		$Global.game_mode = 1
	elif Input.is_key_pressed(KEY_F2):
		get_node("Camera3D").make_current()
		_camera = $Camera3D
		$Global.game_mode = 0
	'''
	elif Input.is_key_pressed(KEY_F3):
		get_node("god_Camera").make_current()
		_camera = $god_Camera
		$Global.game_mode = 0
	'''	
	# 获得方向向量
	var forward = _camera.basis.z * -1
	forward = Plane(plane, 0).project(forward).normalized()
	var right = _camera.basis.x
	# print("forward: " + str(forward))
	# print("right: " + str(right))
	var temp_text  = ""
	temp_text += "x:" + str($".".position.x) + "\n"
	temp_text += "y:" + str($".".position.y) + "\n"
	temp_text += "z:" + str($".".position.z) + "\n"
	temp_text += "now_x:" + str(_camera.basis.x) + "\n"
	temp_text += "now_y:" + str(_camera.basis.y) + "\n"
	temp_text += "now_z:" + str(_camera.basis.z) + "\n"
	temp_text += "now_forward:" + str(forward) + "\n"
	temp_text += "now_right:" + str(right) + "\n"
	#$"../Debug参数".set_text(temp_text)
	# 输入判断模块
	#get_input(forward, right)
	get_input($Global.game_mode)
	
	# 人工重力
	if gravity_mode == 0:						# 垂直重力
		if $".".linear_velocity.y > -10:
			$".".linear_velocity.y += -0.15 * delta * 500
	else:										# 球体重力
		# 求球心方向
		var dir = $"Global".get_dir_to_core($".".position) * 10
		# 求向心线速度
		var now_linear_v = $".".linear_velocity.project(dir)
		if min(now_linear_v.x, now_linear_v.y, now_linear_v.z) > -10:
			$".".linear_velocity = $".".linear_velocity.move_toward(dir, delta * 80)
			
	
