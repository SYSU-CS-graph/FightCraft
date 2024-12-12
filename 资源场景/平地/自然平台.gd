extends Node3D

var base_position = Vector3(0, 0, 0)					# 基地址
var hash_node = { }									# 用于使用方块的hash
var hash_node_tree = { }								# 用于使用树的hash
var hash_node_cow = { }								# 用于使用牛的hash
var hash_node_long = { }								# 用于使用龙的hash
var hash_node_grass = { }							# 用于使用草的hash
var hash_node_pool = { }								# 用于池塘边缘方块的hash

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 生成平台
	layer_init()
	# 生成水
	water_init()
	# 随机生成点东西
	random_init()
	# 生成树
	make_tree()
	# 生成牛
	make_cow()
	# 生成草(消耗GPU资源，平时开发可不生成草)
	#make_grass()

func layer_init():									# 初始化平台
	# 地基
	for i in range(101):
		for j in range(101):
			if 40<=i and i<=46 and 40<=j and j<=46:
				continue
			# 创建地基方块
			var each_node = preload("res://资源场景/方块/方块_base.tscn").instantiate()
			# 添加到当前场景中
			add_child(each_node)
			# 设定该方块的位置
			each_node.position = base_position + Vector3(i - 50, 0, j - 50)
			# 添加到hash中便于使用
			hash_node[Vector3(i - 50, 0, j - 50)] = each_node

func water_init():									# 生成池塘
	# 生成水
	var water_node = preload("res://资源场景/水/水.tscn").instantiate()
	add_child(water_node)
	water_node.position = base_position + Vector3(-7, -0.8 ,-7)
	# 生成池塘边缘
	var depth = 2 # 池塘深度
	for i in range(40, 47):
		for j in range(40, 47):
			# 竖直边缘
			if i == 40 or i == 46 or j == 40 or j == 46:
				for k in range(depth): # y坐标
					var each_node = preload("res://资源场景/方块/方块.tscn").instantiate()
					add_child(each_node)
					each_node.position = base_position + Vector3(i - 50, -k, j - 50)
					hash_node_pool[Vector3(i - 50, -k, j - 50)] = each_node
			# 池底
			var each_node = preload("res://资源场景/方块/方块.tscn").instantiate()
			add_child(each_node)
			each_node.position = base_position + Vector3(i - 50, -depth, j - 50)
			hash_node_pool[Vector3(i - 50, -depth, j - 50)] = each_node
func is_in_pool(pos:Vector3): # 判断坐标是否在池塘内，避免池塘内随机生成物体（除了小动物）
	var x = pos.x
	var z = pos.z
	return x>=40-50 and x<=46-50 and z>=40-50 and z<=46-50
	
	

func make_grass():									# 生成草
	# 产生随机坐标
	var pos_list = []
	for i in range(50):
		var temp_pos = Vector3(randi_range(-50, 50), 0.5, randi_range(-50, 50))
		var flag = true
		for j in pos_list:
			var dir = j - temp_pos
			if dir.length() < 3:
				flag = false
				break
			if is_in_pool(temp_pos): # 避免在池塘内生成
				flag = false
				break
		if flag:
			pos_list.append(temp_pos)
	# 生成草
	for i in pos_list:
		# 在周围3×3的范围内随机生成草，这样做的目的是让草的生成倾向于集中
		for j in range(-1, 2):
			for k in range(-1, 2):
				if randi_range(0,100) < 30: # 生成概率30%
					var pos = i
					pos.x+=j
					pos.z+=k
					var each_node = preload("res://资源场景/3D资源/草/grass.tscn").instantiate()
					add_child(each_node)
					each_node.position = pos
					hash_node_grass[pos] = each_node
	
func make_tree():									# 随机产生一些树
	# 产生随机坐标
	var pos_list = []
	for i in range(50):
		var temp_pos = Vector3(randi_range(-50, 50), 0, randi_range(-50, 50))
		# 要求每颗树至少保持7格距离
		var flag = true
		for j in pos_list:
			var dir = j - temp_pos
			if dir.length() < 7:
				flag = false
				break
		if is_in_pool(temp_pos): # 避免在池塘内生成
			flag = false
		if flag:
			pos_list.append(temp_pos)
	# 生成树
	for i in pos_list:
		# 创建树
		var each_node = preload("res://资源场景/3D资源/树/树.tscn").instantiate()
		# 添加到当前场景中
		add_child(each_node)
		# 设置位置
		each_node.position = i
		# 随机角度
		each_node.rotation = Vector3(0, randf_range(-PI, PI), 0)
		# 添加到dict中
		hash_node_tree[i] = each_node

