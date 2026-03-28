extends Node2D
# Handle the motion of both player cameras as well as communication with the
# SplitScreen shader to achieve the dynamic split screen effet
#
# Cameras are place on the segment joining the two players, either in the middle
# if players are close enough or at a fixed distance if they are not.
# In the first case, both cameras being at the same location, only the view of
# the first one is used for the entire screen thus allowing the players to play
# on a unsplit screen.
# In the second case, the screen is split in two with a line perpendicular to the
# segement joining the two players.
#
# The points of customization are:
#   max_separation: the distance between players at which the view starts to split
#   split_line_thickness: the thickness of the split line in pixels
#   split_line_color: color of the split line
#   adaptive_split_line_thickness: if true, the split line thickness will vary
#       depending on the distance between players. If false, the thickness will
#       be constant and equal to split_line_thickness

@export var max_separation := 16.0
@export var split_line_thickness := 8.0
@export var split_line_color := Color.BLACK
@export var adaptive_split_line_thickness := true

@onready var player1: Node2D
@onready var player2: Node2D
@onready var view: TextureRect = $ViewTexture
@onready var viewport1: SubViewport = $Viewport1
@onready var viewport2: SubViewport = $Viewport2
@onready var camera1: Camera2D = $Viewport1/Camera2D
@onready var camera2: Camera2D = $Viewport2/Camera2D

var viewport_base_height := int(ProjectSettings.get_setting("display/window/size/viewport_height"))

func setup() -> void:
	_on_size_changed()
	_update_splitscreen()

	get_viewport().size_changed.connect(_on_size_changed)

	view.material.set_shader_parameter("viewport1", viewport1.get_texture())
	view.material.set_shader_parameter("viewport2", viewport2.get_texture())


func _process(_delta: float) -> void:
	_move_cameras()
	_update_splitscreen()


func _move_cameras() -> void:
	var position_difference := _get_position_difference_in_world()

	var distance := clampf(_get_horizontal_length(position_difference), 0, max_separation)

	position_difference = position_difference.normalized() * distance

	camera1.position.x = player1.position.x + position_difference.x / 2.0
	camera1.position.y = player1.position.y + position_difference.y / 2.0

	camera2.position.x = player2.position.x - position_difference.x / 2.0
	camera2.position.y = player2.position.y - position_difference.y / 2.0


func _update_splitscreen() -> void:
	var screen_size := get_viewport().get_visible_rect().size
	var player1_position := camera1.global_position / screen_size
	var player2_position := camera2.global_position / screen_size

	var thickness := 0.0
	if adaptive_split_line_thickness:
		var position_difference := _get_position_difference_in_world()
		var distance := _get_horizontal_length(position_difference)
		thickness = lerpf(0, split_line_thickness, (distance - max_separation) / max_separation)
		thickness = clampf(thickness, 0, split_line_thickness)
	else:
		thickness = split_line_thickness

	view.material.set_shader_parameter("split_active", _is_split_state())
	view.material.set_shader_parameter("player1_position", player1_position)
	view.material.set_shader_parameter("player2_position", player2_position)
	view.material.set_shader_parameter("split_line_thickness", thickness)
	view.material.set_shader_parameter("split_line_color", split_line_color)


## Returns `true` if split screen is active (which occurs when players are
## too far apart from each other), `false` otherwise.
## Only the horizontal components (x, z) are used for distance computation.
func _is_split_state() -> bool:
	var position_difference := _get_position_difference_in_world()
	var separation_distance := _get_horizontal_length(position_difference)
	return separation_distance > max_separation


func _on_size_changed() -> void:
	var screen_size := get_viewport().get_visible_rect().size

	$Viewport1.size = screen_size
	$Viewport2.size = screen_size

	view.material.set_shader_parameter("viewport_size", screen_size)


func _get_position_difference_in_world() -> Vector2:
	return player2.position - player1.position


func _get_horizontal_length(vec: Vector2) -> float:
	return Vector2(vec.x, vec.y).length()

func get_viewport1() -> Viewport:
	return viewport1
	
func get_viewport2() -> Viewport:
	return viewport2
	
func get_camera2() -> Camera2D:
	return $Viewport2/Camera2D
	
func match_worlds():
	viewport2.world_2d = viewport1.find_world_2d()
