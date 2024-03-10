extends Control

var info_refs := []
var info_index := -1

func _ready() -> void:
	set_process(false)

func _process(_delta):
	update_info_nodes()

func add_info_node(node: Node):
	if node.has_method('enable_debug_overlay'):
		if node.has_method('update_debug_text'):
			if not has_info_node(node):
				var info_ref = weakref(node)
				info_refs.append(info_ref)
				set_process(true)
				node.enable_debug_overlay()
			else:
				remove_info_node(node)

func has_info_node(node: Node):
	for info_ref in info_refs:
		if info_ref:
			var check = info_ref.get_ref()
			if check and check == node:
				return true
	return false

func remove_info_node(node: Node):
	for info_ref in info_refs:
		if info_ref:
			var check = info_ref.get_ref()
			if check and check == node:
				info_refs.erase(info_ref)
				if node.has_method("disable_debug_overlay"):
					node.disable_debug_overlay()
	if info_refs.is_empty():
		set_process(false)

func update_info_nodes():
	for info_ref in info_refs:
		if info_ref:
			var node = info_ref.get_ref()
			if node:
				if node.has_method('update_debug_text'):
					node.update_debug_text()
			else:
				info_refs.erase(info_ref)
		else:
			info_refs.erase(info_ref)
	if info_refs.is_empty():
		set_process(false)

func set_info_text(text: String):
	$Info.set_text(text)

func next_debug_info(container: Node):
	var current = container.get_child(info_index)
	if current:
		remove_info_node(current)
	info_index += 1
	if info_index >= container.get_child_count():
		info_index = 0
	var child = container.get_child(info_index)
	add_info_node(child)

func prev_debug_info(container: Node):
	var current = container.get_child(info_index)
	if current:
		remove_info_node(current)
	info_index -= 1
	if info_index < 0:
		info_index = container.get_child_count()-1
	var child = container.get_child(info_index)
	add_info_node(child)
