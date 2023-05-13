# UTILITY FUNCTIONS
@tool
extends Node

var desktop := true
var mobile := false
# specific os
var android := false
var apple := false
var windows := false
var linux := false
var osx := false
var web := false
var console := false
# touch
var touch := false

func _ready():
	platform_detection()
	input_detection()

func platform_detection():
	mobile = OS.has_feature('mobile')
	desktop = OS.has_feature('pc')
	web = OS.has_feature('web')
	match OS.get_name():
		'Android':
			android = true
		'iOS', 'macOS':
			apple = true
		'Linux':
			linux = true
		'Windows','UWP':
			windows = true
		'FreeBSD', 'NetBSD', 'OpenBSD', 'BSD':
			linux = true

func input_detection():
	touch = DisplayServer.is_touchscreen_available()

# SORT CLASSES
class FirstElementGreatest:
	static func sort(a, b):
		if a[0] > b[0]:
			return true
		return false

class FirstElementLeast:
	static func sort(a, b):
		if a[0] < b[0]:
			return true
		return false

class SecondElementGreatest:
	static func sort(a, b):
		if a[1] > b[1]:
			return true
		return false

# HELPER FUNCTIONS
#  these are all static, meaning they arent part of the 'util' object
#  but still called like -> util.fullscreen_flip()

func fullscreen_flip():
	if ((get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN) or (get_window().mode == Window.MODE_FULLSCREEN)):
		get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (false) else Window.MODE_WINDOWED
	else:
		get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (true) else Window.MODE_WINDOWED

func random(_s, _e):
	if typeof(_s) == TYPE_INT:
		return math.random_int(_s, _e)
	else:
		return math.random_float(_s, _e)

func random_boolean():
	return ((randi()%2) == 0)

func random_array(a):
	if a.size() > 0:
		var i = math.random_int(0,a.size()-1)
		return a[i]
	return null

func random_array_index(a):
	if a.size() > 0:
		var i = math.random_int(0,a.size()-1)
		return i
	return null

func random_set(_s):
	return random_array(_s)

func random_key(dict):
	var keys = dict.keys()
	if keys.size() > 0:
		var i = randi() % keys.size()
		var key = keys[i]
		return key
	else:
		return null

func random_value(dict):
	var key = random_key(dict)
	if key: return dict[key]
	return false

func random_integer_key(dict):
	var keysT = dict.keys()
	var keys = Array()
	for key in keysT:
		if typeof(key) == TYPE_INT:
			keys.append(key)
	if keys.size() > 0:
		var i = randi() % keys.size()
		var key = keys[i]
		return key
	else:
		return null

func random_vector():
	var angle = math.random_float(0,PI)
	return Vector2(cos(angle), sin(angle))

func random_direction(excluding=[]):
	var dirs = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	return random_array_excluding(dirs, excluding)

func random_left_right_up_vector(left_right_scale=1.0, up_scale=1.0):
	var angle = math.random_float(PI,PI*2)
	var v = Vector2(cos(angle), sin(angle))
	v.x *= left_right_scale
	v.y *= up_scale
	return v.normalized()

# dict is {} you want key from, exclude is array [] with keys you dont want again
func random_key_excluding(dict, exclude):
	var keysT = dict.keys()
	var keys = Array()
	for key in keysT:
		if not exclude.has(key):
			keys.append(key)
	if keys.size() > 0:
		var i = randi() % keys.size()
		var key = keys[i]
		return key
	else:
		return null

func random_value_excluding(dict, exclude=[]):
	var keysT = dict.keys()
	var keys = Array()
	for key in keysT:
		if not exclude.has(dict[key]):
			keys.append(key)
	if keys.size() > 0:
		var i = randi() % keys.size()
		var key = keys[i]
		return dict[key]
	else:
		return null

func random_array_excluding(array, exclude):
	var pool = Array()
	for a in array:
		if not a in exclude:
			pool.append(a)
	if pool.size() > 0:
		var i = randi() % pool.size()
		var v = pool[i]
		return v
	else:
		return null

