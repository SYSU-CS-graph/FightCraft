extends Node

var is_ball = false						# 是否以生成完整球体
var is_full_screen = false				# 是否全屏

var is_challenge = false					# 是否处于挑战模式
var is_horror = false					# 是否处于恐怖模式
var hash_monster = { }					# 怪物节点表
var monster_num = 0						# 总生成怪物数

var is_scared = false					# 还未被吓到

func _ready() -> void:
	# 播放背景音乐
	$"BGM播放器1".play()
	# 信号连接
	$"怪物生成计时".timeout.connect(make_a_monster)
	$"恐怖模式计时器".timeout.connect(time_end_and_win)

func get_input():							# 处理输入
	# 生成完整球体
	if not is_ball and Input.is_key_pressed(KEY_O):
		is_ball = true
		$"自然平台".make_global_ball()
	# 按P键切换全屏
	if Input.is_action_just_pressed("Action_P"):
		if is_full_screen:
			is_full_screen = false
			get_window().mode = get_window().Mode.MODE_WINDOWED
		else:
			is_full_screen = true
			get_window().mode = get_window().Mode.MODE_EXCLUSIVE_FULLSCREEN
	# 按Esc退出游戏
	if Input.is_action_just_pressed("Action_Esc"):
		get_tree().quit()
	# 按C键开启挑战模式
	if not is_challenge and Input.is_action_just_pressed("Action_C"):
		is_challenge = true
		# 开始生成怪物
		$"怪物生成计时".start(2)
		# 开始换音乐
		$"BGM播放器1".stop()
		$"BGM播放器2".play()
		# 更换为挑战模式
		$"模式".set_text("挑战模式")
	# 挑战模式基础上按V键开启恐怖模式
	if not is_horror and is_challenge and Input.is_action_just_pressed("Action_V"):
		is_horror = true
		# 开始换音乐
		$"BGM播放器2".stop()
		$"BGM播放器3".play()
		# 视野变小
		$"Character/Camera3D".set_far(8)
		$"Character/Camera3D".set_fov(60)
		$"Character/Camera3D"._max_angle = 1.2
		$"Character/Camera3D"._min_angle = -1.2
		# 走路和跑动变慢
		$"Character".walking_rate = 0.6
		$"Character".running_rate = 1.5
		# 玩家设为恐怖模式行走，会带有脚步声
		$"Character".is_horror = true
		# 传送至原点
		$"Character".position = Vector3(0, 2, 0)
		# 头顶屏障开启
		$"自然平台/头顶屏障/边界top".disabled = false
		$"自然平台/头顶屏障/边界1".disabled = false
		$"自然平台/头顶屏障/边界2".disabled = false
		$"自然平台/头顶屏障/边界3".disabled = false
		$"自然平台/头顶屏障/边界4".disabled = false
		# 恐怖模式计时器开始计时
		$"恐怖模式计时器".start(180)
		# 更改为恐怖模式
		$"模式".set_text("恐怖模式")
		# 天空盒变黑
		$"旧天空/WorldEnvironment".environment.sky.sky_material.energy_multiplier = 0
		$"旧天空".visible = false
		

