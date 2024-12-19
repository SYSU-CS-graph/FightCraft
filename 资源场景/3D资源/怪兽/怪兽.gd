extends RigidBody3D

signal catch						# 抓住玩家的信号

var is_horror = false			# 是否处于恐怖模式

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 信号连接
	$"抓取箱".body_entered.connect(catch_it)
	$"吼叫计时".timeout.connect(jiao)
	# 产生60秒后自动消亡
	await get_tree().create_timer(45).timeout
	queue_free()

func start_horror():									# 开始恐怖模式
	is_horror = true
	$"吼叫计时".start(5)

func jiao():											# 吼叫
	$"吼叫声".play()

func catch_it(_body):								# 抓到玩家回调
	# 发送信号
	catch.emit()
	# 自我删除(恐怖模式突脸)
	await get_tree().create_timer(0.1).timeout
	queue_free()
