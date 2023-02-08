extends Control
class_name Menu

var default_menu_button = null

func set_default_menu_button(button):
	default_menu_button = button
	audio.button_sounds(default_menu_button, 'menu-hover', 'menu-press')

func on_focus():
	if default_menu_button:
		default_menu_button.grab_focus()

