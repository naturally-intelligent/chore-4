extends Node
#
# A YARN Importer for Godot
#
# Credits:
# - Dave Kerr (http://www.naturallyintelligent.com)
#
# Latest: https://github.com/naturally-intelligent/godot-yarn-importer
#
# Yarn: https://github.com/InfiniteAmmoInc/Yarn
# Twine: http://twinery.org
#
# Yarn: a ball of threads (Yarn file)
# Thread: a series of fibres (Yarn node)
# Fibre: a text or choice or logic (Yarn line)

var yarn := {}

# OVERRIDE METHODS
#
# called to request new dialog
func say(text: String):
	pass

# called to request new choice button
func choice(text: String, marker: String):
	pass

# called to request internal logic handling
func logic(instruction: String, command: String):
	pass

# called for each line of text
func yarn_text_variables(text: String) -> String:
	return text

# called when "settings" node parsed
func story_setting(setting: String, value: String):
	pass

# called for each node name
func yarn_custom_logic(to: String):
	pass

# called for each node name (after)
func yarn_custom_logic_after(to: String):
	pass

# START SPINNING YOUR YARN
#
func spin_yarn(file: String, start_thread := ''):
	yarn = load_yarn(file)
	# Find the starting thread...
	if start_thread == '':
		start_thread = yarn['start']
	# Load any scene-specific settings
	# (Not part of official Yarn standard)
	if 'settings' in yarn['threads']:
		var settings: Dictionary = yarn['threads']['settings']
		for fibre: Dictionary in settings['fibres']:
			var line: String = fibre['text']
			var split := line.split('=')
			var setting: String = split[0].strip_edges(true, true)
			var value: String = split[1].strip_edges(true, true)
			story_setting(setting, value)
	# First thread unravel...
	return yarn_unravel(start_thread)

# Internally create a new thread (during loading)
func new_yarn_thread() -> Dictionary:
	var thread := {}
	thread['title'] = ''
	thread['kind'] = 'branch' # 'branch' for standard dialog, 'code' for gdscript
	thread['tags'] = [] # unused
	thread['fibres'] = []
	thread['header'] = {} # all the command before dialog, like title: intro
	return thread

# Internally create a new fibre (during loading)
func new_yarn_fibre(line: String) -> Dictionary:
	var first_two := line.substr(0,2)
	# choice fibre
	if first_two == '[[':
		if line.find('|') != -1:
			var fibre := {}
			fibre['kind'] = 'choice'
			line = line.replace('[[', '')
			line = line.replace(']]', '')
			var split := line.split('|')
			fibre['text'] = split[0]
			fibre['marker'] = split[1]
			return fibre
	# logic instruction (not part of official Yarn standard)
	elif first_two == '<<':
		if line.find(':') != -1:
			var fibre := {}
			fibre['kind'] = 'logic'
			line = line.replace('<<', '')
			line = line.replace('>>', '')
			var split := line.split(':')
			fibre['instruction'] = split[0]
			fibre['command'] = split[1]
			#print(line, split[0], split[1])
			return fibre
	# comment ##
	elif first_two == '##':
		var fibre := {}
		fibre['kind'] = 'comment'
		fibre['text'] = line.strip_edges(true, true)
		return fibre
	# text fibre
	var new_fibre := {}
	new_fibre['kind'] = 'text'
	new_fibre['text'] = line.strip_edges(true, true)
	return new_fibre

# Create Yarn data structure from file (must be *.yarn.txt Yarn format)
func load_yarn(path: String) -> Dictionary:
	var new_yarn := {}
	new_yarn['threads'] = {}
	new_yarn['start'] = ''
	new_yarn['file'] = path
	var file = FileAccess.open(path, FileAccess.READ)
	if file.is_open():
		# yarn reading flags
		var start := false
		var header := true
		var thread := new_yarn_thread()
		# loop
		while !file.eof_reached():
			# read a line
			var line := file.get_line()
			# header read mode
			if header:
				if line == '---':
					header = false
				else:
					var split := line.split(': ', true, 2)
					if split.size() == 2:
						thread['header'][split[0]] = split[1]
						if split[0] == 'title':
							var title_split := split[1].split(':')
							var thread_title := ''
							var thread_kind := 'branch'
							if len(title_split) == 1:
								thread_title = split[1]
							else:
								thread_title = title_split[1]
								thread_kind = title_split[0]
							thread['title'] = thread_title
							thread['kind'] = thread_kind
							if new_yarn['start'] == '':
								new_yarn['start'] = thread_title
			# end of thread
			elif line == '===':
				header = true
				new_yarn['threads'][thread['title']] = thread
				thread = new_yarn_thread()
			# fibre read mode
			else:
				var fibre := new_yarn_fibre(line)
				if fibre:
					thread['fibres'].append(fibre)
	else:
		print('ERROR: Yarn file missing: ', path)
	return new_yarn

