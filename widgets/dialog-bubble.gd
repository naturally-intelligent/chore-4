extends Control
class_name DialogBubble

var animating = false
var future_text = ''
var appear_sound = 'dialog_appear'
var hover_sound = 'dialog_hover'
var press_sound = 'dialog_confirm'

func _ready():
	var label = get_text_label()
	label.set_text('')
	$Bubble.set_size(Vector2(0,0))
	$Bubble.set_custom_minimum_size(Vector2(0, 0))
	$Bubble.set_h_size_flags(1)
	if hover_sound:
		audio.button_hover_sounds($Bubble/Backgrounds/ChoiceButton, hover_sound)

func set_size_direct(dx, dy, text):
	set_size(Vector2(dx, dy))
	set_custom_minimum_size(Vector2(dx, dy))
	set_h_size_flags(0)
	$Bubble.set_size(Vector2(dx, dy))
	$Bubble.set_custom_minimum_size(Vector2(dx, dy))
	$Bubble.set_h_size_flags(0)
	var label = get_text_label()
	set_text(text)
	label.set_size(Vector2(dx, dy))
	get_minimum_size()
	$Bubble.get_minimum_size()
	label.get_minimum_size()
	animating = false

func set_text(text):
	var label = get_text_label()
	if text.count('[') > 0:
		label.bbcode_enabled = true
		label.set_bbcode(text)
	else:
		label.set_text(text)

func grow_animation(dx, dy, time, text):
	if animating: return
	animating = true
	disable_button()

	# Prep for Animation
	future_text = text
	set_size(Vector2(dx, dy))
	set_custom_minimum_size(Vector2(dx, dy))
	set_h_size_flags(0)
	$Bubble.set_size(Vector2(0, 0))

	# wait a tiny bit for next frame to bump vbox up
	$Bubble.visible = false
	await util.wait(0.05, self).timeout
	$Bubble.visible = true

	if appear_sound:
		audio.play_sound(appear_sound)

	# grow animation
	var tween = property_tween('size', 0,0, dx,dy, time)
	await tween.finished
	$Bubble.set_custom_minimum_size(Vector2(dx, dy))
	$Bubble.set_h_size_flags(0)
	#var label = get_text_label()
	set_text(future_text)
	animating = false
	enable_button()

func property_tween(property, ox,oy, dx,dy, time):
	var tween = Tween.new()
	tween.interpolate_property(
		$Bubble, property,
		Vector2(ox,oy), Vector2(dx,dy),
		time,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	add_child(tween)
	tween.start()
	return tween

func get_text():
	if animating:
		return future_text
	else:
		var label = get_text_label()
		if label: # why would this be null? happens in duplicate check, coffee
			return label.get_text()
	return ''

func get_bubble():
	return $Bubble

func get_text_container():
	return $Bubble/TextContainer

func get_text_label():
	return $Bubble/TextContainer/TextLabel

func get_choice_button():
	return $Bubble/Backgrounds/ChoiceButton

func hide_backgrounds():
	for child in $Bubble/Backgrounds.get_children():
		child.visible = false

func set_background(bg_name):
	hide_backgrounds()
	var node = $Bubble/Backgrounds.get_node_or_null(bg_name)
	if node:
		node.visible = true
	else:
		pass

func get_button(b_name):
	var node = $Bubble/Backgrounds.get_node_or_null(b_name)
	return node

func disable_button():
	var button1 = get_button("ChoiceButton")
	if button1: button1.disabled = true
	var button2 = get_button("AdvanceButton")
	if button2: button2.disabled = true

func enable_button():
	var button1 = get_button("ChoiceButton")
	if button1: button1.disabled = false
	var button2 = get_button("AdvanceButton")
	if button2: button2.disabled = false

func finish_animating():
	# todo: allow user to force end of animation
	# requires saving tween and dx/dy
	pass
