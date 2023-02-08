extends Node

# CHORE ENGINE - Launch Scene

func _init():
	# STARTUP TEXT
	debug.print('---')
	debug.print(game.title.to_upper())
	debug.print('---')
	# COMMAND LINE ARGUMENTS
	root.command_line_start()

func _ready():
	# hide editor splash (first menu you see when opening Godot project)
	if has_node("EditorSplash"):
		$EditorSplash.visible = false
	# show first menu
	if game.release:
		menus.show(game.launch_menu)
	else:
		# development launch overrides
		if dev.launch_menu_override:
			menus.show(dev.launch_menu_override)
		elif dev.launch_scene_override:
			scenes.show(dev.launch_scene_override)
		else:
			menus.show(game.launch_menu)
	# then delete this blank scene (don't need it anymore)
	self.queue_free()
