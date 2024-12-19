extends Node3D

@onready var _camera = $Camera3D

var base_camera = Vector3.ZERO					# 摄影机位置

var shake_degree = 0								# 当前摇晃程度
var shake_direction = 1							# 当前摇晃方向
var base_shake = Vector3.ZERO					# 手持方块基础位置
var base_shake_r = Vector3.ZERO					# 手持方块基础方向
var walking_rate = 1.0							# 走路速度
var running_rate = 3.0							# 疾跑速度 

var hand_have = 1								# 1表示宝剑，2表示石质方块，3表示实体剑,4表示普通方块
var gravity_mode = 0								# 0表示垂直向下，1表示球体

var plane = Vector3(0, 1, 0)						# 平面法线方向

var base_sword_pos = Vector3.ZERO				# 宝剑基础位置
var base_sword_rot = Vector3.ZERO				# 宝剑初始角度
var attack_time = 0.35							# 挥砍用时
var is_attacking = false							# 是否进行攻击
var attack_times = -1							# 第几下连击(未攻击时为-1)
var can_attack = true							# 能否追加攻击，攻击计时器控制
var not_attack = false							# 是否不能追加攻击，追击计时器控制
var is_freezed = false							# 是否处于硬直，硬直计时器控制
var is_attack_back = false						# 是否挥砍归位

var sword_start_pos_1 = Vector3(0.12, 0.57, -0.06)	# 第一刀起始位置
var sword_end_pos_1 = Vector3(-0.92, -0.15, -1.05)	# 第一刀结束位置
var sword_start_rot_1 = Vector3(0.47, 0.67, -1.82)	# 第一刀起始角度
var sword_end_rot_1 = Vector3(0.73, 0.47, -1.79)		# 第一刀起始角度

var sword_start_pos_2 = Vector3(-0.82, 0.18, -1.32)	# 第二刀起始位置
var sword_end_pos_2 = Vector3(-0.029, -0.05, -0.039)	# 第二刀结束位置
var sword_start_rot_2 = Vector3(0.94, 3.94 , -0.15)	# 第二刀起始角度
var sword_end_rot_2 = Vector3(1.37, -0.067, -2.2)		# 第二刀结束角度

var hash_shock_wave = { }							# 冲击波表

var attack_text = 0									# 当前攻击状态(用于打印)
var attack_text_list = ["就绪", "硬直", "可追击", "冷却中"]

var drop_attack_CD = 5								# 技能CD
var is_drop_freezed = false							# 是否处于冷却
var is_aiming = false								# 是否处于瞄准状态

var need_place_assist = true							# 默认要吸附网格
var is_placing = false								# 是否即将放置
var is_replacing = false								# 是否即将要拆除

var hash_node_stone = { }							# 存放石头节点的表

var is_alive = true									# 没被怪物抓到
var is_horror = false								# 是否处于恐怖模式
var breath_num = 0									# 呼吸数(影响音量)
var scared_direction = true							# 被吓到时的振动方向

func _ready() -> void:
	# 信号连接
	$"攻击计时器".timeout.connect(soft_attack_end)
	$"追击计时器".timeout.connect(soft_attack_append)
	$"硬直计时器".timeout.connect(soft_attack_reset)
	$"召唤计时器".timeout.connect(drop_attack_reset)
	# 记录初始手持方块位置及方向
	base_shake = $"Camera3D/手持".position
	base_shake_r = $"Camera3D/手持".rotation
	base_camera = $"Camera3D".position
	base_sword_pos = $"Camera3D/手持/宝剑".position
	base_sword_rot = $"Camera3D/手持/宝剑".rotation
	# 输入不要累计
	# Input.use_accumulated_input = false
	# print(Input.use_accumulated_input)
	# print($"Camera3D/手持/宝剑".position)
	# print($"Camera3D/手持/宝剑".rotation)

