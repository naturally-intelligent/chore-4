extends "res://menus/menu.gd"

# Chore Engine

var text_entry = true
var no_back_button = true

func _ready():
	customize_to_platform()
	var fullscreen = get_widget('fullscreen')
	fullscreen.set_pressed(((get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN) or (get_window().mode == Window.MODE_FULLSCREEN)))
	fullscreen.connect('toggled',Callable(self,'fullscreen_toggle'))
	$BackButton.connect('pressed',Callable(self,'back_button_pressed'))
	var sound = get_widget('sound')
	sound.value = settings.sound_volume
	sound.connect('value_changed',Callable(self,'sound_changed'))
	var music = get_widget('music')
	music.value = settings.music_volume
	music.connect('value_changed',Callable(self,'music_changed'))
	set_default_menu_button($BackButton)

func get_widget(name):
	if name == 'fullscreen':
		return $GridNames/FullscreenCheckBox
	elif name == 'fullscreen_label':
		return $GridNames/FullscreenLabel
	elif name == 'sound':
		return $GridAudio/HSliderSound
	elif name == 'music':
		return $GridAudio/HSliderMusic
	elif name == 'reset':
		return $GridNames/ResetButton

func customize_to_platform():
	if util.mobile:
		get_widget('fullscreen').visible = false
		get_widget('fullscreen_label').visible = false

func fullscreen_toggle(state):
	if state == true:
		get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (true) else Window.MODE_WINDOWED
	else:
		get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (false) else Window.MODE_WINDOWED
	var fullscreen = get_widget('fullscreen')
	fullscreen.set_pressed(((get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN) or (get_window().mode == Window.MODE_FULLSCREEN)))

func back_button_pressed():
	settings.save_settings_config()
	menus.back()

func sound_changed(value):
	settings.sound_volume = value
	audio.set_sound_volume(settings.sound_volume)

func music_changed(value):
	settings.music_volume = value
	audio.set_music_volume(settings.music_volume)

func notify_fullscreen():
	var fullscreen = get_widget('fullscreen')
	fullscreen.set_pressed(((get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN) or (get_window().mode == Window.MODE_FULLSCREEN)))
