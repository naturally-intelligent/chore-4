extends "res://menus/menu.gd"

var no_back_button = true

func _ready():
	$BackButton.connect("pressed",Callable(self,"on_back_pressed"))
	var file = FileAccess.open('res://CHORE-ENGINE-SETUP.txt', FileAccess.READ)
	var notes = file.get_as_text()
	file = null
	$File.set_text(notes)
	set_default_menu_button($BackButton)

func on_back_pressed():
	menus.show('main')
