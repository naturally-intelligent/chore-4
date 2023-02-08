extends Node2D
class_name ParallaxPoint

@export var parallax = 1.5

@onready var origin : Vector2 = global_position

func _ready():
	pass

func _process(delta):
	var camera_pos = game.level.viewport_center
	var camera_distance = camera_pos.x - origin.x
	if abs(camera_distance) < 2000:
		visible = true
		position.x = origin.x - camera_distance * (parallax-1)
	else:
		visible = false

