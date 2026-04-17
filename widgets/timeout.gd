# TIMEOUT TIMER
# - make a global
extends Timer

var timeout_time := 3*60 # seconds
var timeout_action := 'quit'

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
	match timeout_action:
		'quit':
			debug.print("Input Timeout! Quitting")
			root.quit()
		'menu':
			debug.print("Input Timeout! Main Menu")
			# this can be tricky and possibly cause crash
			if not root.switching_scene:
				if not root.current_scene_name == game.main_menu:
					audio.pause_sounds()
					menus.show(game.main_menu)
	