func random_sign():
	if random_boolean():
		return 1
	else:
		return -1

func random_color(modifier):
	return Color(math.random_float(0,1)*modifier,
				math.random_float(0,1)*modifier,
				math.random_float(0,1)*modifier, 1)

func randomize_color(color, modifier):
	color.r += math.random_float(-modifier/2.0, modifier/2.0)
	color.r = clamp(color.r, 0, 1)
	color.g += math.random_float(-modifier/2.0, modifier/2.0)
	color.g = clamp(color.g, 0, 1)
	color.b += math.random_float(-modifier/2.0, modifier/2.0)
	color.b = clamp(color.b, 0, 1)
	return color

func random_colors(one,two):
	return Color(math.randomf(one.r,two.r), math.randomf(one.g,two.g), math.randomf(one.b,two.b), 1)

func rgb100_to_color(r,g,b):
	return Color(r/100.0, g/100.0, b/100.0, 1)

func rgb256_to_color(r,g,b,a=1.0):
	return Color(r/256.0, g/256.0, b/256.0, a)

func thousands_sep(number, prefix=''):
	number = int(number)
	var neg = false
	if number < 0:
		number = -number
		neg = true
	var string = str(number)
	var mod = string.length() % 3
	var res = ""
	for i in range(0, string.length()):
		if i != 0 && i % 3 == mod:
			res += ","
		res += string[i]
	if neg: res = '-'+prefix+res
	else: res = prefix+res
	return res

func percent_string(f: float) -> String:
	return str(int(f*100)) + '%'

func file_exists(file):
	if FileAccess.file_exists(file):
		return true
	if ResourceLoader.exists(file):
		return true
	return false

func int_to_currency(i, pennies=false):
	var cash_text = util.thousands_sep(str(i), '$')
	if pennies:	cash_text += '.00'
	return cash_text

func trim_decimals(f, places):
	return snapped(f, pow(0.1,places))

func string_upper_first(id):
	return id.substr(0,1).to_upper() + id.substr(1, id.length())

func first_letter(id):
	return id.substr(0,1)

func upper_first_letter(id):
	return id.substr(0,1).to_upper()

func a_an(word):
	var first = word.substr(0,1).to_upper()
	var vowels = ['a','e','i','o','u']
	if first in vowels:
		return 'an'
	else:
		return 'a'

func name_full(object):
	var full = ''
	if 'prefix' in object:
		full = object['prefix'] + ' '
	full+= object['first'] + ' '
	if 'middle' in object:
		full+= object['middle'] + ' '
	if 'last' in object:
		full+= object['last']
	object['full'] = full

func name_fills(object):
	name_full(object)
	object['first_upper'] = object['first'].to_upper()
	if 'last' in object:
		object['last_upper'] = object['last'].to_upper()

func first_upper(string: String):
	return string.substr(0,1).capitalize() + string.substr(1)

func first_upper_only(string: String):
	return string.substr(0,1).capitalize() + string.substr(1).to_lower()

func calculate_total(data):
	data['total'] = 0
	for col in data:
		if col != 'total':
			var amount = data[col]
			data['total'] += amount

func clean_string(_s):
	return _s.replace("\n", '').replace(" ",'')

func replace_fake_formatting(_s):
	return _s.replace("\\n", "\n")

func random_phone_number():
	var ph = '555-'
	ph+= str(math.random_int(0,9))
	ph+= str(math.random_int(0,9))
	ph+= str(math.random_int(0,9))
	ph+= str(math.random_int(0,9))
	return ph

