extends TextureButton
class_name CalmButton

# CALM TEXTURE BUTTON
#
#  Doesn't glitch out when cursor entered/exited quickly
#  Must Set these Textures: Normal, Pressed, Hover
#   Normal texture changed to Hover/Normal checked timers
#
#  TODO: Test for joystick/keyboard/touch
#  TODO: Have another small delay after returning to normal before next hover?

@export var hover_time = 0.5
signal on_hover_state
signal on_normal_state

@onready var normal_tex = texture_normal
@onready var hover_tex = texture_hover

var has_hint = false
@export var hide_hint = true

var has_indicator = false

func _ready():
	connect("mouse_entered",Callable(self,"to_hover_state"))
	connect("mouse_exited",Callable(self,"to_normal_state"))
	connect("focus_entered",Callable(self,"to_hover_state"))
	connect("focus_exited",Callable(self,"to_normal_state"))
	$HoverTimer.wait_time = hover_time
	$HoverTimer.connect("timeout",Callable(self,"set_normal_textures"))
	texture_normal  = normal_tex
	texture_hover = normal_tex
	if has_node('Hint'):
		has_hint = true
		do_hide_hint()
	if has_node('Indicator'):
		has_indicator = true
		do_hide_indicator()

func to_hover_state():
	$HoverTimer.stop()
	if has_hint: show_hint()
	if has_indicator: show_indicator()
	if hover_tex != texture_hover:
		set_hover_textures()
		emit_signal('on_hover_state')

func to_normal_state():
	$HoverTimer.start()
	if has_hint: do_hide_hint()
	if has_indicator: do_hide_indicator()

func set_normal_textures():
	if is_pressed():
		$HoverTimer.start()
	else:
		texture_normal  = normal_tex
		texture_hover = normal_tex
		if has_hint: do_hide_hint()
		if has_indicator: do_hide_indicator()
		emit_signal('on_normal_state')

func set_hover_textures():
	texture_normal  = hover_tex
	texture_hover = hover_tex

func on_textures_changed():
	normal_tex = texture_normal
	hover_tex = texture_hover
	texture_normal  = normal_tex
	texture_hover = normal_tex

func show_hint():
	var hint = get_node('Hint')
	hint.visible = true

func do_hide_hint():
	if hide_hint:
		var hint = get_node('Hint')
		hint.visible = false

func show_indicator():
	if not root.last_input_mouse and settings.show_hints:
		var indicator = get_node('Indicator')
		indicator.visible = true

func do_hide_indicator():
	var indicator = get_node('Indicator')
	indicator.visible = false
