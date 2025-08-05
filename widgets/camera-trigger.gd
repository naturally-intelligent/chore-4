# CAMERA TRIGGER
# - to use, add a Node2D container to your scene and link it to the Camera
# - add CameraTriggers to the Node2D container, then add CollisionShape to each one
# - make sure to set the CollisionMask flag to appropriate body physics layer (usually Player)
extends Area2D
class_name CameraTrigger

# remove_at after entry?
@export var disappears_after := false
@export var time := 1.0
@export var tween_trans := Tween.TRANS_CUBIC
@export var tween_ease := Tween.EASE_IN

# y limits
@export_group("Y Limits")
@export var new_y_limits := true
@export var limit_y_top := 0
@export var limit_y_bottom := 360
@export var add_top_distance_time := true

# x limits
@export_group("X Limits")
@export var new_x_limits := false
@export var new_left_limit := true
@export var new_right_limit := true
@export var limit_x_left := 0
@export var limit_x_right := 640
@export var tween_x_limits := true

# target ahead
@export_group("Target Ahead")
@export var new_target_ahead := false
@export var target_ahead_pixels := 0
@export var target_behind_pixels := 0

# darkness
@export_group("Darkness")
@export var new_darkness := false
@export var lighting := false
@export var darkness_y := 370
@export var darkness_depth := 800

# camera rounding
@export_group("Camera Rounding")
@export var new_rounding := false
@export var pixel_rounding := true

signal triggered()

func on_camera_target_entered(body: Node):
	emit_signal("triggered")
	if disappears_after:
		queue_free()

func on_new_lighting():
	if lighting:
		if not game.level.lighting:
			game.level.enable_lighting()
		game.level.update_lighting()
	else:
		game.level.fade_off_lighting()
