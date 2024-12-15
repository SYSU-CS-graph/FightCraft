extends Node3D

var base_position = Vector3(0, 0, 0)					# 基地址
var hash_node = { }									# 用于使用方块的hash
var hash_node_tree = { }								# 用于使用树的hash
var hash_node_cow = { }								# 用于使用牛的hash
var hash_node_long = { }								# 用于使用龙的hash
var hash_node_grass = { }							# 用于使用草的hash
var hash_node_pool = { }								# 用于池塘边缘方块的hash

# 随即地形加载




# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 打乱地形生成
	var my_arry = [1,2,3,0]
	my_arry.shuffle()
	var a1 = my_arry[0]
	var a2 = my_arry[1]
	var a3 = my_arry[2]
	var a4 = my_arry[3]
	print(a1,a2,a3,a4)
	var new_array = [[-35,-35,35,30],[0,-35,30,20],[-35,0,30,25],[29,29,44,25]]
	make_stone(new_array[a1][0],new_array[a1][1],new_array[a1][2],new_array[a1][3])	#位置x,位置z，生成大小size，生成最大高度max_height
	make_stone(new_array[a2][0],new_array[a2][1],new_array[a2][2],new_array[a2][3])	
	make_stone(new_array[a3][0],new_array[a3][1],new_array[a3][2],new_array[a3][3])	
	# 生成树
	var tree_height =randi()%8+1
	make_tree_2(new_array[a4][0],new_array[a4][1],new_array[a4][2],tree_height)		#位置x,位置z，生成大小size，生成最大高度max_height
	
	
	# 生成平台
	layer_init()
	#generate_sine_wave_terrain(4,7,10,5)		#位置x,位置z，生成大小size，生成最大高度max_height
	#generate_sine_wave_terrain(18,26,10,5)
	#generate_sine_wave_terrain(35,31,15,8)
	#generate_sine_wave_terrain(16,21,15,8)
	#generate_sine_wave_terrain(39,-19,15,5)
	
	#随机地形加载

	#make_stone(-35,-35,35,30)	#位置x,位置z，生成大小size，生成最大高度max_height
	#make_stone(0,-35,30,20)	#位置x,位置z，生成大小size，生成最大高度max_height
	#make_stone(-35,0,30,25)	#位置x,位置z，生成大小size，生成最大高度max_height
	## 生成树
	#make_tree_2(29,29,44,5)		#位置x,位置z，生成大小size，生成最大高度max_height
	# 生成水
	water_init()
	
	
	
	
	
	#river_init()
	# 随机生成点东西
	#random_init()
	make_sand(33,-20,36,54,7)	#位置x,位置z，生成大小x_size,z_size，生成最大高度max_height
	make_sand(-35,31,30,35,7)
	# 生成牛
	make_cow()
	# 生成草(消耗GPU资源，平时开发可不生成草)
	#make_grass()
var pool_star =30;
var pool_end =50;
var poor_x_star = 30;
var poor_x_end = 55;
var poor_z_star = 30;
var poor_z_end = 94;

func layer_init():									# 初始化平台
	var max_height = 3  # 最大高度
	# 地基
	for i in range(101):
		for j in range(101):
			if poor_x_star<=i and i<=poor_x_end and poor_z_star<=j and j<=poor_z_end:
				continue
			
			#var height = randi() % max_height + 1
			#for y in range(height):  # 堆叠高度层的方块
				#var each_node = preload("res://资源场景/方块/方块.tscn").instantiate()
				#add_child(each_node)
				#each_node.position = base_position + Vector3(i - 50, y, j - 50)
				#hash_node[Vector3(i - 50, y, j - 50)] = each_node
				
			# 创建地基方块
			var each_node = preload("res://资源场景/bhh-方块/bhh_草平台.tscn").instantiate()
			# 添加到当前场景中
			add_child(each_node)
			# 设定该方块的位置
			each_node.position = base_position + Vector3(i - 50, 0, j - 50)
			 #添加到hash中便于使用
			hash_node[Vector3(i - 50, 0, j - 50)] = each_node

func make_sand(x_pos : int, z_pos: int , x_range:int,z_range:int , max_height:int):
	#var max_height # 最大高度
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.05
	for x_temp in range(x_range):
		for z_temp in range(z_range):
			var x =x_temp + x_pos
			var z =z_temp+ z_pos
			var noise_value = noise.get_noise_2d(x * 0.1, z * 0.1)
			#var height = int(  ( sin(x * 0.5) * cos(z * 0.85)* 0.3    +   sin((x + z) * 0.6)* 0.3    +   cos((x-z)*0.4) *0.2  +  sin(x-z)*0.1 + noise_value * 0.8 ) *  max_height  ) 
			var height = int(noise_value * max_height)
			# 使用正弦函数生成高度
			height = height + randi()%4 +1;
			#height = int(sin(x * 0.5) * cos(z * 0.5) * max_height) + randi()%3 -1   # noise.get_noise_2d(x * 0.1, z * 0.1) * 5
			if height <= 1:
				height = 1  # 最小高度保证地形存在
			# 堆叠方块
			for y in range(height):
				var block = preload("res://资源场景/bhh-方块/沙子方块.tscn").instantiate()
				add_child(block)
				block.position = Vector3(x - x_range / 2, y, z - z_range / 2)
				
				if(y == height):
					#最高点是否生成树
					continue


