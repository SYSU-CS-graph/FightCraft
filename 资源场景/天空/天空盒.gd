extends Node3D

@export var switch_freq:float = 5 # 每隔这么多秒切换一次天空盒
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
# 当前累计时间
var total_time: float = 0.0
# 天空盒总数
var env_cnt:int = 5
# 记录上一个天空盒和上一个序号
var last_idx = null
var last_node = null

func _process(delta: float) -> void:
	total_time += delta
	# 根据时间确定天空盒
	var total_idx:int = total_time / switch_freq
	var idx = total_idx % env_cnt
	if last_idx != null and idx == last_idx:
		return
	#print(idx)
	# idx改变
	if last_node != null:
		#print('remove')
		remove_child(last_node)
	var env_node
	if idx == 0:
		env_node = preload("res://资源场景/天空/日出/日出.tscn").instantiate()
	elif idx == 1:
		env_node = preload("res://资源场景/天空/多云/上午/上午.tscn").instantiate()
	elif idx == 2:
		env_node = preload("res://资源场景/天空/多云/下午/下午.tscn").instantiate()
	elif idx == 3:
		env_node = preload("res://资源场景/天空/日落/日落.tscn").instantiate()
	elif idx == 4:
		env_node = preload("res://资源场景/天空/黑夜/黑夜.tscn").instantiate()
	add_child(env_node)
	last_node = env_node
	last_idx = idx
		
	
	