func get_input(forward, right):						# 输入判断集成
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
	# 可能要换手中的东西
	hand_switch()
	# 可能改变重力模式
	gravity_switch()
	# 手动调节任务朝向
	if Input.is_key_pressed(KEY_T):
		rotation_adapt()
	# 速度归一化
	var velocity = direction.normalized()
	# 疾跑与潜行特判
	var run = walking_rate
	$"Camera3D".set_position(base_camera)
	if Input.is_key_pressed(KEY_SHIFT):
		run = run * 2.0 / 3
		$"Camera3D".set_position(base_camera - Vector3(0, 0.3, 0))
	elif Input.is_key_pressed(KEY_CTRL):
		run = run * running_rate
		# 恐怖模式中，疾跑情况下有呼吸声
		if is_horror:
			if not $"玩家呼吸声".is_playing():
				$"玩家呼吸声".set_volume_db(- 30 * breath_num)
				$"玩家呼吸声".play()
				breath_num += 1
				if breath_num == 3:
					breath_num = 0
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
	# 攻击判断
	# 2D宝剑的挥砍和技能
	if hand_have == 1:
		if Input.is_action_just_pressed("Action_Click"):
			soft_attack()
		if not is_drop_freezed:
			# 按下瞄准
			if Input.is_action_pressed("Action_Click_R"):
				pre_attack()
			# 正在瞄准并松开释放
			if is_aiming and Input.is_action_just_released("Action_Click_R"):
				drop_attack()
	# 切换是否要网格吸附放置方块
	if Input.is_action_just_released("Action_B"):
		need_place_assist = not need_place_assist
	# 石质方块的放置和拆除
	if hand_have == 2:
		# 拆除
		if Input.is_action_pressed("Action_Click"):
			pre_replace()
		if is_replacing and Input.is_action_just_released("Action_Click"):
			replace_it()
		# 按下瞄准
		if Input.is_action_pressed("Action_Click_R"):
			pre_place()
		# 松开放置
		if is_placing and Input.is_action_just_released("Action_Click_R"):
			place_it()
	# 手电开关
	if Input.is_action_just_pressed("Action_E"):
		$"Camera3D/恐怖模式光源".visible = not $"Camera3D/恐怖模式光源".visible
		$"手电音效".play()

func f_jump():										# 跳跃的回调函数
	# 直接给垂直方向加一个速度
	$".".linear_velocity.y += 35
	# 给跳跃速度一个上限
	$".".linear_velocity.y = min(30, $".".linear_velocity.y)

func hand_switch():									# 换手上的东西
	if hand_have != 4 and Input.is_key_pressed(KEY_4):
		$"Camera3D/手持/石质方块".set_visible(false)
		$"Camera3D/手持/宝剑".set_visible(false)
		$"Camera3D/手持/实体剑".set_visible(false)
		$"Camera3D/手持/方块".set_visible(true)
		hand_have = 4
	if hand_have != 3 and Input.is_key_pressed(KEY_3):
		$"Camera3D/手持/石质方块".set_visible(false)
		$"Camera3D/手持/宝剑".set_visible(false)
		$"Camera3D/手持/实体剑".set_visible(true)
		$"Camera3D/手持/方块".set_visible(false)
		hand_have = 3
	if hand_have != 2 and Input.is_key_pressed(KEY_2):
		$"Camera3D/手持/石质方块".set_visible(true)
		$"Camera3D/手持/宝剑".set_visible(false)
		$"Camera3D/手持/实体剑".set_visible(false)
		$"Camera3D/手持/方块".set_visible(false)
		hand_have = 2
	if hand_have != 1 and Input.is_key_pressed(KEY_1):
		$"Camera3D/手持/石质方块".set_visible(false)
		$"Camera3D/手持/宝剑".set_visible(true)
		$"Camera3D/手持/实体剑".set_visible(false)
		$"Camera3D/手持/方块".set_visible(false)
		hand_have = 1
	# 防止一些因为瞄准中切换导致的问题
	if hand_have != 2:
		$"方块瞄准".visible = false
		$"方块移除瞄准".visible = false
	if hand_have != 1:
		$"宝剑释放瞄准".visible = false

func gravity_switch():								# 切换重力模式
	if Input.is_key_pressed(KEY_G):
		gravity_mode = 1
	if Input.is_key_pressed(KEY_H):
		gravity_mode = 0

func rotation_adapt():								# 手动重力适应
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

