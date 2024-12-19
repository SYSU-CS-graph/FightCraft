extends RigidBody3D

var is_on_plane = false						# 只有落在地上时产生波及效果
var hit_flag = true							# 产生一次的球型碰撞，击飞周围的物体

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 信号连接
	$"计时器".timeout.connect(time_over)
	$"波及/计时器".timeout.connect(time_over_2)
	# 开始计时
	$"计时器".start(3.5)

func time_over():							# 时间到了自动消亡
	queue_free()

func start_hit():							# 开始波及
	# 土粒子溅射
	$"土粒子".emitting = true
	# 标志为真
	is_on_plane = true
	hit_flag = true
	# 产生一些由于特效的方块
	for i in range(15):
		var new_node = preload("res://资源场景/方块/方块_for_effect.tscn").instantiate()
		# 添加到根场景中
		get_parent().add_child(new_node)
		# 设定该方块的位置
		new_node.position = position + Vector3(randf_range(-2.5, 2.5), 1, randf_range(-2.5, 2.5))
	# 波及球上移
	$"波及/波及体积1".disabled = false
	$"波及".linear_velocity.y = 20
	# 开始计时
	$"波及/计时器".start(0.3)
	# 发出声响
	$"爆炸声".play()

func time_over_2():							# 时间到了自动停止波及
	hit_flag = false
	$"波及/波及体积1".disabled = true
