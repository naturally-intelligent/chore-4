# FEATURE CAMERA 2D
extends Camera2D
class_name FeatureCamera2D

# target
@export var target_node: NodePath = NodePath("")
var target_ref: WeakRef
var target: Node2D : set = set_target

# targeting behavior
@export var target_ahead := true
@export var target_ahead_pixels := 90
@export var target_behind_pixels := 0
@export var target_ahead_factor := 2
@export var target_behind_factor := 1
@export var target_ahead_y := false
@export var target_moved := false
# catch up to high speed target? warning: causes jitter
@export var target_velocity_account := false
@export var target_velocity_threshold := 200
var target_point := Vector2.ZERO
var last_camera_direction := Vector2.ZERO
var target_anchor_position := Vector2.ZERO
var target_anchored := false
var enable_triggers := true

# pixel rounding
@export var pixel_rounding := true

# shake
var shaking := false

# earthquake
@onready var noise := FastNoiseLite.new()
@export var max_shake_offset := Vector2(10, 5)  # Maximum hor/ver shake in pixels.
@export var allow_shake_y := false
@export var quake_decay := 0.8  # How quickly the shaking stops [0, 1].
@export var quake_power := 2  # quake exponent. Use [2, 3].
var quake := 0.0  # Current shake strength.
# shake due to shooting
@export var shoot_shake_decay := 2.0
@export var shoot_shake_power := 2
@export var limit_shake_zoom := true
var shoot_shake := 0.0
var max_shake_roll := 0.1  # Maximum rotation in radians (use sparingly).
var noise_vector := Vector2.ZERO
var shake_vector := Vector2.ZERO

# camera trigger areas - parent container of CameraTrigger objects
@export var camera_trigger_areas: NodePath = NodePath("")
var trigger_areas: Node = null
var last_trigger_area := ''
var trigger_tween: Tween

# maintenance
var float_camera_position: Vector2 = global_position
var initial_camera_left_limit := 0
var initial_camera_right_limit := 0

# free roam
var free_roam_mode := false
var free_roam_data := {}

# coop
@export var coop_camera_limits := true

const TARGET_CATCHUP_LERP_SPEED = 2.0
const TARGET_IGNORE_PIXELS = 24
const NOISE_FACTOR = 1

func _ready():
	# random noise
	noise.seed = 5
	noise.frequency = 0.88
	noise.fractal_octaves = 2
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	# timers
	$DramaticTimer.connect("timeout",Callable(self,"after_drama"))
	# limits
	init_limits()
	# setup triggers
	setup_camera_triggers()
	# target
	if target_node:
		target = get_node(target_node)

# PROCESS
func _process(delta: float):
	# target valid?
	if not target_ref or not target_ref.get_ref():
		target_ref = null
		target = null
	# target follow
	if target:
		if target_ahead:
			target_ahead_camera(delta)
		else:
			float_camera_position = target.global_position
	# shake
	if shaking:
		_shake_camera(delta)
	# final
	if pixel_rounding:
		global_position = round(float_camera_position)
	else:
		global_position = float_camera_position

# TARGET
func set_target(_target: Node2D):
	if target != _target:
		target_ref = weakref(_target)
		target = _target

