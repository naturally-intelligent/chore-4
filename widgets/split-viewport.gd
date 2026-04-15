class_name SplitViewport extends SubViewportContainer

func get_split_subviewport() -> SubViewport:
	return $SplitViewport

func move_scene(scene: Node):
	$SplitViewport.add_child(scene)
	scene.reparent($SplitViewport)

func find_world_2d() -> World2D:
	return $SplitViewport.find_world_2d()

func set_world_2d(other_world_2d: World2D):
	$SplitViewport.world_2d = other_world_2d

func add_node(node: Node):
	$SplitViewport.add_child(node)

func move_node(node: Node):
	$SplitViewport.add_child(node)
	node.reparent($SplitViewport)

func get_level() -> Level:
	return $SplitViewport.get_child(0)
