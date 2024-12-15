extends RigidBody3D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# 随机旋转
	if randi_range(1, 10000) < 10:
		$".".rotation.y += randf_range(0, 3)
		$".".linear_velocity = Vector3.ZERO
	# 随机前进
	if randi_range(1, 10000) < 10:
		$".".linear_velocity = $".".linear_velocity.move_toward($".".basis.x, delta) * randi_range(5, 20)