func hand_shake(run):								# 做出走路摇晃特效
	if shake_direction == 1:
		shake_degree += 0.0015 * run
		if shake_degree > 0.1:
			shake_direction = -1
			# 恐怖模式加脚步声
			if is_horror:
				$"玩家脚步声".play()
	else:
		shake_degree -= 0.0015 * run
		if shake_degree < -0.05:
			shake_direction = 1
			# 恐怖模式加脚步声
			if is_horror:
				$"玩家脚步声".play()
	if hand_have == 2 or hand_have == 4:
		# x轴做左右摇晃
		$"Camera3D/手持".position.x = base_shake.x + shake_degree * 1.3
		# y轴做“U字型”
		$"Camera3D/手持".position.y = base_shake.y + abs(shake_degree)
		# z轴稍微运动即可
		$"Camera3D/手持".position.z = base_shake.z + abs(shake_degree) * 0.1
		# 带上一点旋转
		$"Camera3D/手持".rotation.x = base_shake_r.x - shake_degree
		$"Camera3D/手持".rotation.y = base_shake_r.y - shake_degree
	if hand_have == 1 or hand_have == 3:
		# x轴做左右摇晃
		$"Camera3D/手持".position.x = base_shake.x + shake_degree * 0.5
		# y轴做“U字型”
		$"Camera3D/手持".position.y = base_shake.y + abs(shake_degree) * 0.5
		# z轴稍微运动即可
		$"Camera3D/手持".position.z = base_shake.z + abs(shake_degree) * 0.2
		# 带上一点旋转
		$"Camera3D/手持".rotation.x = base_shake_r.x + shake_degree
		$"Camera3D/手持".rotation.y = base_shake_r.y - shake_degree * 0.5

func soft_attack():									# 挥砍攻击
	"""
	print("点击鼠标")
	print("is_attacking:" + str(is_attacking))
	print("  can_attack:" + str(can_attack))
	print("  not_attack:" + str(not_attack))
	print("is_attacking:" + str(is_attacking))
	print("  is_freezed:" + str(is_freezed))
	"""
	if is_attacking:
		if attack_times >= 2:		# 最多连砍两次
			pass
		elif can_attack == false:	# 正在挥砍时不能追加
			pass 
		elif not_attack == true:		# 不可追击时也跳过
			pass
		else:
			attack_times += 1		# 次数递增
			is_freezed = false		# 解除冷却
	else:
		is_attacking = true			# 正在挥砍
		attack_times = 0				# 第一次砍设为0

func soft_attack_manage():							# soft_attack内部实现
	
	if attack_times == 0:		# 第一下
		
		print("attack 0")
		
		# 开启攻击计时器
		$"攻击计时器".start(attack_time)
		# 暂时不能够追加攻击直到攻击计时器结束
		can_attack = false
		
		# 开启一次追击计时，计时内可以挥第二下
		$"追击计时器".start(1.2)
		# 可以追加攻击直到追击计时器结束
		not_attack = false
		
		# 开启一次硬直(本次可被追击打断)
		$"硬直计时器".start(2.2)
		is_freezed = true
		
		# 右边发出挥砍音效
		$"Camera3D/挥刀音效_右".play()
		
		# 发波
		send_shock_wave()
		
		# 进入硬直
		attack_text = 1
		
	elif attack_times == 1:		# 第二下
		# 重置前一次硬直
		$"硬直计时器".stop()
		
		print("attack 1")
		
		# 开启攻击计时器
		$"攻击计时器".start(attack_time)
		# 不能够追加攻击
		can_attack = false
		
		# 也不能追击
		not_attack = true
		
		# 开启一次硬直(本次没法被打断)
		$"硬直计时器".start(1)
		is_freezed = true
		
		# 左边发出挥砍音效
		$"Camera3D/挥刀音效_左".play()
		
		# 发波
		send_shock_wave()
		
		# 进入硬直
		attack_text = 1

func soft_attack_end():								# soft_attack计时结束回调
	# print("可追击")
	# 能够再攻击
	can_attack = true
	# 若第一下则可追击，第二下则直接进入冷却
	if attack_times == 0:
		attack_text = 2
	else:
		attack_text = 3

func soft_attack_append():							# soft_attack追击
	# print("不能追击")
	# 不能在追加攻击
	not_attack = true
	# 设置标签为冷却中
	attack_text = 3

func soft_attack_reset():							# soft_attack重置
	# print("重置")
	# 重置次数
	is_attacking = false
	attack_times = -1
	# 结束硬直
	is_freezed = false
	# 开启可以攻击(因为第二次攻击没有开攻击计时器所以这里要设置)
	can_attack = true
	# 允许攻击
	not_attack = false
	# 设置显示标签为就绪
	attack_text = 0

