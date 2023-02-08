extends "res://menus/menu.gd"

var no_back_button = true
var no_hud = true

func _ready():
	$Buttons/Play.connect("pressed",Callable(self,"on_play_pressed"))
	$Buttons/Restart.connect("pressed",Callable(self,"on_restart_pressed"))
	$Buttons/Credits.connect("pressed",Callable(self,"on_about_pressed"))
	$Buttons/Notes.connect("pressed",Callable(self,"on_notes_pressed"))
	$Buttons/Settings.connect("pressed",Callable(self,"on_settings_pressed"))
	$Buttons/Quit.connect("pressed",Callable(self,"on_quit_pressed"))
	for button in $Buttons.get_children():
		audio.button_sounds(button, 'menu-hover', 'menu-press')
	game.massage_label($Copyright)
	game.massage_label($Version)
	default_menu_button = $Buttons/Play

	audio.play_music('main-menu')

	# VERSION
	$Version.set_text('v' + game.version)

func on_play_pressed():
	if not scenes.reveal():
		scenes.show('play', 'fade')

func on_restart_pressed():
	scenes.fresh('play', 'fade', 'clear')

func on_notes_pressed():
	menus.show('notes')

func on_settings_pressed():
	menus.show('settings')

func on_about_pressed():
	menus.show('credits')

func on_quit_pressed():
	audio.delayed_sound('quit', 0.2)
	root.fade_out_and_quit()