# loads a texxt file, sectioned like:
# [Section]
# keys = values
# keys = array # if split_commas and comma detected
# values converted to ints/floats if convert_numbers, otherwise strings
func load_config(_filename, split_commas=true, convert_numbers=true):
	var path = _filename
	var file = FileAccess.open(path, FileAccess.READ)
	var records = {}
	var record = {}
	var title = ''
	var new_record = false
	var added_record = false
	var line_count = 0
	if file:
		while !file.eof_reached():
			# read a line
			var line = file.get_line()
			# comments (strip edges checked left?)
			if line.find('#')==0:
				pass
			# config section/record check
			elif line.find('[') + line.find(']') > 1:
				# store previous record
				if new_record and not added_record:
					records[title] = record
				# start new record
				var start = line.find('[')+1
				var end = line.find(']') - start
				title = line.substr(start, end)
				record = {}
				new_record = true
				added_record = false
				line_count = 0
			# add key=value line pairs to record
			elif line.find('=') >= 0:
				var data = line.split('=')
				if len(data) == 2:
					var key = data[0].strip_edges(true, true)
					var value = data[1].strip_edges(true, true)
					if split_commas:
						if value.find(',') >= 0:
							var a = value.split(',')
							var d = {}
							for i in range(0,a.size()):
								var sub_value = a[i].strip_edges(true, true)
								if convert_numbers: sub_value = util.convert_string_to_number(sub_value)
								d[i] = sub_value
							record[key] = d
						else:
							if convert_numbers: value = util.convert_string_to_number(value)
							record[key] = value
					else:
						record[key] = value
			# add non-empty, non-whitespace lines as integer indexes (starting at 1)
			elif line.strip_edges(true, true).length()>0:
				line_count = line_count + 1
				while(line_count in record): line_count = line_count + 1
				record[line_count] = line
		# store lingering record
		if new_record and not added_record:
			records[title] = record
	else:
		debug.print('ERROR: File missing: ', _filename)
	return records

func save_config(_filename, config_data, header={}, _convert_numbers=true):
	var path = _filename
	var file = FileAccess.open(path, FileAccess.WRITE)
	var records = {}
	var record = {}
	var title = ''
	if file.is_open():
		# HEADER SECTION
		if header:
			for section in header:
				var section_data = header[section]
				file.store_string('['+str(section)+']'+"\n")
				for key in section_data:
					var value = section_data[key]
					file.store_string(str(key)+"\t = "+str(value)+"\n")
				file.store_string("\n")
		# MAIN SECTION
		for section in config_data:
			var section_data = config_data[section]
			file.store_string('['+str(section)+']'+"\n")
			for key in section_data:
				var value = section_data[key]
				var tabs = 3 - key.length()/4
				if tabs < 0: tabs = 0
				var tabs_str = "\t".repeat(tabs)
				file.store_string(str(key)+tabs_str+ " = "+str(value)+"\n")
			file.store_string("\n")
		file = null
	else:
		debug.print("ERROR: can't write config file ", _filename)

# tries to convert a string to a number, if possible
func convert_string_to_number(value):
	if value.is_valid_int():
		return value.to_int()
	if value.is_valid_float():
		return value.to_float()
	return value

func set_texture(sprite, file):
	if util.file_exists(file):
		var tex = load(file)
		sprite.texture = tex
	else:
		debug.print('MISSING TEXTURE: ' + file)

func number2words(n):
	var prefix = ''
	if n < 0:
		n = -n
		prefix = 'Negative '
	var num2words = {1: 'One', 2: 'Two', 3: 'Three', 4: 'Four', 5: 'Five', \
				6: 'Six', 7: 'Seven', 8: 'Eight', 9: 'Nine', 10: 'Ten', \
				11: 'Eleven', 12: 'Twelve', 13: 'Thirteen', 14: 'Fourteen', \
				15: 'Fifteen', 16: 'Sixteen', 17: 'Seventeen', 18: 'Eighteen', \
				19: 'Nineteen', 20: 'Twenty', 30: 'Thirty', 40: 'Forty', \
				50: 'Fifty', 60: 'Sixty', 70: 'Seventy', 80: 'Eighty', \
				90: 'Ninety', 0: 'Zero'}
	if n in num2words:
		return prefix + num2words[n]
	else:
		return prefix + num2words[n-n%10] + '-' + num2words[n%10]

func number2past(n):
	var num2words = {1: 'Once', 2: 'Twice', 3: 'Thrice'}
	if n in num2words:
		return num2words[n]
	else:
		return number2words(n) + ' times'