func make_a_monster():									# 产生一个小怪物
	# 记录生成数，当数目达到一定量时生成更强的怪
	monster_num += 1
	# 随机决定生成怪的种类，时间越长怪物越容易出现高级怪
	var monster_kind = randi_range(0, monster_num)
	# 产生节点
	var node
	var kind = 0
	# 根据随机数生成怪
	if monster_kind < 15:
		node = preload("res://资源场景/3D资源/怪兽/怪兽.tscn").instantiate()
		kind = 0
	elif monster_kind < 30:
		node = preload("res://资源场景/3D资源/怪兽/怪兽_rush.tscn").instantiate()
		kind = 1
	elif monster_kind < 45:
		node = preload("res://资源场景/3D资源/怪兽/怪兽_big.tscn").instantiate()
		kind = 2
	else:
		node = preload("res://资源场景/3D资源/怪兽/怪兽_no_barrier.tscn").instantiate()
		kind = 3
	# 添加到根场景中
	get_parent().add_child(node)
	# 设定该方块的位置(随机距离50m)
	var dir = (Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))).normalized()
	node.position = $"Character".position + dir * randf_range(35, 65) + Vector3(0, -1.3, 0)
	# 设置速度指向玩家
	dir = ($"Character".position - node.position).normalized()
	node.linear_velocity = dir * 7
	# 速度怪加速，巨型怪减速且上移
	if kind == 1:
		node.linear_velocity = dir * 12
	elif kind == 2:
		node.linear_velocity = dir * 4
		node.position.y += 0.4
	# 朝向玩家
	node.rotate_y(dir.signed_angle_to(node.basis.x, -node.basis.y))
	# 保存至dict中
	hash_monster[hash_monster.size()] = node
	node.catch.connect(catch_it)
	# 恐怖模式则额外设置一下
	if is_horror:
		# 开启怪兽恐怖模式的叫声
		node.start_horror()
		# 设定怪兽在水平面上生成
		node.position.y = -0.3

func catch_it():										# 怪物抓到玩家
	# 处于挑战(恐怖)模式
	if is_challenge:
		# 第一次才触发
		if not is_scared:
			# 被吓到
			is_scared = true
			# 玩家倒下(回到地面)
			$"Character".be_caught()
			# 恐怖模式突脸
			if is_horror:
				# 怪兽位置
				$"怪兽".position = $"Character".position - Vector3(0, 1, 0)
				$"怪兽".visible = true
				# 人发出尖叫
				$"怪兽/人声尖叫".play()
				await get_tree().create_timer(2).timeout
				$"怪兽/人声尖叫".queue_free()

func time_end_and_win():								# 恐怖模式计时结束
	# 回归休闲模式
	is_challenge = false
	is_horror = false
	is_scared = false
	monster_num = 0
	$"Character".is_horror = false
	$"模式".set_text("休闲模式")
	$"恐怖倒计时".set_text("")
	$"怪物生成计时".stop()
	$"Character".alive_and_recover()
	# 走路和跑动变快
	$"Character".walking_rate = 1
	$"Character".running_rate = 3
	# 玩家设为恐怖模式行走，会带有脚步声
	$"Character".is_horror = false
	# 视野变大
	$"Character/Camera3D".set_far(500)
	$"Character/Camera3D".set_fov(75)
	$"Character/Camera3D"._max_angle = 1.57
	$"Character/Camera3D"._min_angle = -1.57
	# 清空怪物
	hash_monster.clear()
	# 天空盒变亮
	$"旧天空/WorldEnvironment".environment.sky.sky_material.energy_multiplier = 1
	$"旧天空".visible = true
	# 音乐换回去
	$"BGM播放器3".stop()
	$"BGM播放器1".play()
	# 头顶屏障关闭
	$"自然平台/头顶屏障/边界top".disabled = true
	$"自然平台/头顶屏障/边界1".disabled = true
	$"自然平台/头顶屏障/边界2".disabled = true
	$"自然平台/头顶屏障/边界3".disabled = true
	$"自然平台/头顶屏障/边界4".disabled = true

func _process(_delta: float) -> void:
	
	# 直接显示一些参数
	var temp_text  = ""
	temp_text += "x:" + str(int($"Character".position.x)) + "\n"
	temp_text += "y:" + str(int($"Character".position.y)) + "\n"
	temp_text += "z:" + str(int($"Character".position.z)) + "\n"
	$"Debug参数".set_text(temp_text)
	
	# 恐怖模式显示计时
	if is_horror:
		$"恐怖倒计时".set_text("别被怪兽抓到！\n倒计时:" + str(int($"恐怖模式计时器".get_time_left())))
	
	# 处理输入
	get_input()
