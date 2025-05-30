extends Node

# CHORE ENGINE
# Designed and developed by David Glen Kerr
#
# autoload 'scenes' and call the user functions
#
# use show() expected for a scene system
# use level() for easier way to launch persistent levels

# tracking variables
var search_dirs := []

func _ready() -> void:
	search_dirs = settings.scene_dirs
	if not settings.custom_scene_dirs_only:
		search_dirs.append_array(['scenes','scene'])

### USER FUNCTIONS - call these to use scene system

func current_scene() -> Node:
	var scene_count: int = root.scenes_root.get_child_count()
	if scene_count > 0:
		return root.scenes_root.get_children()[scene_count-1]
	return null

func has_scene() -> bool:
	var scene_count: int = root.scenes_root.get_child_count()
	if scene_count > 0:
		return true
	return false

func show(scene_name: String, transitions={}, info={}, scene_data=false) -> Variant:
	return thaw(scene_name, transitions, info, scene_data)

func thaw(scene_name: String, transitions={}, info={}, scene_data=false) -> Variant:
	#debug.print('scenes.show ', scene_name)
	# smooth arguments
	if info is bool: info = {}
	if transitions is bool: transitions = {}
	if transitions is String:
		var transitions_str = transitions
		transitions = {}
		transitions['in'] = transitions_str
		transitions['out'] = transitions_str
		transitions['middle'] = transitions_str
	# find or create scene
	var scene = null
	var force_refresh = false
	if info:
		if info == 'clear':
			force_refresh = true
		if info == 'remove_at':
			force_refresh = true
	if has_in_memory(scene_name) and not force_refresh:
		scene = retrieve_scene(scene_name)
	else:
		scene = find_scene_file(scene_name)
	var infos := {}
	if info:
		infos[info] = true
	if util.is_not(scene):
		debug.print("ERROR: scene.thaw() can't find scene: ", scene_name)
		return null
	root.switch_to_scene(scene, scene_name, scene_data, infos, transitions)
	return scene

func fresh(scene_name: String, transitions=false, info=false, scene_data=false) -> Variant:
	if info is bool and info == false:
		info = 'remove_at'
	if info == null:
		info = 'remove_at'
	return thaw(scene_name, transitions, info, scene_data)

func hard(scene_name: String, scene_data=false) -> Variant:
	var transitions := {}
	transitions['out'] = 'none'
	transitions['middle'] = 'none'
	transitions['in'] = 'none'
	return thaw(scene_name, transitions, {}, scene_data)

func reload_current_scene() -> void:
	fresh(root.current_scene_name)

# restore top scene
func reveal() -> bool:
	var next_scene = current_scene()
	if next_scene:
		root.switch_to_scene(next_scene, next_scene.name)
		return true
	return false

func remove_at(scene_name) -> void:
	if has_in_memory(scene_name):
		var scene := retrieve_scene(scene_name)
		if scene_name:
			scene.queue_free()
			root.scenes_root.remove_child(scene)

func back() -> void:
	if settings.has_method('back'):
		settings.back()
		return
	if root.current_scene_type == &'scene':
		var _current_scene = current_scene()
		if _current_scene and _current_scene.name != settings.main_scene_name:
			scenes.show(settings.main_scene_name)
	else:
		scenes.show(settings.main_scene_name)

func clear() -> void:
	root.clear_scenes()

### MAINTENANCE FUNCTIONS - Not recommended to call these in your game

func create_scene(scene_name: String) -> Node:
	var scene_file_name := find_scene_file(scene_name)
	if scene_file_name:
		var tscn := load(scene_file_name)
		var scene: Node = tscn.instantiate()
		scene.set_name(scene_name)
		return scene
	else:
		debug.print("FATAL: create_scene(): MISSING SCENE FILE:",scene_file_name)
		return null

func find_scene_file(scene_name: String) -> String:
	# search in directories
	for dir: String in search_dirs:
		var file_name_tscn := 'res://' + dir + '/' + scene_name + ".tscn"
		if util.file_exists(file_name_tscn):
			return file_name_tscn
		var file_name := 'res://' + dir + '/' + scene_name
		if util.file_exists(file_name):
			return file_name
	# search from root directory if allowed
	if settings.allow_res_scenes:
		if util.file_exists(scene_name):
			return scene_name
		if util.file_exists(scene_name+".tscn"):
			return scene_name+".tscn"
	return ''

func delete_on_hide(scene_name: String) -> bool:
	if has_in_memory(scene_name):
		return false
	return true

func restore_on_show(scene_name: String) -> bool:
	if has_in_memory(scene_name):
		return true
	return false

func load_scene_file(scene_file: String) -> Resource:
	if util.file_exists(scene_file):
		return load(scene_file)
	else:
		debug.print('ERROR: Missing scene file: ', scene_file)
		return null

# find scene from stack and remove_at any scenes above it
func retrieve_scene(scene_name: String) -> Node:
	var found_scene: Node = null
	for scene in root.scenes_root.get_children():
		if scene.name == scene_name:
			found_scene = scene
	return found_scene

func has_in_memory(scene_name: String) -> bool:
	for scene in root.scenes_root.get_children():
		if scene.name == scene_name:
			return true
	return false

func scene_or_menu(scene: String) -> String:
	if find_scene_file(scene):
		return &'scene'
	return &'menu'
