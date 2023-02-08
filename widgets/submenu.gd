extends Control

# Copyright (C) 2018 Naturally Intelligent

var no_back_button = true
var up_front = false # different than visible (settled in front of player)
var sliding_in = false
var sliding_out = false
var sliding_tween = false
var view_point = Vector2(80,0)
var leave_point = Vector2(-300,0)
var entry_point = Vector2(80,220)
var side_point = Vector2(-10,0)
var to_the_side = false

@export var show_sound = false
@export var leave_sound = false

func _ready():
	view_point = get_position()
	leave_point.y = view_point.y

# generic leave call (override)
func leave():
	set_visible(false)
	to_the_side = false
	up_front = false
	sliding_in = false
	sliding_out = false

func is_on_screen():
	if sliding_in: return true
	if up_front: return true
	return false

func animating():
	if sliding_in: return true
	if sliding_out: return true
	if sliding_tween: return true
	return false

# generic show call (override)
func show():
	set_visible(true)

func flip():
	if up_front:
		leave()
	else:
		show()

func ensure_out():
	if up_front or sliding_in:
		slide_out()

func slide_in_only():
	if not up_front and not animating():
		slide_in()

func slide_in_out():
	if sliding_in:
		slide_out()
	elif sliding_out:
		slide_in()
	elif up_front:
		slide_out()
	else:
		slide_in()

func slide_over_or_out():
	if to_the_side:
		slide_out()
	else:
		slide_over()

func slide_in():
	if not sliding_in:
		var p = entry_point
		if sliding_tween:
			sliding_tween.stop_all()
			sliding_tween = null
			sliding_out = false
			p = get_position()
		sliding_in = true
		sliding_out = false
		to_the_side = false
		up_front = false
		set_visible(true)
		var tween = Tween.new()
		tween.interpolate_property(
			self, "position",
			p, view_point, 0.5,
			Tween.TRANS_SINE, Tween.EASE_OUT)
		add_child(tween)
		tween.start()
		if show_sound:
			audio.play_sound(show_sound)
		sliding_tween = tween
		await tween.finished
		to_the_side = false
		sliding_tween = false
		sliding_in = false
		up_front = true

func slide_out():
	if not sliding_out:
		var p = get_position()
		if sliding_tween:
			sliding_tween.stop_all()
			sliding_tween = null
			sliding_in = false
		sliding_out = true
		sliding_in = false
		to_the_side = false
		up_front = false
		var tween = Tween.new()
		tween.interpolate_property(
			self, "position",
			p, leave_point, 0.25,
			Tween.TRANS_SINE, Tween.EASE_OUT)
		add_child(tween)
		tween.start()
		sliding_tween = tween
		if leave_sound:
			audio.play_sound(leave_sound)
		await tween.finished
		to_the_side = false
		sliding_tween = false
		sliding_out = false
		set_visible(false)

func slide_over():
	if sliding_tween:
		sliding_tween.stop_all()
		sliding_tween = null
	var p = get_position()
	sliding_out = false
	sliding_in = false
	up_front = true
	set_visible(true)
	var tween = Tween.new()
	tween.interpolate_property(
		self, "position",
		p, side_point, 0.5,
		Tween.TRANS_SINE, Tween.EASE_OUT)
	add_child(tween)
	tween.start()
	sliding_tween = tween
	await tween.finished
	to_the_side = true