# Main logic for node handling
#
func yarn_unravel(to:String, from:=false) -> Dictionary:
	var thread: Dictionary
	yarn_custom_logic(to)
	if to in yarn['threads']:
		thread = yarn['threads'][to]
		yarn_header(thread['header'])
		match thread['kind']:
			'branch':
				for fibre: Dictionary in thread['fibres']:
					match fibre['kind']:
						'text':
							var text := yarn_text_variables(fibre['text'])
							say(text)
						'choice':
							var text := yarn_text_variables(fibre['text'])
							choice(text, fibre['marker'])
						'logic':
							var instruction: String = fibre['instruction']
							var command: String = fibre['command']
							logic(instruction, command)
			'code':
				yarn_code(to)
	else:
		print('WARNING: Missing Yarn thread: ', to, ' in file ',yarn['file'])
	yarn_custom_logic_after(to)
	return thread

#
# RUN GDSCRIPT CODE FROM YARN NODE - Special node = code:title
# - Not part of official Yarn standard
#
func yarn_code(title: String, run:=true, parent:='parent.', tabs:="\t", next_func:="yarn_unravel") -> String:
	if title in yarn['threads']:
		var thread: Dictionary = yarn['threads'][title]
		var code := ''
		for fibre: Dictionary in thread['fibres']:
			match fibre['kind']:
				'text':
					var line = yarn_text_variables(fibre['text'])
					line = yarn_code_replace(line, parent, next_func)
					code += tabs + line + "\n"
				'choice':
					var line = parent+next_func+"('"+fibre['marker']+"')"
					print(line)
					code += tabs + line + "\n"
		if run:
			run_yarn_code(code)
		else:
			return code
	else:
		print('WARNING: Title missing in yarn ball: ', title)
	return ''

# override to replace convenience variables
func yarn_code_replace(code: String, parent:='parent.', next_func:="yarn_unravel") -> String:
	if code.find("[[") != -1:
		code = code.replace("[[", parent+next_func+"('")
		code = code.replace("]]", "')")
	code = code.replace("say(", parent+"say(")
	code = code.replace("choice(", parent+"choice(")
	return code

func run_yarn_code(code: String):
	var front = "extends Node\n"
	front += "func dynamic_code():\n"
	front += "\tvar parent = get_parent()\n\n"
	code = front + code
	#print("CODE BLOCK: \n", code)

	var script = GDScript.new()
	script.set_source_code(code)
	script.reload()

	#print("Executing code...")
	var node = Node.new()
	node.set_script(script)
	add_child(node)
	var result = node.dynamic_code()
	remove_child(node)

	return result

func yarn_header(header: String):
	pass

# EXPORTING TO GDSCRIPT
#
# This code may not be directly usable
# Use if you need an exit from Yarn

func export_to_gdscript():
	var script = ''
	script += "func start_story():\n\n"
	if 'settings' in yarn['threads']:
		var settings = yarn['threads']['settings']
		for fibre in settings['fibres']:
			var line = fibre['text']
			var split = line.split('=')
			var setting = split[0].strip_edges(true, true)
			var value = split[1].strip_edges(true, true)
			script += "\t" + 'story_setting("' + setting + '", "' + value + '")' + "\n"
	script += "\tstory_logic('" + yarn['start'] + "')\n\n"
	# story logic choice/press event
	script += "func story_logic(marker):\n\n"
	script += "\tmatch marker:\n"
	for title in yarn['threads']:
		var thread = yarn['threads'][title]
		match thread['kind']:
			'branch':
				var code = "\n\t\t'" + thread['title'] + "':"
				var tabs = "\n\t\t\t"
				for fibre in thread['fibres']:
					match fibre['kind']:
						'text':
							code += tabs + 'say("' + fibre['text'] + '")'
						'choice':
							code += tabs + 'choice("' + fibre['text'] + '", "' + fibre['marker'] + '")'
						'logic':
							code += tabs + 'logic("' + fibre['instruction'] + '", "' + fibre['command'] + '")'
				script += code + "\n"
			'code':
				var code = "\n\t\t'" + thread['title'] + "':"
				var tabs = "\n\t\t\t"
				code += "\n"
				code += yarn_code(thread['title'], false, '', "\t\t\t", "story_logic")
				script += code + "\n"
	# done
	return script

func print_gdscript_to_console():
	print(export_to_gdscript())

func save_to_gdscript(filename: String):
	var script = export_to_gdscript()
	# write to file
	var file = FileAccess.open(filename, FileAccess.WRITE)
	if not file.is_open():
		print('ERROR: Cant open file ', filename)
		return false
	file.store_string(script)
	file = null

