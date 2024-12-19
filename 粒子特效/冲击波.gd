extends RigidBody3D

var is_running = false							# 是否在运动

func _ready():
	# 信号连接
	$"计时器".timeout.connect(time_end)

func init(direction, rot, times):					# 初始化
	# 设定速度(希望比第一下稍快)
	$".".linear_velocity = direction * (50 + times * 10)
	# 设定角度
	$".".rotation = rot + Vector3(0, - PI / 2, 0)
	if times == 0:
		$".".rotation.x -= PI / 4
	else:
		$".".rotation.x += PI / 4
	# 设置is_running为真
	is_running = true
	# 开始计时
	$"计时器".start(5)

func time_end():									# 生命周期结束时消失
	queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if is_running:
		# 当速度足够小时消失
		if $".".linear_velocity.length() < 40:
			queue_free()