func number2present(i):
	var n = str(i)
	var num2present = {0: 'Zeroeth', 1: 'First', 2: 'Second', 3: 'Third', \
		4: 'Fourth', 5: 'Fifth', 6: 'Sixth', 7: 'Seventh', 8: 'Eighth', \
		9: 'Ninth', 10: 'Tenth', 11: 'Eleventh', 12: 'Twelvth', \
		13: 'Thirteenth', 14: 'Fourteenth', 15: 'Fifteenth'}
	if i in num2present:
		return num2present[i]
	else:
		var last = n.substr(n.length()-1, 1)
		if last == '1':
			return number2words(i) + 'st'
		elif last == '2':
			return number2words(i) + 'nd'
		elif last == '3':
			return number2words(i) + 'rd'
		return number2words(i) + 'th'

func str_no_zero(i: int) -> String:
	if i == 0:
		return ''
	else:
		return str(i)

func index_in_list(current, list : Array):
	return list.find(current)

func next_in_list(current, list : Array):
	var index = list.find(current, 0)
	if index >= 0:
		index = index + 1
		if index >= list.size():
			index = 0
		return list[index]
	return current

func prev_in_list(current, list : Array):
	var index = list.find(current, 0)
	if index >= 0:
		index = index - 1
		if index < 0:
			index = list.size()-1
		return list[index]
	return current

# must call yield checked t after return
# because gdscript wont wait for a yield in an outside function call
func wait(time, parent=null):
	var t = Timer.new()
	t.set_wait_time(time)
	t.set_one_shot(true)
	if parent: parent.add_child(t)
	t.start()
	#await t.timeout # must call this and queue_free outside of function!
	return t

# https://github.com/godotengine/godot/issues/14562
func create_import_files_for_export(texture_dir):
	var file_list = list_files_in_directory(texture_dir)
	for file in file_list:
		if file.ends_with(".import"):
			var file_name = file.replace(".import", "")
			return load(texture_dir + file_name)

# SCREENSHOT (F5)
func screenshot(scene, scale=false, logo=false, savedir="screenshots"):
	debug.print('Screenshot...')
	# clear next frame
	RenderingServer.viewport_set_clear_mode(scene.get_viewport(), RenderingServer.VIEWPORT_CLEAR_ONLY_NEXT_FRAME)

	# hide cursor?
	var show_cursor = root.is_cursor_visible()
	if show_cursor:
		root.hide_cursor()

	if settings.screenshot_transparent_bg:
		scene.get_viewport().transparent_bg = true

	# Let two sprite_frames pass to make sure the screen was captured
	await scene.get_tree().process_frame
	await scene.get_tree().process_frame

	# Retrieve the captured image
	var img: Image = scene.get_viewport().get_texture().get_image()

	if settings.screenshot_transparent_bg:
		scene.get_viewport().transparent_bg = false

	# scale after (note, doesn't upscale pixel-art nicely)
	if scale:
		img.resize(scale.x, scale.y, Image.INTERPOLATE_NEAREST)

	# Flip it checked the y-axis (because it's flipped)
	if settings.screenshot_flip_y:
		img.flip_y()
	# color range format
	img.convert(Image.FORMAT_RGBA8)

	# optional logo (filename like "res://art/logo.png")
	if logo:
		if util.file_exists(logo):
			var logo_tex = load(logo)
			var logo_img = logo_tex.get_image()
			var logo_rect = Rect2(0,0, settings.screenshot_size.x, settings.screenshot_size.y)
			logo_img.convert(img.get_format())
			img.blend_rect(logo_img, logo_rect, Vector2(0,0))

	# Linux: ~/.local/share/godot/app_userdata/project_name
	util.ensure_dir(savedir, "user://")
	var dir = "user://" + savedir
	var files = numbered_filename(dir)
	var file = files[0]
	var file_name = files[1]
	debug.print('Saving '+file+'...')
	img.save_png(file)
	var dir_plus_file = append_separator(OS.get_user_data_dir()) + file_name
	debug.print('PNG saved to:', dir_plus_file)
	# restore cursor?
	if show_cursor:
		root.show_cursor()

