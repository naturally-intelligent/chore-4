class_name GameViewport extends SubViewportContainer

func _ready():
	set_process_unhandled_input(true)

func _input(event: InputEvent):
	if event is InputEventMouse:
		root.update_mouse_position()

func viewport():
	return $SubViewport
