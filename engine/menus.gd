extends Node

# CHORE ENGINE
# Designed and developed by David Glen Kerr
#
# autoload 'menus' and call the user functions
#
# use show() expected for a menu system

# tracking variables
var search_dirs = []

func _ready() -> void:
	search_dirs = settings.menu_dirs
	if not settings.custom_menu_dirs_only:
		search_dirs.append_array(['menus','menu'])

### USER FUNCTIONS - call these to use menu system

func current_menu():
	var menu_count = root.menus_root.get_child_count()
	if menu_count > 0:
		return root.menus_root.get_children()[menu_count-1]
	return null

func show(menu_name, transitions={}, info={}, menu_data=false):
	return thaw(menu_name, transitions, info, menu_data)

func thaw(menu_name, transitions={}, info={}, menu_data=false):
	#debug.print('menus.show ', menu_name)
	# smooth arguments
	if info is bool: info = {}
	if transitions is bool: transitions = {}
	if transitions is String:
		var transitions_str = transitions
		transitions = {}
		transitions['in'] = transitions_str
		transitions['out'] = transitions_str
		transitions['middle'] = transitions_str
	# find or create menu
	var menu = null
	if has_in_memory(menu_name):
		menu = retrieve_menu(menu_name)
		if util.is_not(menu):
			debug.print("ERROR: menu.thaw() can't find menu: ", menu_name)
			return false
	else:
		menu = find_menu_file(menu_name)
		if util.is_not(menu):
			debug.print("ERROR: menu.thaw() can't find menu: ", menu_name)
			return false
	root.switch_to_menu(menu, menu_name, menu_data, info, transitions)
	return menu

func fresh(scene_name, transitions={}, info={}, scene_data=false):
	if info == '': 
		info = 'remove_at'
	return thaw(scene_name, transitions, info, scene_data)

func hard(menu_name, menu_data=false):
	var transitions = {}
	transitions['out'] = 'none'
	transitions['middle'] = 'none'
	transitions['in'] = 'none'
	return thaw(menu_name, transitions, {}, menu_data)

# restore top menu
func reveal():
	var next_menu = current_menu()
	if next_menu:
		root.switch_to_menu(next_menu, next_menu.name)
		return true
	return false

func remove_at(menu_name):
	if has_in_memory(menu_name):
		var menu = retrieve_menu(menu_name)
		if menu_name:
			menu.queue_free()
			root.menus_root.remove_child(menu)

func back():
	if settings.has_method('back'):
		settings.back()
		return
	if root.current_scene_type == 'menu':
		var _current_menu = current_menu()
		if _current_menu and _current_menu.name != settings.main_menu_name:
			menus.show(settings.main_menu_name)
	else:
		menus.show(settings.main_menu_name)

### MAINTENANCE FUNCTIONS - Not recommended to call these in your game

func create_menu(menu_name):
	var menu_file_name = find_menu_file(menu_name)
	if menu_file_name:
		var tscn = load(menu_file_name)
		var menu = tscn.instantiate()
		menu.set_name(menu_name)
		return menu

func find_menu_file(menu_name):
	# search in directories
	for dir in search_dirs:
		var file_name_tscn = 'res://' + dir + '/' + menu_name + ".tscn"
		if util.file_exists(file_name_tscn):
			return file_name_tscn
		var file_name = 'res://' + dir + '/' + menu_name
		if util.file_exists(file_name):
			return file_name
	# search from root directory if allowed
	if settings.allow_res_menus:
		if util.file_exists(menu_name):
			return menu_name
		if util.file_exists(menu_name+".tscn"):
			return menu_name+".tscn"
	return false

func delete_on_hide(menu_name):
	if has_in_memory(menu_name):
		return false
	return true

func restore_on_show(menu_name):
	if has_in_memory(menu_name):
		return true
	return false

func load_menu_file(menu_file):
	if util.file_exists(menu_file):
		return load(menu_file)
	else:
		debug.print('ERROR: Missing menu file: ', menu_file)

# find menu from stack and remove_at any menus above it
func retrieve_menu(menu_name):
	var found = false
	var found_menu = null
	var to_remove = []
	for menu in root.menus_root.get_children():
		if found:
			to_remove.append(menu)
		if menu.name == menu_name:
			found = true
			found_menu = menu
	#root.clear_menus_above(found_menu)
	#for menu in to_remove:
	#	menu.queue_free()
	#	root.menus_root.remove_child(menu)
	return found_menu

func has_in_memory(menu_name):
	for menu in root.menus_root.get_children():
		if menu.name == menu_name:
			return true
	return false

func menu_or_scene(menu):
	if find_menu_file(menu):
		return 'menu'
	return 'scene'

func is_menu(_menu_or_scene):
	if find_menu_file(_menu_or_scene):
		return true
	return false