func soft_attack_body():								# soft_attack实现主体
	# 计算比例
	var ratio = (attack_time - $"攻击计时器".time_left) / attack_time
	# 判断是否需要归位
	if ratio == 1:
		is_attack_back = true
	else:
		is_attack_back = false
	# 挥砍动画
	if attack_times == 0:		# 第一砍
		$"Camera3D/手持/宝剑".position = sword_start_pos_1.lerp(sword_end_pos_1, ratio)
		$"Camera3D/手持/宝剑".rotation = sword_start_rot_1.lerp(sword_end_rot_1, ratio)
	elif attack_times == 1:		# 第二砍
		$"Camera3D/手持/宝剑".position = sword_start_pos_2.lerp(sword_end_pos_2, ratio)
		$"Camera3D/手持/宝剑".rotation = sword_start_rot_2.lerp(sword_end_rot_2, ratio)

func soft_attack_back():								# soft_attack硬直回复原位置
	$"Camera3D/手持/宝剑".position = 0.995 * $"Camera3D/手持/宝剑".position + 0.005 * base_sword_pos
	$"Camera3D/手持/宝剑".rotation = 0.993 * $"Camera3D/手持/宝剑".rotation + 0.007 * base_sword_rot

func send_shock_wave():								# 向前发冲击波
	# 创建冲击波
	var node = preload("res://粒子特效/冲击波.tscn").instantiate()
	# 添加到根场景中
	get_parent().add_child(node)
	# 设定该方块的位置
	node.position = $".".position
	# 设定速度和方向
	var dir = (_camera.basis.z * -1).normalized()
	var rot = _camera.rotation
	node.init(dir, rot, attack_times)
	# 放入dict方便管理
	hash_shock_wave[len(hash_shock_wave)] = node

func pre_attack():									# 预先按住设定宝剑释放位置
	# 让瞄准处于目标位置
	$"宝剑释放瞄准".position = _camera.position + _camera.basis.z * -1 * 15
	# 没有瞄准则瞄准
	if not is_aiming or $"宝剑释放瞄准".visible == false:
		# 让其可见
		$"宝剑释放瞄准".visible = true
		# 正在瞄准
		is_aiming = true

func drop_attack():									# 召唤宝剑技能
	# 让瞄准不可见
	$"宝剑释放瞄准".visible = false
	# 瞄准结束
	is_aiming = false
	# 进入CD
	is_drop_freezed = true
	# CD开始计时
	$"召唤计时器".start(drop_attack_CD)
	# 释放下落宝剑
	# 创建
	var node = preload("res://资源场景/3D资源/手持宝剑/剑.tscn").instantiate()
	# 先设置为不可见
	node.visible = false
	# 添加到根场景中
	get_parent().add_child(node)
	# 设定该方块的位置
	node.position = $".".position + _camera.basis.z * -1 * 15 + Vector3(0, 5.8, 0)
	# 设为可见
	node.visible = true
	# 等待落地
	await node.hit_plane
	# 记录位置并删除原节点
	var new_position = node.position - Vector3(0, 0.8, 0)
	node.queue_free()
	# 宝剑变成断剑插入地面
	var new_node = preload("res://资源场景/3D资源/断剑/断剑.tscn").instantiate()
	# 添加到根场景中
	get_parent().add_child(new_node)
	# 设定该方块的位置
	new_node.position = new_position
	# 如果落在地上则会触发波及特效
	if new_node.position.y < 1:
		new_node.start_hit()

func drop_attack_reset():							# 宝剑技能重置(召唤计时器的回调函数)
	# CD结束
	is_drop_freezed = false

func print_cd():										# 打印CD和其他信息
	# 预输出
	var show_text = ""
	# 放置是否有吸附
	if need_place_assist:
		show_text += "放置自动定位: 开启\n"
	else:
		show_text += "放置自动定位: 关闭\n"
	# 左键CD
	show_text += "剩余连击次数: " + str(1 - attack_times) + "\n"
	show_text += "挥砍攻击状态: " + attack_text_list[attack_text] + "\n"
	# 右键CD
	if $"召唤计时器".time_left != 0:
		show_text += "右键技能CD: " + str(int($"召唤计时器".time_left + 0.1)) + "\n"
	else:
		show_text += "右键技能可释放\n"
	$"CD".set_text(show_text)

func pre_place():									# 按住右键时显示放置点
	# 原目标位置
	var aim_position =  _camera.global_position + _camera.basis.z * -1 * 2.5
	# 需要网格吸附辅助
	if need_place_assist:
		# 标准化
		aim_position = aim_position.round()
	# 让瞄准处于目标位置
	$"方块瞄准".global_position = aim_position
	if not is_placing or $"方块瞄准".visible == false:
		# 让其可见
		$"方块瞄准".visible = true
		# 正在准备放置
		is_placing = true