func target_ahead_camera(delta: float):
	# find direction based on target
	var current_direction: Vector2
	current_direction.x = sign(target.direction.x)
	current_direction.y = sign(target.direction.y)
	if current_direction.x == 0:
		current_direction.x = last_camera_direction.x
	if current_direction.y == 0:
		current_direction.y = last_camera_direction.y
	# switch direction?
	var direction_changed := false
	if current_direction.x != last_camera_direction.x \
	or (target_ahead_y and current_direction.y != last_camera_direction.y):
		if last_camera_direction.x != 0:
			direction_changed = true
	# remember direction
	last_camera_direction = current_direction
	if direction_changed:
		target_anchored = true
		target_anchor_position = target.global_position
		$TargetIgnoreTimer.start()
		return
	# anchored?
	if target_anchored:
		var anchor_distance_x: float = absf(target.global_position.x - target_anchor_position.x)
		if anchor_distance_x <= TARGET_IGNORE_PIXELS / zoom.x:
			var camera_distance_y: float = absf(target.global_position.y - float_camera_position.y)
			if camera_distance_y < 5:
				return
		target_anchored = false
	# move target point?
	if $TargetIgnoreTimer.is_stopped():
		if current_direction.x > 0:
			#target_point.x = target_ahead_pixels
			target_point.x += target_ahead_factor
			if target_point.x > target_ahead_pixels / zoom.x:
				target_point.x = target_ahead_pixels / zoom.x
		elif current_direction.x < 0:
			#target_point.x = -target_behind_pixels
			target_point.x -= target_behind_factor
			if target_point.x < -target_behind_pixels / zoom.x:
				target_point.x = -target_behind_pixels / zoom.x
	# move towards goal
	var camera_speed := TARGET_CATCHUP_LERP_SPEED * delta
	# account for fast-moving target?
	if target_velocity_account:
		if target.has_method("get_real_velocity"):
			var real_velocity: Vector2 = target.get_real_velocity()
			if real_velocity.length() > target_velocity_threshold:
				camera_speed = lerp(camera_speed, 1.0, 0.1)
	# clamp final speed
	camera_speed = clamp(camera_speed, 0.1, 1.0)
	# final move camera
	float_camera_position = lerp(float_camera_position, target.global_position + target_point, camera_speed)

func force_position(_position: Vector2):
	_position = round(_position)
	global_position = _position
	target_point = Vector2.ZERO
	target_anchor_position = _position
	float_camera_position = _position

# TRIGGER
func setup_camera_triggers():
	if camera_trigger_areas:
		trigger_areas = get_node(camera_trigger_areas)
		# connect triggers
		for camera_trigger: CameraTrigger in trigger_areas.get_children():
			camera_trigger.connect("triggered", Callable(self, "on_camera_trigger").bind(camera_trigger))
		trigger_areas.visible = false

func on_camera_trigger(camera_trigger: CameraTrigger, ensure := false):
	if camera_trigger.name != last_trigger_area or ensure:
		if enable_triggers:
			enter_trigger_area(camera_trigger)

func check_all_triggers(force := true, ensure := false):
	if camera_trigger_areas:
		trigger_areas = get_node(camera_trigger_areas)
		# connect triggers
		for trigger: CameraTrigger in trigger_areas.get_children():
			var camera_trigger: CameraTrigger = trigger
			if camera_trigger.has_overlapping_bodies():
				if force:
					force_trigger_area(camera_trigger)
				else:
					on_camera_trigger(camera_trigger, ensure)

func enter_trigger_area(trigger_area: CameraTrigger):
	if trigger_area.new_y_limits or trigger_area.new_x_limits:
		if trigger_tween:
			trigger_tween.kill()
		trigger_tween = create_tween()
		var trans_type := trigger_area.tween_trans
		var ease_type := trigger_area.tween_ease
		trigger_tween.set_trans(trans_type)
		trigger_tween.set_ease(ease_type)
		trigger_tween.set_parallel()
	# y limits
	if trigger_area.new_y_limits:
		# tween
		var time: float = trigger_area.time
		# set these limits to what is current, so that animation to new limits is smoother
		limit_top = camera_edge_top_y()
		limit_bottom = camera_edge_bottom_y()
		if trigger_area.add_top_distance_time:
			time += abs(trigger_area.limit_y_top - limit_top) / 400
		trigger_tween.tween_property(self, "limit_top", trigger_area.limit_y_top, time)
		trigger_tween.tween_property(self, "limit_bottom", trigger_area.limit_y_bottom, time)
	# x limits
	if trigger_area.new_x_limits:
		if trigger_area.tween_x_limits:
			initial_camera_left_limit = trigger_area.limit_x_left
			initial_camera_right_limit = trigger_area.limit_x_right
			limit_left = camera_edge_left_x()
			limit_right = camera_edge_right_x()
			var time: float = abs(initial_camera_left_limit - trigger_area.limit_x_left) + abs(initial_camera_right_limit - trigger_area.limit_x_right)
			time *= 0.01
			if time < 1.0: time = 1.0
			trigger_tween.tween_property(self, "limit_left", trigger_area.limit_x_left, time)
			trigger_tween.tween_property(self, "limit_right", trigger_area.limit_x_right, time)
			if position_smoothing_speed > 1:
				set_smoothing_speed_temporarily()
		else:
			#initial_camera_left_limit = trigger_area.limit_x_left
			#initial_camera_right_limit = trigger_area.limit_x_right
			limit_left = trigger_area.limit_x_left
			limit_right = trigger_area.limit_x_right
	# target distance pixels
	if trigger_area.new_target_ahead:
		target_ahead_pixels = trigger_area.target_ahead_pixels
		target_behind_pixels = trigger_area.target_behind_pixels
	# lighting
	if trigger_area.new_darkness:
		trigger_area.on_new_lighting()
	# lighting
	if trigger_area.new_rounding:
		pixel_rounding = trigger_area.pixel_rounding

	last_trigger_area = trigger_area.name
	call_deferred("check_empty_triggers")