func make_cow():									# 随机产生一些树
	# 产生随机坐标
	var pos_list = []
	for i in range(10):
		var temp_pos = Vector3(randi_range(-50, 50), 5, randi_range(-50, 50))
		# 要求每头牛至少保持5格距离
		var flag = true
		for j in pos_list:
			var dir = j - temp_pos
			if dir.length() < 5:
				flag = false
				break
		if flag:
			pos_list.append(temp_pos)
	# 生成牛
	for i in pos_list:
		# 创建树
		var each_node = preload("res://资源场景/3D资源/牛/牛.tscn").instantiate()
		# 添加到当前场景中
		add_child(each_node)
		# 设置位置
		each_node.position = i
		# 随机角度
		each_node.rotation = Vector3(0, randf_range(-PI, PI), 0)
		# 添加到dict中
		hash_node_cow[i] = each_node

func make_global_ball():								# 产生完整球体，为了加载速度正常不生成，靠手动生成
	# 球体的其他面
	var side_base_position = [Vector3(-50, 0, -50), Vector3(-50, 0, 50), Vector3(50, 0, -50), Vector3(-50, 0, -50), Vector3(0, -100, 0)]
	var rotation_list = [Vector3(- PI / 2, 0, 0), Vector3(PI / 2, 0, 0), Vector3(0, 0, - PI / 2), Vector3(0, 0, PI / 2), Vector3(0, PI, 0)]
	for h in range(5):
		var new_base_pos = side_base_position[h] + base_position
		for i in range(101):
			for j in range(101):
				# 创建地基方块
				var each_node = preload("res://资源场景/方块/方块_base.tscn").instantiate()
				# 添加到当前场景中
				add_child(each_node)
				# 设定方向
				each_node.rotation = rotation_list[h]
				# 设定该方块的位置
				if h == 0:
					each_node.position = new_base_pos + Vector3(i, j - 100, 0)
				elif h == 1:
					each_node.position = new_base_pos + Vector3(i, j - 100, 0)
				elif h == 2:
					each_node.position = new_base_pos + Vector3(0, j - 100, i)
				elif h == 3:
					each_node.position = new_base_pos + Vector3(0, j - 100, i)
				elif h == 4:
					each_node.position = new_base_pos + Vector3(i - 50, 0, j - 50)
				# 添加到hash中便于使用
				hash_node[each_node.position] = each_node

func random_init():									# 随机化平台
	for m in range(25):
		for n in range(25):
			# 创建地基方块
			var each_node = preload("res://资源场景/方块/方块.tscn").instantiate()
			# 添加到当前场景中
			add_child(each_node)
			# 设定一个随机数
			var i = randi_range(-50, 50)
			var j = randi_range(-50, 50)
			var k = randi_range(10, 30)
			# 设定该方块的位置
			each_node.position = Vector3(i, k, j)
			# 随机角度
			each_node.rotation = Vector3(randf_range(-PI / 2, PI / 2), randf_range(-PI, PI), randf_range(-PI / 2, PI / 2))
			# 添加到hash中便于使用
			hash_node[Vector3(i, k, j)] = each_node

func summon_dragon():								# 召唤龙
	if Input.is_key_pressed(KEY_N) and Input.is_key_pressed(KEY_L):
		# 创建龙
		var each_node = preload("res://资源场景/3D资源/龙/1/龙1.tscn").instantiate()
		# 添加到当前场景中
		add_child(each_node)
		# 设定该方块的位置
		each_node.position = Vector3(0, 10, 0)
		# 随机角度
		each_node.rotation = Vector3(randf_range(-PI / 2, PI / 2), randf_range(-PI, PI), randf_range(-PI / 2, PI / 2))
		# 添加到hash中便于使用
		hash_node_long[len(hash_node_long)] = each_node
	if Input.is_key_pressed(KEY_N) and Input.is_key_pressed(KEY_M):
		# 创建龙
		var each_node = preload("res://资源场景/3D资源/龙/2/龙2.tscn").instantiate()
		# 添加到当前场景中
		add_child(each_node)
		# 设定该方块的位置
		each_node.position = Vector3(0, 10, 0)
		# 随机角度
		each_node.rotation = Vector3(randf_range(-PI / 2, PI / 2), randf_range(-PI, PI), randf_range(-PI / 2, PI / 2))
		# 添加到hash中便于使用
		hash_node_long[len(hash_node_long)] = each_node

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# 可能召唤的输入判定
	summon_dragon()
