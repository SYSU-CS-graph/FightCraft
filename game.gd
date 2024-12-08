extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var temp_text  = ""
	temp_text += "x:" + str($"Character".position.x) + "\n"
	temp_text += "y:" + str($"Character".position.y) + "\n"
	temp_text += "z:" + str($"Character".position.z) + "\n"
	$"Debug参数".set_text(temp_text)