func make_stone(x_pos : int, z_pos: int , range:int , max_height:int):
	var terrain_size = range  # 地形范围
	#var max_height # 最大高度
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.05
	
	for x_temp in range(terrain_size):
		for z_temp in range(terrain_size):
			var x =x_temp + x_pos
			var z =z_temp+ z_pos
			var noise_value = noise.get_noise_2d(x * 0.1, z * 0.1)
			var height = int(  ( sin(x * 0.5) * cos(z * 0.85)* 0.3    +   sin((x + z) * 0.6)* 0.3    +   cos((x-z)*0.4) *0.2  +  sin(x-z)*0.1 + noise_value * 0.2 ) *  max_height  ) 
			# 使用正弦函数生成高度
			height = height + randi()%6 -1;
			#height = int(sin(x * 0.5) * cos(z * 0.5) * max_height) + randi()%3 -1   # noise.get_noise_2d(x * 0.1, z * 0.1) * 5
			if height <= 1:
				continue
				#height = 1  # 最小高度保证地形存在
			# 堆叠方块
			for y in range(height):
				var block = preload("res://资源场景/bhh-方块/石头方块.tscn").instantiate()
				add_child(block)
				block.position = Vector3(x - terrain_size / 2, y, z - terrain_size / 2)
				
				if(y == height):
					#最高点是否生成树
					continue
				




func water_init():									# 生成池塘
	# 生成水
	var water_node = preload("res://资源场景/bighaohao水/Scenes/WaterPlane.tscn").instantiate()
	add_child(water_node)
	water_node.position = base_position + Vector3(-10, -0.8 ,-10)	#-7,-0.8,-7
	# 生成池塘边缘
	var depth = 2 # 池塘深度
	for i in range(poor_x_star, poor_x_end+1):
		for j in range(poor_z_star, poor_z_end+1):
			# 竖直边缘
			if i == poor_x_star or i == poor_x_end or j == poor_z_star or j == poor_z_end:
				for k in range(depth): # y坐标
					var each_node = preload("res://资源场景/bhh-方块/沙子方块.tscn").instantiate()
					add_child(each_node)
					each_node.position = base_position + Vector3(i - 50, -k, j - 50)
					hash_node_pool[Vector3(i - 50, -k, j - 50)] = each_node
			# 池底
			var each_node = preload("res://资源场景/bhh-方块/沙子方块.tscn").instantiate()
			add_child(each_node)
			each_node.position = base_position + Vector3(i - 50, -depth, j - 50)
			hash_node_pool[Vector3(i - 50, -depth, j - 50)] = each_node
			
			
			

func is_in_pool(pos:Vector3): # 判断坐标是否在池塘内，避免池塘内随机生成物体（除了小动物）
	var x = pos.x
	var z = pos.z
	return x>=poor_x_star-50 and x<=poor_x_end-50 and z>=poor_z_star-50 and z<=poor_z_end-50
	
	

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
	#for i in pos_list:
		## 在周围3×3的范围内随机生成草，这样做的目的是让草的生成倾向于集中
		#for j in range(-1, 2):
			#for k in range(-1, 2):
				#if randi_range(0,100) < 30: # 生成概率30%
					#var pos = i
					#pos.x+=j
					#pos.z+=k
					#var each_node = preload("res://资源场景/3D资源/草/grass.tscn").instantiate()
					#add_child(each_node)
					#each_node.position = pos
					#hash_node_grass[pos] = each_node
	#
	
		#
func make_tree_2(x_pos : int, z_pos: int , range:int , max_height:int):									# 随机产生一些树
	var terrain_size = range  # 地形范围
	#var max_height # 最大高度
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.05
	var pos_list = []	#树坐标
	for x_temp in range(terrain_size):
		for z_temp in range(terrain_size):
			var x =x_temp+ x_pos
			var z =z_temp+ z_pos
			var noise_value = noise.get_noise_2d(x * 0.1, z * 0.1)
			var height = int(  ( sin(x * 0.5) * cos(z * 0.85)* 0.3    +   sin((x + z) * 0.6)* 0.3    +   cos((x-z)*0.4) *0.2  +  sin(x-z)*0.1 + noise_value * 0.2 ) *  max_height  ) 
			# 使用正弦函数生成高度
			height = height + randi()%3;
			#height = int(sin(x * 0.5) * cos(z * 0.5) * max_height) + randi()%3 -1   # noise.get_noise_2d(x * 0.1, z * 0.1) * 5
			if height <= 1:
				continue
				#height = 1  # 最小高度保证地形存在
			# 堆叠方块
			for y in range(height):
				var block = preload("res://资源场景/bhh-方块/泥土方块.tscn").instantiate()
				add_child(block)
				block.position = Vector3(x - terrain_size / 2, y, z - terrain_size / 2)
				
				if(y == height-1):
					#最高点是否生成树
					var flag = true
					var temp_pos=Vector3(x - terrain_size / 2,y,z - terrain_size / 2)
					for j in pos_list:
						var dir = j - temp_pos
						if dir.length() < 6:
							flag = false
							break
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
	
	
	
	
		
		
		
		
func make_tree():									# 随机产生一些树
	# 产生随机坐标
	var pos_list = []
	for i in range(50):
		var temp_pos = Vector3(randi_range(5, 50), 0, randi_range(-19, 50))
		# 要求每颗树至少保持7格距离
		var flag = true
		for j in pos_list:
			var dir = j - temp_pos
			if dir.length() < 5:
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
