extends Node

var is_ball = false						# 是否以生成完整球体

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func get_input():							# 处理输入
	# 生成完整球体
	if not is_ball and Input.is_key_pressed(KEY_O):
		is_ball = true
		$"自然平台".make_global_ball()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	# 直接显示一些参数
	var temp_text  = ""
	temp_text += "x:" + str($"Character".position.x) + "\n"
	temp_text += "y:" + str($"Character".position.y) + "\n"
	temp_text += "z:" + str($"Character".position.z) + "\n"
	$"Debug参数".set_text(temp_text)
	
	# 处理输入
	get_input()
