extends TouchScreenButton

@export var diagonal := true

var outer_boundary := 128
var inner_boundary := 8
var touch_idx := -1
var direction := Vector2.RIGHT
var active := false
var instant_direction := false
var instant_threshold := 1
var last_position := Vector2.ZERO

var up := false
var down := false
var left := false
var right := false

var last_degrees := -1
var wiggle := 23

# sprite sprite_frames
const eight_directions = {
	'up-left': 0,
	'up': 1,
	'up-right': 2,
	'right': 3,
	'none': 4,
	'left': 5,
	'down-left': 6,
	'down': 7,
	'down-right': 8,
}
const four_directions = {
	'none': 0,
	'up': 1,
	'right': 2,
	'down': 3,
	'left': 4,
}
var sprite_frames: Dictionary

func _ready():
	if diagonal:
		sprite_frames = eight_directions
	else:
		sprite_frames = four_directions

func _process(_delta: float):
	if active:
		press_events()

func _input(event: InputEvent):
	if event is InputEventScreenTouch \
	and event.get_index() == touch_idx \
	and !event.is_pressed():
		active = false
		touch_idx = -1
		reset_dpad()
		release_events()
		return

	if event is InputEventScreenDrag \
	or (event is InputEventScreenTouch and event.is_pressed()):
		var valid_touch := false
		var new_touch := false

		if touch_idx == -1:
			touch_idx = event.get_index()
			new_touch = true
			valid_touch = true
		elif touch_idx == event.get_index():
			valid_touch = true

		if valid_touch:
			var new_position: Vector2 = event.position
			var vector: Vector2 = new_position - $Sprite2D.global_position
			var distance := vector.length()
			var dpad_normal := vector.normalized()
			if new_touch:
				last_position = event.position
			if new_touch and distance > outer_boundary:
				valid_touch = false
				touch_idx = -1
				return
			if not new_touch and instant_direction:
				var instant_vector := new_position - last_position
				var instant_distance := instant_vector.length()
				if instant_distance > instant_threshold:
					direction = instant_vector.normalized()
					active = true
					update_dpad(direction)
			elif distance > inner_boundary and distance <= outer_boundary:
				active = true
				direction = dpad_normal
				update_dpad(direction)
			else:
				active = false
				release_events()
				reset_dpad()
			last_position = new_position

func reset_dpad():
	$Sprite2D.frame = sprite_frames['none']
	last_degrees = -1

func update_dpad(vector: Vector2):
	var deg360 := math.normal_to_360_degrees(vector)
	var degrees := int(math.normal_to_45(vector))
	if not diagonal:
		#degrees = math.normal_to_90(vector)
		# right diagonals into right
		if degrees == 45 or degrees == 315:
			degrees = 0
		# left diagonals into left
		if degrees == 135 or degrees == 225:
			degrees = 180
	if degrees >= 360: degrees -= 360
	if last_degrees == degrees:
		return
	if degrees == 0 or (deg360 <= 0+wiggle and deg360 >= 0-wiggle):
		$Sprite2D.frame = sprite_frames['right']
		right = true
		release_left()
		release_up()
		release_down()
	elif degrees == 180 or (deg360 <= 180+wiggle and deg360 >= 180-wiggle):
		$Sprite2D.frame = sprite_frames['left']
		left = true
		release_down()
		release_right()
		release_up()
	elif degrees == 90 or (deg360 <= 90+wiggle and deg360 >= 90-wiggle):
		$Sprite2D.frame = sprite_frames['down']
		down = true
		release_right()
		release_left()
		release_up()
	elif degrees == 45:
		$Sprite2D.frame = sprite_frames['down-right']
		right = true
		down = true
		release_left()
		release_up()
	elif degrees == 135:
		$Sprite2D.frame = sprite_frames['down-left']
		down = true
		left = true
		release_right()
		release_up()
	elif degrees == 225:
		$Sprite2D.frame = sprite_frames['up-left']
		left = true
		up = true
		release_right()
		release_down()
	elif degrees == 270:
		$Sprite2D.frame = sprite_frames['up']
		up = true
		release_left()
		release_right()
		release_down()
	elif degrees == 315:
		$Sprite2D.frame = sprite_frames['up-right']
		up = true
		right = true
		release_left()
		release_down()
	last_degrees = degrees

func press_events():
	if up: Input.action_press("ui_up")
	if left: Input.action_press("ui_left")
	if right: Input.action_press("ui_right")
	if down: Input.action_press("ui_down")

func release_left():
	if left:
		Input.action_release("ui_left")
		left = false

func release_right():
	if right:
		Input.action_release("ui_right")
		right = false

func release_up():
	if up:
		Input.action_release("ui_up")
		up = false

func release_down():
	if down:
		Input.action_release("ui_down")
		down = false

func release_events():
	release_left()
	release_right()
	release_up()
	release_down()
