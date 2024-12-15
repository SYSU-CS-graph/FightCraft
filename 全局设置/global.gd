extends Node3D

var core = Vector3(0, -50, 0)						# 球心

func get_dir_to_core(pos):							# 获取对象到core的方向向量
	var dir = core - pos
	dir = dir.normalized()
	return dir
