extends Node

### DEBUG MODULE

# Try calling debug.print() instead of print() in your game
# - debug.print(...) can save to a log file and send back to an in-game widget

# echo to console (print)
var echo: bool = true
# log file
var log_file_name = false
# hook to print to your own widget
var callback_object: WeakRef = null
var print_callback = false
# debug.cat
var categories := {}
var echo_all_categories := false

func _ready():
	if OS.is_debug_build():
		echo = true
	else:
		echo = false

# call this from another object such as your game object
# - this way you can control if logs are created or not since debug is first autoload
func open_log() -> void:
	var logs_subdir := "logs"
	var dir := "user://" + logs_subdir
	util.ensure_dir(logs_subdir, "user://")

	var project_name: String = ProjectSettings.get_setting('application/config/name')
	var count := 1
	var file := project_name + "-Gameplay-%04d.txt" % count
	var file_dir := dir + '/' + file
	while(util.file_exists(file_dir)):
		count = count + 1
		file = project_name + "-Gameplay-%04d.txt" % count
		file_dir = dir + '/' + file
	# final log file name
	log_file_name = file_dir
	print('Log Location: ', OS.get_user_data_dir())
	print('Debug log: ', log_file_name)
	var log_file := FileAccess.open(log_file_name, FileAccess.WRITE)
	if log_file:
		log_file.store_line("Log started: "+log_file_name)
		log_file.close()
	else:
		print('ERROR: Cannot open log for writing!')
		log_file_name = false

func print(s1, s2='',s3='',s4='',s5='',s6='',s7='',s8='',s9='',s10='',s11='',s12='',s13='',s14='') -> void:
	if echo or log_file_name:
		var s := convert_string(s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14)
		if echo:
			print(s)
		if log_file_name:
			append_log(s)
		if print_callback and callback_object.get_ref():
			callback_object.get_ref().call(print_callback, s)

func log(s1, s2='',s3='',s4='',s5='',s6='',s7='',s8='',s9='',s10='',s11='',s12='',s13='',s14='') -> void:
	if log_file_name:
		var s := convert_string(s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14)
		if log_file_name:
			append_log(s)

# Give an object and method, for example ->
#   MyGameConsole.print_to_console(line: String)
#    calls ->
#   debug.print(MyGameConsole, "print_to_console")
func set_callback(object: Object, method: String) -> void:
	callback_object = weakref(object)
	print_callback = method

# print a dictionary
func dict(d: Dictionary, title:='') -> void:
	if title:
		print('Dict: '+title)
	for key: String in d:
		var value: Variant = d[key]
		print(str(key)+' = '+str(value))

# print an array
func array(a: Variant, title:='') -> void:
	if title:
		print('Array: '+title)
	if a is Array:
		var count := 0
		for value in a:
			print(str(count)+' = '+str(value))
			count += 1
	elif a is Dictionary:
		dict(a)

# ignore; used by debug,print()
func convert_string(s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14) -> String:
	var s := str(s1)
	var c := ' '
	if s2 or s2 is bool: s+=c+str(s2);
	else: return s
	if s3 or s3 is bool: s+=c+str(s3); 
	else: return s
	if s4 or s4 is bool: s+=c+str(s4); 
	else: return s
	if s5 or s5 is bool: s+=c+str(s5); 
	else: return s
	if s6 or s6 is bool: s+=c+str(s6);
	else: return s
	if s7 or s7 is bool: s+=c+str(s7); 
	else: return s
	if s8 or s8 is bool: s+=c+str(s8); 
	else: return s
	if s9 or s9 is bool: s+=c+str(s9); 
	else: return s
	if s10 or s10 is bool: s+=c+str(s10); 
	else: return s
	if s11 or s11 is bool: s+=c+str(s11); 
	else: return s
	if s12 or s12 is bool: s+=c+str(s12); 
	else: return s
	if s13 or s13 is bool: s+=c+str(s13); 
	else: return s
	if s14 or s14 is bool: s+=c+str(s14); 
	else: return s
	return s

# same as print(), but forced to print
func error(s1, s2='',s3='',s4='',s5='',s6='',s7='',s8='',s9='',s10='',s11='',s12='',s13='',s14='') -> void:
	var s := convert_string(s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14)
	print(s)
	append_log(s)

# debug printing by "category"
# any categories enabled will be printed to console
#  but all will still be recorded to log
func cat(_cat: String, s1, s2='',s3='',s4='',s5='',s6='',s7='',s8='',s9='',s10='',s11='',s12='',s13='',s14='') -> void:
	if echo:
		if echo_all_categories or _cat in categories:
			var _s := _cat+': '+convert_string(s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14)
			print(_s)
	if log_file_name:
		var _s := _cat+': '+convert_string(s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14)
		append_log(_s)

# add mode to keep log file open isntead of opening/closing each line?
func append_log(s: String) -> void:
	if log_file_name:
		var log_file = FileAccess.open(log_file_name, FileAccess.READ_WRITE)
		if log_file:
			log_file.seek_end()
			log_file.store_line(s)
			log_file.close()
		else:
			print('ERROR: Cannot write to log file! Aborting log.')
			log_file_name = false

# built-in console (not very good)
func console(s1, s2='',s3='',s4='',s5='',s6='',s7='',s8='',s9='',s10='',s11='',s12='',s13='',s14='') -> void:
	var s := convert_string(s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14)
	print(s)
	root.add_debug_line(s)

func print_instance(id: int) -> void:
	var object := instance_from_id(id)
	if object:
		print_object(object)

func print_object(object: Object) -> void:
	var property_list := object.get_property_list()
	for prop in property_list:
		debug.print (prop.name, object.get(prop.name))
