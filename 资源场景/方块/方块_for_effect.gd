extends RigidBody3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 产生后自发消亡
	await get_tree().create_timer(6).timeout
	queue_free()
