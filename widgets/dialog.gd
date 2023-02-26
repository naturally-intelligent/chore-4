extends VBoxContainer
class_name DialogWidget

# a Dialog container
# Chore Engine

# BUBBLE STYLE
enum BubbleStyle {
	DEFAULT_GRAY,
	TURQUOISE_ROUND, GREEN_ROUND,
	RED_SQUARE, DOUBLE_RED_LINE,
}
@export var dialog_id: String = ""
@export var bubble_style: BubbleStyle : set = set_bubble_style
@export var font_color_override: bool = false
@export var font_color = Color(1,1,1,1) # (Color, RGBA)
@export var fading_bubbles: int = 0
@export var fade_alpha: float = 0.2
# if the text is only one line, add this to the bubble size
@export var extra_one_line_bubble_height: int = 0
# if the text more than one line, subtract from the bubble size * lines-1
@export var extra_multiline_bubble_height_multiplier: int = 0
@export var check_key_input: bool = true
@export var inner_bubble_margins: int = 19

@export var dialog_bubble_scene: String = settings.dialog_bubble_tscn
@export var choice_bubble_scene: String = settings.choice_bubble_tscn
@export var action_bubble_scene: String = settings.action_bubble_tscn

var dialog_bubble_tscn
var choice_bubble_tscn
var action_bubble_tscn

var white_fonts = [BubbleStyle.DEFAULT_GRAY]

var dialog = {}
var dialog_index = 0
var dialog_speed = 2
var dialog_timer = dialog_speed - 0.5
var dialog_size
var dialog_position
var choice_height = 20
var auto_leave = false
var dialog_action = false
var align_choices = 'left'
var user_advance = false
var dialog_leave_y = 0
var dialog_pos_y = 0
var bump_ahead = false
var auto_remove = false
var auto_remove_limit = 2
var auto_remove_speed = 5
var auto_remove_timers = {}
var no_duplicates = false
var click_removes = false
var animating_entry = false
var talk_script = false
var bubble_grow_time = 0.25
var next_action_timer = 0
var next_action_delay = bubble_grow_time + 1.5 # delay until user can do something
var dialog_closed = false

func widget():
	return self

func _ready():
	dialog_bubble_tscn = load(dialog_bubble_scene)
	choice_bubble_tscn = load(choice_bubble_scene)
	action_bubble_tscn = load(action_bubble_scene)
	if not check_key_input:
		set_process_unhandled_key_input(false)
	dialog_size = get_size()
	dialog_position = get_position()
	if dialog_id == "":
		dialog_id = name

func _process(delta):
	if dialog_closed:
		return
	if next_action_timer > 0:
		next_action_timer = next_action_timer - delta
	if auto_remove:
		for name_id in auto_remove_timers:
			var bubble = false
			for child in get_children():
				if child.get_name() == name_id: bubble = child
			if bubble:
				var counter = auto_remove_timers[name_id]
				counter = counter - delta
				auto_remove_timers[name_id] = counter
				if counter <= 0:
					bubble.queue_free()
					remove_child(bubble)
					auto_remove_timers.erase(name_id)
			else:
				auto_remove_timers.erase(name_id)
	match dialog_action:
		'leave':
			# using a tween for easier pixel-locked movement
			dialog_action = 'leave-checked'
			var tween: Tween = create_tween()
			var new_pos = get_position()
			new_pos.y = new_pos.y - get_size().y
			position = get_position()
			tween.set_trans(Tween.TRANS_LINEAR)
			tween.set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(self, "position", new_pos, 0.5)
			await tween.loop_finished
			delete_dialogs()
			dialog_action = false
		'leave-pixel':
			var p = get_position()
			dialog_leave_y = dialog_leave_y + 200 * delta
			p.y = dialog_pos_y - dialog_leave_y
			set_position(p)
			if p.y + get_size().y < 0:
				delete_dialogs()
				dialog_action = false
	if fading_bubbles > 0:
		fade()

# connects to parent scene nodes (may not be necessary or wanted)
func connect_scene(scene):
	if scene.has_node('DialogBackButton'):
		var dbb = scene.get_node('DialogBackButton')
		dbb.connect('pressed',Callable(self,'dialog_press'))

