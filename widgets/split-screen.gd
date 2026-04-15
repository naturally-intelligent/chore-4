# SPLIT SCREEN
extends HBoxContainer
class_name SplitScreen

func get_left_viewport() -> SplitViewport:
	return $LeftViewport
	
func get_right_viewport() -> SplitViewport:
	return $RightViewport
