extends "res://menus/menu.gd"

var no_back_button = true

func _ready():
	$BackButton.connect("pressed",Callable(self,"on_back_pressed"))
	game.massage_label($Notes)
	set_default_menu_button($BackButton)

func on_back_pressed():
	menus.show('main')
