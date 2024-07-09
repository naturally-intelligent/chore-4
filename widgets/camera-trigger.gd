extends Area2D
class_name CameraTrigger

# remove_at after entry?
@export var disappears_after := false

# y limits
@export var new_y_limits := true
@export var limit_y_top := 0
@export var limit_y_bottom := 360

# x limits
@export var new_x_limits := false
@export var limit_x_left := 0
@export var limit_x_right := 640

# target ahead
@export var new_target_ahead := false
@export var target_ahead_pixels := 0
@export var target_behind_pixels := 0

# darkness
@export var new_darkness := false
@export var lighting := false
@export var darkness_y := 370
@export var darkness_depth := 800

# camera rounding
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
