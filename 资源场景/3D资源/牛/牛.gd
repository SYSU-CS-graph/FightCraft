extends RigidBody3D

func _ready():
	pass

func moo():									# 发出叫声
	# 发出声音
	$"牛叫".play()
	# 一段时间内不发出来
	set_contact_monitor(false)
	await get_tree().create_timer(5).timeout
	set_contact_monitor(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# 随机旋转
	if randi_range(1, 10000) < 10:
		$".".rotation.y += randf_range(0, 3)
		$".".linear_velocity = Vector3.ZERO
	# 随机前进
	if randi_range(1, 10000) < 10:
		$".".linear_velocity = $".".linear_velocity.move_toward($".".basis.x, delta) * randi_range(2, 5)
	# 随机发出声音
	if randi_range(1, 50000) < 3:
		moo()
