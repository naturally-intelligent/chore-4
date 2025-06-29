# TIMEOUT TIMER
# - make a global
extends Timer

var timeout_time := 3*60 # seconds

func _ready():
	debug.print("Start input timer: ", timeout_time)
	start(timeout_time)

func _input(event: InputEvent) -> void:
	#debug.print("Input Timer _input")
	start(timeout_time)

func _unhandled_input(event: InputEvent) -> void:
	#debug.print("Input Timer _unhandled_input")
	start(timeout_time)

func _on_timeout() -> void:
	debug.print("Input Timeout! Quitting")
	root.quit()