func force_trigger_area(trigger_area: CameraTrigger):
	if trigger_tween:
		trigger_tween.kill()
	# y limits
	if trigger_area.new_y_limits:
		# set these limits to what is current, so that animation to new limits is smoother
		limit_top = trigger_area.limit_y_top
		limit_bottom = trigger_area.limit_y_bottom
	# x limits
	if trigger_area.new_x_limits:
		initial_camera_left_limit = trigger_area.limit_x_left
		initial_camera_right_limit = trigger_area.limit_x_right
		limit_left = trigger_area.limit_x_left
		limit_right = trigger_area.limit_x_right
	# target distance pixels
	if trigger_area.new_target_ahead:
		target_ahead_pixels = trigger_area.target_ahead_pixels
		target_behind_pixels = trigger_area.target_behind_pixels
	# lighting
	if trigger_area.new_darkness:
		trigger_area.on_new_lighting()
	# lighting
	if trigger_area.new_rounding:
		pixel_rounding = trigger_area.pixel_rounding
	last_trigger_area = trigger_area.name
	
func tween_change_camera_limits_x(new_limit_left: int, new_limit_right: int, time:=1.5):
	if trigger_tween:
		trigger_tween.kill()
	trigger_tween = create_tween()
	var trans_type := Tween.TRANS_CUBIC
	var ease_type := Tween.EASE_OUT
	limit_left = camera_edge_left_x()
	limit_right = camera_edge_right_x()
	trigger_tween.set_trans(trans_type)
	trigger_tween.set_ease(ease_type)
	trigger_tween.set_parallel()
	trigger_tween.tween_property(self, "limit_left", new_limit_left, time)
	trigger_tween.tween_property(self, "limit_right", new_limit_right, time)

func tween_change_camera_limits(new_limit_left: int, new_limit_right: int, new_limit_top: int, new_limit_bottom: int, time:=1.5):
	if trigger_tween:
		trigger_tween.kill()
	trigger_tween = create_tween()
	var trans_type := Tween.TRANS_CUBIC
	var ease_type := Tween.EASE_OUT
	limit_left = camera_edge_left_x()
	limit_right = camera_edge_right_x()
	limit_bottom = camera_edge_bottom_y()
	limit_top = camera_edge_top_y()
	trigger_tween.set_trans(trans_type)
	trigger_tween.set_ease(ease_type)
	trigger_tween.set_parallel()
	trigger_tween.tween_property(self, "limit_left", new_limit_left, time)
	trigger_tween.tween_property(self, "limit_right", new_limit_right, time)
	trigger_tween.tween_property(self, "limit_top", new_limit_top, time)
	trigger_tween.tween_property(self, "limit_bottom", new_limit_bottom, time)

