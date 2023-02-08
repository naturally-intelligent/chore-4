# Chore Engine
#
#  This is a scene base class for menus that contain
# dialog style scenes

extends "res://engine/base.gd"

var loaded_scene = false
var current_scene = false
var current_beat = 0
var current_beat_max = 0
var scenes = {}
var events = {}
var history = {}
var counters = {}
var timers = {}
var step = 0
var manual_scene = false

func _process(delta):
	step = step + delta
	# enact events
	for event_name in events:
		var event = events[event_name]
		# mark first run of event
		# timer style events
		if 'timer' in event:
			if step > event['timer']:
				event['start-time'] = step
				event['loop-count'] += 1
				if 'func-call' in event:
					event['func-call'].call_func(event_name, event, delta)
				if 'max-loops' in event:
					if event['loop-count'] >= event['max-loops']:
						clear_event(event_name)
		# run-every-frame style events
		else:
			if 'func-call' in event:
				event['func-call'].call_func(event_name, event, delta)


func load_scene_file(filename):
	var config = util.load_config(filename, false)
	if not config:
		print("MISSING SCENE: ", filename)
		loaded_scene = false
		return false
	# let know we have a scene ready
	for section_name_upper in config:
		var section = config[section_name_upper]
		var scene_name = section_name_upper.to_lower()
		if not section:
			debug.print('Exterior dialog section not found: '+section_name_upper)
			loaded_scene = false
			return false
		#debug.print(section)
		var scene = {}
		# methods
		var first = section[1].split(',')
		#debug.print(first)
		scene['method'] = first[0]
		scene['skip'] = first[1]
		scene['loop'] = first[2]
		manual_scene = false
		if scene['method'] == 'manual':
			manual_scene = true
		# beats
		var beat_count = 0
		scene['beats'] = []
		for i in range(2,section.size()+1):
			var line = section[i]
			var data = line.split(',', true, 3)
			if data.size()>=4:
				var beat = {}
				beat['character'] = data[0]
				beat['post'] = data[1]
				beat['timeout'] = int(data[2])
				beat['dialog'] = format_dialog(data[3])
				beat_count = beat_count + 1
				#debug.print(beat)
				scene['beats'].append(beat)
			else:
				debug.print('Malformed: ',line)
		#debug.print(scene['beats'])
		scene['beats_total'] = beat_count
		scenes[scene_name] = scene
	loaded_scene = true
	return loaded_scene

func format_dialog(dialog):
	dialog = dialog.replace('"', '')
	#dialog = game.text_variables(dialog) # do this later instead for more up-to-date data?
	return dialog

func set_current_scene(name):
	if loaded_scene:
		if name in scenes:
			current_scene = name
			current_beat = 0
			current_beat_max = scenes[name]['beats_total']-1
		else:
			debug.print('ERROR: Missing scene ',name)
	else:
		debug.print('ERROR: No loaded data for scene ',name)

func get_scene_beat(beat_index=false):
	if loaded_scene:
		if current_scene:
			if not beat_index:
				beat_index = current_beat
			#debug.print('get_scene_beat ',beat_index)
			var scene = scenes[current_scene]
			var beat = scene['beats'][beat_index]
			return beat
	return false

func scene_time(step, time):
	if time >= 8:
		if dev.dev_mode_enabled:
			return step + int(time / dev.fast_speed)
		return step + time
	else:
		return step + time

func queue_event(name, time, event_data={}, function=null):
	var data = {}
	if event_data:
		for key in event_data:
			data[key] = event_data[key]
	if function:
		data['func-call'] = funcref(self, function)
	data['timer'] = step + time
	data['loop-count'] = 0
	events[name] = data
	return data

func clear_event(name):
	events.erase(name)
	history[name] = step

func get_scene_method():
	if current_scene:
		var scene = scenes[current_scene]
		if scene:
			return scene['method']