func numbered_filename(dir="user://", file_prefix='', file_ext='.png'):
	if file_prefix == '':
		file_prefix = ProjectSettings.get_setting('application/config/name').replace(' ','')
	var count = 1
	var file_name = file_prefix + "-%03d" % count + file_ext
	var file_dir = append_separator(dir) + file_name
	while(file_exists(file_dir)):
		count = count + 1
		file_name = file_prefix + "-%03d" % count + file_ext
		file_dir = append_separator(dir) + file_name
	return [file_dir, file_name]

func ensure_dir(subdir, res="user://"):
	var directory = DirAccess.open(res)
	if not directory.dir_exists(subdir):
		directory.make_dir(subdir)

# https://godotengine.org/qa/5175/how-to-get-all-the-files-inside-a-folder
# - sort_by = date
# - sort_order = newest/oldest
func list_files_in_directory(path, sort_by=false, sort_order=false):
	var files = []
	var sort = []
	var dir = DirAccess.open(path)
	dir.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file)
			# collect sort info if needed
			if sort_by:
				if sort_by == 'date':
					var file_object = FileAccess.open(file, FileAccess.READ)
					var modified_time = FileAccess.get_modified_time(file)
					sort.append([file, modified_time])
	dir.list_dir_end()

	# sort?
	if sort_by and sort_by == 'date':
		if sort_order == 'newest':
			sort.sort_custom(Callable(util.FirstElementGreatest,"sort"))
			files = []
			for data in sort:
				files.append(data[0])
		elif sort_order == 'oldest':
			sort.sort_custom(Callable(util.FirstElementLeast,"sort"))
			files = []
			for data in sort:
				files.append(data[0])

	return files

# directory separator
func dir_sep():
	if util.windows:
		return '\\'
	else:
		return '/'

func append_separator(dir):
	var last = dir.substr(-1, 1)
	if last != '/' and last != '\\':
		return dir + dir_sep()
	return dir

func strip_bbcode(text):
	var regex = RegEx.new()
	regex.compile('|[[\\/\\!]*?[^\\[\\]]*?]|')
	return regex.sub(text, '', true)

func open_browser(www_url):
	return OS.shell_open(www_url)

func delete_children(node):
	for n in node.get_children():
		node.remove_child(n)
		n.queue_free()

func get_all_children(node) -> Array:
	var nodes: Array = []
	for c in node.get_children():
		if c.get_child_count() > 0:
			nodes.append(c)
			nodes.append_array(get_all_children(c))
		else:
			nodes.append(c)
	return nodes

func opposite_direction(direction: String) -> String:
	if direction == 'up':
		return 'down'
	if direction == 'down':
		return 'up'
	if direction == 'left':
		return 'right'
	if direction == 'right':
		return 'left'
	return 'none'

# TILES

func tilemap_closest_used_cell(map: TileMap, position: Vector2, direction: Vector2 = Vector2.ZERO):
	var desired_cell = map.local_to_map(position)
	if map.get_cell_source_id(0, desired_cell) == 0:#:TileMap.INVALID_CELL:
		var closest_cell = false
		var closest_distance = 1000000
		for cell in map.get_used_cells(0):
			var world_direction = position.direction_to(map.map_to_local(cell))
			if direction.x == 0 or sign(world_direction.x) == sign(direction.x):
				# we don't need to call sqrt() on distance here, just use squared values
				var distance = (desired_cell.x-cell.x)*(desired_cell.x-cell.x)+(desired_cell.y-cell.y)*(desired_cell.y-cell.y)
				if distance < closest_distance:
					closest_cell = cell
					closest_distance = distance
		return closest_cell
	return desired_cell

# STRING CONVENIENCE

func s(i: int) -> String:
	if i == 1:
		return ''
	return 's'

func unlimited(i: int) -> String:
	if i == -1:
		return 'Unlimited'
	return str(i)

func a_or_number(i: int) -> String:
	if i == 1:
		return 'a'
	return str(i)