func connect_script(a_script):
	talk_script = a_script

func set_bubble_style(style):
	bubble_style = style
	# set font color (doesnt help in editor)
	#if not (bubble_style in white_fonts):
	#	font_color = Color(0,0,0,1)

func bump_dialog(plus_y=0):
	if !dialog_action:
		var size_y = get_minimum_size().y
		if size_y > dialog_size.y:
			size_y += plus_y
			set_position(Vector2(dialog_position.x, dialog_position.y - (size_y-dialog_size.y)))

func build_dialog(text, type='dialog'):
	if no_duplicates:
		for child in get_children():
			var t1 = util.clean_string(child.get_text())
			var t2 = util.clean_string(text)
			if t1 == t2:
				if auto_remove:
					auto_remove_timers.erase(child.get_name())
				child.queue_free()
	if dialog_action:
		delete_dialogs()
		dialog_action = false
	visible = true
	var max_bubble_width = dialog_size.x
	var inner_text_width = max_bubble_width - inner_bubble_margins
	var line_spacing = 2 # todo: get from text label
	# bubble background (ninepatchrect)
	var dialog_bubble
	if type == 'dialog':
		dialog_bubble = dialog_bubble_tscn.instantiate()
	elif type == 'choice':
		dialog_bubble = choice_bubble_tscn.instantiate()
	elif type == 'action':
		dialog_bubble = action_bubble_tscn.instantiate()
	else:
		dialog_bubble = dialog_bubble_tscn.instantiate()
	var bubble = dialog_bubble.get_bubble()
	var container = dialog_bubble.get_text_container()
	var label = dialog_bubble.get_text_label()
	if type=='dialog':
		dialog_bubble.set_background('Dialog9P')
	elif type=='action':
		dialog_bubble.set_background('Action9P')
	elif type=='choice':
		dialog_bubble.set_background('ChoiceButton')
	elif type=='player':
		dialog_bubble.set_background('Player9P')

	#var font = label.get('theme_override_fonts/normal_font')
	#var _theme = util.find_theme(self)
	#var font = _theme.default_font
	#if font == null:
	var font = load(ProjectSettings.get_setting('gui/theme/custom_font'))
	var data = text_in_box_shape(text, font, line_spacing, inner_text_width)
	var formatted_text = data[0]
	var text_h = data[1]
	var text_lines = data[2]
	var smallest_w = data[3]

	# calculate text size
	#label.set_text(formatted_text)
	if text_lines < 1: text_lines = 1
	var text_w = inner_text_width
	var bubble_height = text_h + 3 + 3
	var bump_height = bubble_height
	if text_lines == 1 and type != 'choice': # vcenter text a bit for 1 line bubbles
		container.set("custom_constants/offset_top", 4)
		bubble_height = bubble_height - 1
		text_w = smallest_w
	var bubble_width = text_w + 19
	if bubble_width > max_bubble_width:
		bubble_width = max_bubble_width
	if type == 'action':
		bump_height += 34
	elif type == 'choice':
		bump_height += 34
		if text_lines == 1:
			container.set("custom_constants/offset_top", 8)
			bubble_height += 8
		bubble_width = dialog_size.x
	#debug.print(text, ': ', font_height, ' ',text_size,' ',text_lines,' ',text_w,'x',text_h)

	# press signal
	if click_removes:
		var button = dialog_bubble.get_button('AdvanceButton')
		button.visible = true
		button.connect('pressed',Callable(self,'bubble_press').bind(dialog_bubble))

	# best guess scroll the dialog up...
	if bump_ahead:
		var separation = 2 #self.get_custom_constant('separation')
		self.bump_dialog(bump_height + separation)

	if text_lines == 1:
		bubble_height += extra_one_line_bubble_height
	if text_lines > 1:
		bubble_height += extra_multiline_bubble_height_multiplier * (text_lines-1)

	bubble.set_h_size_flags(SIZE_FILL)
	#dialog_bubble.set_size_direct(bubble_width, bubble_height, formatted_text)
	#dialog_bubble.grow_animation(bubble_width, bubble_height, bubble_grow_time, formatted_text)
	# changed to return original text to preserve bbcode, may cause issue?
	return [dialog_bubble, bubble_width, bubble_height, bubble_grow_time, text]
	#return dialog_bubble

	# set size
	#bubble.set_size(Vector2(bubble_width, bubble_height))
	#bubble.set_custom_minimum_size(Vector2(bubble_width, bubble_height)) # req for vbox
	#bubble.set_h_size_flags0(SIZE_SHRINK_BEGIN) # stop horizontal expansion in vbox

	#return bubble