func is_in_trigger_area() -> bool:
	if camera_trigger_areas:
		trigger_areas = get_node(camera_trigger_areas)
		# connect triggers
		for trigger: CameraTrigger in trigger_areas.get_children():
			if trigger.has_overlapping_bodies():
				return true
	return false

# SHAKE / QUAKE
func start_shaking():
	if settings.camera_shake:
		shaking = true

func stop_shaking():
	shaking = false
	shake_vector = Vector2.ZERO
	offset = Vector2.ZERO

func _shake_camera(delta: float):
	# quake
	var continue_shaking := false
	if quake:
		if quake > 0:
			quake = max(quake - quake_decay * delta, 0)
			_do_shake(quake, quake_power)
			if quake > 0:
				continue_shaking = true
	# shoot shake
	if shoot_shake > 0:
		shoot_shake = max(shoot_shake - shoot_shake_decay * delta, 0)
		_do_shake(shoot_shake, shoot_shake_power)
		if shoot_shake > 0:
			continue_shaking = true
	if not continue_shaking:
		stop_shaking()

func _do_shake(_shake: float, _shake_power: float):
	# get the noise
	var shake_offset := Vector2.ZERO
	var shake_amount := pow(_shake, _shake_power)
	noise_vector.x += 1
	noise_vector.y += 1
	shake_offset.x = max_shake_offset.x * shake_amount * noise.get_noise_2d(noise.seed*2, noise_vector.x) * NOISE_FACTOR
	if allow_shake_y:
		shake_offset.y = max_shake_offset.y * shake_amount * noise.get_noise_2d(noise.seed*3, noise_vector.y) * NOISE_FACTOR
	# apply offset
	shake_vector = shake_offset
	# clamp to max shake
	shake_vector.x = clamp(shake_vector.x, -max_shake_offset.x, max_shake_offset.x)
	shake_vector.y = clamp(shake_vector.y, -max_shake_offset.y, max_shake_offset.y)
	#if not shake_y: shake_vector.y = 0
	shake_vector.x = int(shake_vector.x)
	shake_vector.y = int(shake_vector.y)
	offset = shake_vector
	if zoom != Vector2.ONE and limit_shake_zoom:
		var rect: Rect2 = get_visible_screen_rect()
		if offset.x > 0 and rect.end.x + offset.x > limit_right:
			offset.x = 0 #limit_right - rect.end.x
		elif offset.x < 0 and rect.position.x + offset.x < limit_left:
			offset.x = 0
		if offset.y > 0 and rect.end.y + offset.y > limit_bottom:
			offset.y = 0
		elif offset.y < 0 and rect.position.y + offset.y < limit_top:
			offset.y = 0
	#if offset.x > camera_edge_left_x()
	# rotation
	#rotation = shake_amount * noise.get_noise_2d(noise.seed, noise_vector.x)
	#rotation = clamp(rotation, -max_shake_roll, max_shake_roll)

func quake_shake(amount: float):
	if settings.camera_shake:
		quake = min(quake + amount, 1.0)
		start_shaking()

func shooty_shake(_direction: Vector2, _threshold:=1.0):
	if settings.camera_shake:
		if shoot_shake <= _threshold:
			shoot_shake = 1.0
		start_shaking()

# DRAMA
func zoom_drama(wait:=0.25, zoom_factor:=1.0):
	zoom_to(1.0+zoom_factor)
	$DramaticTimer.wait_time = wait
	$DramaticTimer.start()

func after_drama():
	#zoom_normal()
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "zoom", Vector2(1.0,1.0), 0.22)

# ZOOM
func zoom_normal():
	zoom.x = 1.0
	zoom.y = 1.0

func zoom_to(_target: float):
	zoom.x = _target
	zoom.y = _target

func zoom_in(amount: float):
	var min_zoom := 4.00
	zoom.x += amount
	zoom.y += amount
	if zoom.x > min_zoom:
		zoom.x = min_zoom
	if zoom.y > min_zoom:
		zoom.y = min_zoom
	if target:
		global_position = target.global_position