func place_it():										# 放置方块
	# 放置后
	is_placing = false
	$"方块瞄准".visible = false
	# 放置位置(默认整数坐标)
	var aim_position = $"方块瞄准".global_position
	if need_place_assist:
		aim_position = Vector3i($"方块瞄准".global_position.round())
	# 确定目标位置没有方块
	if hash_node_stone.has(aim_position):
		return
	# 在瞄准位置生成一个石质方块
	# 创建
	var node = preload("res://资源场景/方块/石质方块_shadow.tscn").instantiate()
	# 添加到根场景中
	get_parent().add_child(node)
	# 设定该方块的位置
	node.global_position = aim_position
	# 将该方块记录在dict中方便调用
	hash_node_stone[aim_position] = node
	print("add: " + str(aim_position))

func find_nearest_node(aim_position):					# 找到离aim_position最近的方块
	# 找到表中最近的方块(要求1m以内)
	# 表空直接显示跳过这步
	if hash_node_stone.size() == 0:
		pass
	else:
		var nearest_node_pos = Vector3(0, -50, 0)
		var nearest_dir2 = 2
		for i in hash_node_stone:
			var dir2 = (aim_position - Vector3(i)).length_squared()
			# 首先要求这个方块离原位置差值不能太大：
			if dir2 >= 1.5:
				pass
			# 然后要求取最小距离的那个
			elif dir2 < nearest_dir2:
				nearest_node_pos = i
				nearest_dir2 = dir2
		# 如果找到目标则设置为这个方块的位置
		if nearest_dir2 != 1:
			aim_position = nearest_node_pos
	# 返回找到的结果
	return aim_position

func pre_replace():									# 准备移除
	# 原目标位置
	var aim_position =  _camera.global_position + _camera.basis.z * -1 * 1.8
	# 找到表中最近的方块(要求1m以内)
	aim_position = find_nearest_node(aim_position)
	# 让瞄准处于目标位置
	$"方块移除瞄准".global_position = aim_position
	if not is_replacing or $"方块移除瞄准".visible == false:
		# 让其可见
		$"方块移除瞄准".visible = true
		# 正在准备放置
		is_replacing = true

func replace_it():									# 移除方块
	# 拆除后
	is_replacing = false
	$"方块移除瞄准".visible = false
	# 拆除位置
	var aim_position = find_nearest_node($"方块移除瞄准".global_position)
	# 找到位置对应方块
	var node = hash_node_stone.get(aim_position)
	if node == null:			# 找不到方块直接返回(正常不应该出现)
		print("删除失败")
		return
	# 删除之(先删节点后删表中记录)
	node.queue_free()
	hash_node_stone.erase(aim_position)
	# 在对应位置播放破坏音效
	$"破坏音效".global_position = aim_position
	$"破坏音效".play()

func be_caught():									# 被抓到
	# 被抓到
	is_alive = false
	# 显示提示
	$"死亡提示".visible = true
	# 速度置零
	$".".linear_velocity = Vector3.ZERO
	# 位置为地面
	$".".global_position.y = 1.4

func alive_and_recover():							# 未被抓到恢复正常
	# 被抓到
	is_alive = true
	# 显示提示
	$"死亡提示".visible = false

func _process(delta: float) -> void:
	
	# 还活着
	if is_alive:
		# 获得方向向量
		var forward = _camera.basis.z * -1
		forward = Plane(plane, 0).project(forward).normalized()
		var right = _camera.basis.x
		
		# 输入判断模块
		get_input(forward, right)
		
		# 2D宝剑的挥砍
		if hand_have == 1:
			# 攻击挥砍管理
			if can_attack and is_attacking and (not is_freezed) and (not not_attack):
				soft_attack_manage()
			# 挥砍动作实体
			if is_attacking and is_freezed:
				soft_attack_body()
			# 挥砍归位
			if is_attack_back:
				soft_attack_back()
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
	elif is_horror:		# 恐怖模式被抓住动画
		if scared_direction:
			$".".position.y += 3 * delta
			if $".".position.y > 1.7:
				scared_direction = not scared_direction
		else:
			$".".position.y -= 3 * delta
			if $".".position.y < 1.5:
				scared_direction = not scared_direction
	
	# 打印CD状态
	print_cd()