func create_dialog(text, type='dialog'):
	var bubble_data = build_dialog(text, type)
	var bubble = bubble_data[0]
	if bubble:
		var _bubble_width = bubble_data[1]
		var _bubble_height = bubble_data[2]
		var _bubble_grow_time = bubble_data[3]
		var _formatted_text = bubble_data[4]
		add_child(bubble)
		bubble.grow_animation(_bubble_width, _bubble_height, _bubble_grow_time, _formatted_text)
		if auto_remove:	auto_remove_timers[bubble.get_name()] = auto_remove_speed
		#queue_sort() #https://godotdevelopers.org/forum/discussion/18760/create-scroll-checked-vboxcontainer

func create_action(text):
	var bubble_data = build_dialog(text, 'action')
	var bubble = bubble_data[0]
	if bubble:
		var _bubble_width = bubble_data[1]
		var _bubble_height = bubble_data[2]
		var _bubble_grow_time = bubble_data[3]
		var _formatted_text = bubble_data[4]
		add_child(bubble)
		bubble.grow_animation(_bubble_width, _bubble_height, _bubble_grow_time, _formatted_text)
		if auto_remove:	auto_remove_timers[bubble.get_name()] = auto_remove_speed
		auto_remove_bubbles()

func create_player(text):
	var bubble_data = build_dialog(text, 'player')
	var bubble = bubble_data[0]
	if bubble:
		var _bubble_width = bubble_data[1]
		var _bubble_height = bubble_data[2]
		var _bubble_grow_time = bubble_data[3]
		var _formatted_text = bubble_data[4]
		if align_choices == 'right':
			var hbox = HBoxContainer.new()
			hbox.set_alignment(BoxContainer.ALIGNMENT_END)
			hbox.add_child(bubble)
			add_child(hbox)
			bubble.grow_animation(_bubble_width, _bubble_height, _bubble_grow_time, _formatted_text)
			if auto_remove:	auto_remove_timers[hbox.get_name()] = auto_remove_speed
		elif align_choices == 'left':
			add_child(bubble)
			bubble.grow_animation(_bubble_width, _bubble_height, _bubble_grow_time, _formatted_text)
			if auto_remove:	auto_remove_timers[bubble.get_name()] = auto_remove_speed
		auto_remove_bubbles()

# marker
func create_choice(text, marker, object=null):
	var bubble_data = build_dialog(text, 'choice')
	var bubble = bubble_data[0]
	if bubble:
		var _bubble_width = bubble_data[1]
		var _bubble_height = bubble_data[2]
		var _bubble_grow_time = bubble_data[3]
		var _formatted_text = bubble_data[4]
		if object:
			var button = bubble.get_choice_button()
			button.connect("pressed",Callable(object,"on_choice_press").bind(dialog_id, marker, text))
		#bubble.set_custom_minimum_size(Vector2(dialog_size.x, 1))
		add_child(bubble)
		bubble.grow_animation(_bubble_width, _bubble_height, _bubble_grow_time, _formatted_text)
		if auto_remove:	auto_remove_timers[bubble.get_name()] = auto_remove_speed
		auto_remove_bubbles()
		next_action_timer = next_action_delay
		return bubble

func reset():
	delete_dialogs()

func dialog_press():
	if dialog_closed:
		return
	if any_animating():
		return false
	if next_action_timer > 0:
		return false
	dialog_timer = dialog_speed
	user_advance = true
	if talk_script: talk_script.dialog_press()
	return true

