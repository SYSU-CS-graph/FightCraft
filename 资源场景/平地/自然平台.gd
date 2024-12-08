extends Node3D

var base_position = Vector3(0, 0, 0)					# 基地址
var hash_node = { }									# 用于使用方块的hash

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 生成平台
	layer_init()
	# 随机生成点东西
	random_init()

func layer_init():									# 初始化平台
	# 地基
	for i in range(101):
		for j in range(101):
			# 创建地基方块
			var each_node = preload("res://资源场景/方块/方块_base.tscn").instantiate()
			# 添加到当前场景中
			add_child(each_node)
			# 设定该方块的位置
			each_node.position = base_position + Vector3(i - 50, 0, j - 50)
			# 添加到hash中便于使用
			hash_node[Vector3(i - 50, 0, j - 50)] = each_node
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
			var k = randi_range(1, 20)
			# 设定该方块的位置
			each_node.position = Vector3(i, k, j)
			# 添加到hash中便于使用
			hash_node[Vector3(i, k, j)] = each_node

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