func zoom_out(amount: float):
	var max_zoom := 0.5
	zoom.x -= amount
	zoom.y -= amount
	if zoom.x < max_zoom:
		zoom.x = max_zoom
	if zoom.y < max_zoom:
		zoom.y = max_zoom
	if zoom.y > 1.0:
		limit_top = -10000
		limit_bottom = 10000
	if target:
		global_position = target.global_position

func is_zooming() -> bool:
	if zoom.x != 1 or zoom.y != 1:
		return true
	return false

# LIMITS
func init_limits():
	# limits?
	if has_node('LeftLimit'):
		var node := get_node('LeftLimit')
		limit_left = node.global_position.x
	if has_node('RightLimit'):
		var node := get_node('RightLimit')
		limit_right = node.global_position.x
	initial_camera_left_limit = limit_left
	initial_camera_right_limit = limit_right

func change_camera_limits(left_x: int, right_x: int, top_y=false, bottom_y=false):
	limit_left = left_x
	limit_right = right_x
	if top_y: limit_top = top_y
	if bottom_y: limit_bottom = bottom_y

func reset_camera_limits():
	if position_smoothing_speed > 1:
		set_smoothing_speed_temporarily()
	limit_left = initial_camera_left_limit
	limit_right = initial_camera_right_limit

func tween_reset_camera_limits_x():
	if position_smoothing_speed > 1:
		set_smoothing_speed_temporarily()
	tween_change_camera_limits_x(initial_camera_left_limit, initial_camera_right_limit)

func check_empty_triggers():
	if trigger_areas and trigger_areas.get_child_count() == 0:
		trigger_areas = null

func camera_edge_left_x() -> int:
	return get_screen_center_position().x - ProjectSettings.get_setting("display/window/size/viewport_width") * zoom.x / 2

func camera_edge_right_x() -> int:
	return get_screen_center_position().x + ProjectSettings.get_setting("display/window/size/viewport_width") * zoom.x / 2

func camera_edge_bottom_y() -> int:
	return get_screen_center_position().y + ProjectSettings.get_setting("display/window/size/viewport_height") * zoom.y / 2

func camera_edge_top_y() -> int:
	return get_screen_center_position().y - ProjectSettings.get_setting("display/window/size/viewport_height") * zoom.y / 2

func get_visible_screen_rect() -> Rect2:
	var rect: Rect2
	rect.size = zoom * Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"), ProjectSettings.get_setting("display/window/size/viewport_height")) * zoom
	rect.position = get_screen_center_position() - rect.size / 2
	return rect

func is_point_on_screen(point: Vector2) -> bool:
	var rect := get_visible_screen_rect()
	return rect.has_point(point)

# SMOOTHING
func set_smoothing_speed_temporarily(speed:=1.0, time:=5.0):
	var old_speed := position_smoothing_speed
	position_smoothing_speed = speed
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, 'position_smoothing_speed', old_speed, time)
	await tween.finished

# FREE ROAM MODE

func flip_free_roam_mode():
	if free_roam_mode:
		disable_free_roam()
	else:
		enable_free_roam()

func enable_free_roam():
	free_roam_mode = true
	free_roam_data['limit_left'] = limit_left
	free_roam_data['limit_right'] = limit_right
	free_roam_data['limit_top'] = limit_top
	free_roam_data['limit_bottom'] = limit_bottom
	limit_left = -1000000
	limit_right = 1000000
	limit_top = -1000000
	limit_bottom = 1000000
	set_process(false)
	root.show_console()
	root.add_debug_line("Free Roam Camera Enabled")
	root.add_debug_line("- Press Numpad to move Camera")
	root.add_debug_line("- Press C to disable")
	
func disable_free_roam():
	free_roam_mode = false
	if free_roam_data:
		limit_left = free_roam_data['limit_left']
		limit_right = free_roam_data['limit_right']
		limit_top = free_roam_data['limit_top']
		limit_bottom = free_roam_data['limit_bottom']
	set_process(true)
	root.hide_console()

func free_roam(direction: Vector2):
	const free_roam_speed = 20
	position += direction * free_roam_speed