func bubble_press(bubble):
	if dialog_closed:
		return
	if bubble.animating:
		return
	if next_action_timer > 0:
		return false
	if click_removes:
		if auto_remove:
			auto_remove_timers.erase(bubble.get_name())
		bubble.queue_free()
	else:
		dialog_press()

func _unhandled_key_input(event):
	if dialog_closed:
		return
	if check_key_input:
		if Input.is_action_pressed("ui_accept"):
			dialog_press()

func clear_dialogs():
	#delete_dialogs()
	#dialog_action = false
	dialog_leave_y = 0
	dialog_pos_y = get_position().y
	dialog_action = 'leave'

func delete_dialogs():
	dialog_action = false
	auto_remove_timers = {}
	for child in get_children():
		child.queue_free()
	original_position()

func original_position():
	set_size(dialog_size)
	set_position(dialog_position)

func text_in_box_shape(text, font, line_spacing, max_w):
	#print('text', text, 'max_w', max_w)
	var shape_text = util.strip_bbcode(text)
	var words = shape_text.replace("\n", ' ').replace('  ', ' ').split(' ')
	var line = ''
	var final_line = ''
	var full_text = ''
	var line_count = 0
	var first = true
	var i = 0
	var smallest_line = 100000
	var final_line_size = 0

	#print('words', words, shape_text, words.size())

	# shape text into box constrained horizontally by max_w
	while i < words.size():
		var word = words[i]
		var last = i==words.size()-1
		if !first: line += ' '
		line += word
		var line_size = font.get_string_size(line).x
		#print(i,' ',line_count,' ',word, ', pre=',final_line,' ',line_size)
		# overrun
		if line_size > max_w:
			line_count += 1
			if line_count > 1:
				full_text += "\n"
			full_text += final_line
			final_line = ''
			line = ''
			first = true
			i -= 1 # go back one word, we overran
			if final_line_size < smallest_line: smallest_line = final_line_size
		# keep going to next word
		else:
			if !first: final_line += ' '
			final_line += word
			first = false
			# unless its the last word...
			if last:
				if line_count >= 1:
					full_text += "\n"
				full_text += final_line
				if line_size < smallest_line: smallest_line = line_size
				line_count += 1
		final_line_size = line_size
		i += 1

	if line_count < 1: line_count = 1
	var line_height = font.get_height() + line_spacing
	var text_height = line_count * line_height

	#print('full text = ',full_text,' line count = ',line_count)

	return [full_text, text_height, line_count, smallest_line]

func auto_remove_bubbles():
	# autoremove
	if auto_remove:
		if auto_remove_limit:
			remove_max_bubbles(auto_remove_limit)

func remove_max_bubbles(limit):
	if auto_remove_timers.size() > limit:
		var removes = auto_remove_timers.size() - limit
		for i in range(0,removes):
			var top = 10000
			var top_bubble = false
			for name_id in auto_remove_timers:
				var bubble = false
				for child in get_children():
					if child.get_name() == name_id: bubble = child
				if bubble:
					var counter = auto_remove_timers[name_id]
					if counter < top:
						top_bubble = bubble
						top = counter
				else:
					auto_remove_timers.erase(name_id)
			if top_bubble:
				top_bubble.queue_free()
				remove_child(top_bubble)
				auto_remove_timers.erase(top_bubble.get_name())

func any_animating():
	for child in get_children():
		if child.animating:
			return true
	return false

func finish_animating():
	for child in get_children():
		if child.animating:
			child.finish_animating()

func is_empty():
	if get_child_count() > 0:
		return false
	return true

func fade():
	var fade_step = fade_alpha
	var count = 0
	var total = get_child_count()
	for child in get_children():
		count = count + 1
		var position = total - count + 1
		if position > fading_bubbles:
			var alpha = (1.0 + fading_bubbles*fade_step) - (position*fade_step)
			#print(position, ' ', fade_bubbles, ' = ', alpha)
			child.modulate.a = alpha
	#$Tween.tween_property($AnimatedSprite2D, "modulate",
	#    Color(1, 1, 1, 1), Color(1, 1, 1, 0), 2.0,
	#    Tween.TRANS_LINEAR, Tween.EASE_IN)
