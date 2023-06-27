extends Node

# Edit "override.cfg" in the project directory for further overrides

# DEV HACKS to advance state, etc.
# - meant to be unused for release, for example a mobile app detected
# - to advance debug checked mobile, need to hack again!
var dev_file = "res://dev.tmp"

# dev settings
# IMPORTANT: never change them here, change in launch_hacks() or other function
var dev_mode_enabled = true
var cheats = false
var feature_previews = false
var fast = true # makes animations faster, for dev+testing (todo)
var fast_speed = 0.33
var forced_window = false
var allow_mouse_cursor = true # turn unchecked for recording videos
var hide_system_cursor = true
var autoscreenshot_timer = false
var autoscreenshot_resolution = Vector2(640,360)
var autoscreenshot_hidecursor = true
var dev_sound_volume = false
var dev_music_volume = false
var no_hud_ever = false
var no_overlay_ever = false
var debug_overlay = false
var debug_player = false
var spawn_point = false
var spawn_add = Vector2.ZERO
var player_effect_test = false
var shader_test = false
var never_fade_cutscene = false
var emulate_touch = false
var emulate_touch_mouse = false
var force_show_touch = false
var unlocked_everything = false
var starting_weapon = false
var silence = false
var no_music = false
var captured_npcs_hack = false
var cutscene_dev_scene = false
var cutscene_dev_frame = false
var launch_menu_override = false
var launch_scene_override = false
var skip_transitions = false
var hide_mouse_cursor = false
var skip_first_song = false

func launch_hacks():
	#silence = true
	no_music = true
	#forced_window = Vector2(640,360)
	#debug_overlay = true
	#game.demo = false
	#game.launch_menu = game.default_level
	### PLAYER
	#game.invincible = true
	#game.invisible = true
	### WINDOW
	#emulate_touch = true
	#emulate_touch_mouse = true
	#shader_test = 'whirl'
	pass

func game_hacks():
	pass

func post_launch_hacks():
	pass

func _init():
	# IMPORTANT: 'dev.tmp' needs to be created by you,
	#  and should never be added to release builds
	if util.file_exists(dev_file):
		print("DEV MODE ENABLED")
		dev_mode_enabled = true
