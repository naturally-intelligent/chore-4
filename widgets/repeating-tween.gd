extends Tween
class_name RepeatingTween

func _ready():
	connect("finished",Callable(self,"on_tween_completed"))

func on_tween_completed():
	start()