func signed_number(i: int) -> String:
	if i < 0:
		return str(i)
	elif i > 0:
		return '+'+str(i)
	return str(i)

func string_to_bool(_s: String) -> bool:
	if _s.to_lower() == 'true':
		return true
	else:
		return false

func vector_to_string(vector) -> String:
	return "x="+str(trim_decimals(vector.x, 1))+" y="+str(trim_decimals(vector.y, 1))

func keycode_to_scancode(key_code):
	var scan_code = OS.find_keycode_from_string(key_code) # ex: Escape
	if not scan_code:
		scan_code = OS.find_keycode_from_string(key_code.substr(4)) # ex: KEY_ESCAPE
	if not scan_code:
		debug.print("Can't find scancode for ",key_code)
	return scan_code

### INPUT MAPPING
# from previously loaded config file, ex:
# [INPUT]
# KEY_A = ui_left
# KEY_D = ui_right
# KEY_LEFT = ui_left
# KEY_RIGHT = ui_right
# KEY_SPACE = ui_jump
func map_input_keys(config, allowed:=[]):
	var to_map = []
	var cleared = []
	# Check for validity of input maps, and erase any existing conflicts
	for key_code in config:
		var ui_action = config[key_code]
		var allow = (allowed.is_empty()) or ('all' in allowed) or (ui_action in allowed)
		if allow:
			var scan_code = keycode_to_scancode(key_code)
			#debug.print('Input Map Request: ', ui_action, key_code, scan_code)
			if scan_code:
				# Check if already mapped
				var _duplicate = false
				var input_events = InputMap.action_get_events(ui_action)
				for input_event in input_events:
					if input_event is InputEventKey:
						if scan_code == input_event.scancode:
							_duplicate = true
				# Erase if new
				if not _duplicate:
					for input_event in input_events:
						if input_event is InputEventKey:
							debug.print('Erasing Key:', ui_action, '<-', OS.get_keycode_string(input_event.scancode))
							InputMap.action_erase_event(ui_action, input_event)
					to_map.append(ui_action)
	# Now assign keys (this allows multiple keys per action)
	for key_code in config:
		var ui_action = config[key_code]
		if ui_action in to_map:
			debug.print('Input Map:', key_code, '-> to ->', ui_action)
			var scan_code = keycode_to_scancode(key_code)
			if scan_code:
				var new_event = InputEventKey.new()
				new_event.set_keycode(scan_code)
				InputMap.action_add_event(ui_action, new_event)

# CONFIG GAMEPADS
# from previously loaded config file, ex:
# [GAMEPAD_0]
# Button_0=ui_jump
# Button_2=ui_jump
# Button_1=ui_shoot
# Button_3=ui_flashlight
func map_gamepad_input(config):
	for device_id in range(0,8+1):
		var device_section = 'GAMEPAD_'+str(device_id)
		if device_section in config:
			debug.print("Loading input map for GAMEPAD", str(device_id))
			# Erase buttons
			for button in config[device_section]:
				var ui_action = config[device_section][button]
				var button_index = int(button.substr(9))
				var input_events = InputMap.action_get_events(ui_action)
				for input_event in input_events:
					if input_event is InputEventJoypadButton:
						if input_event.device == device_id:
							debug.print("- Erasing Button:", ui_action, '<- button', str(input_event.button_index))
							InputMap.action_erase_event(ui_action, input_event)
			# Map buttons
			for button in config[device_section]:
				var ui_action = config[device_section][button]
				var button_index = int(button.substr(7)) # Ex: Button_3
				debug.print("- Mapping Button: button", str(button_index), '-> to ->', ui_action)
				var new_event = InputEventJoypadButton.new()
				new_event.device = device_id
				new_event.set_button_index(button_index)
				InputMap.action_add_event(ui_action, new_event)
		else:
			return

func find_theme(control):
	var theme = null
	while control != null && "theme" in control:
		theme = control.theme
		if theme != null: break
		control = control.get_parent()
	return theme

func is_not(variable):
	return variable == null
