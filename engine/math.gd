@tool
extends Node

### RANDOM NUMBERS

static func random_int(start: int, end: int) -> int:
	var div = end-start+1
	if div == 0: return start
	return start + randi()%div

static func randomi(s: int, e: int) -> int:  # shortened version of random_int
	var div = e-s+1
	if div == 0: return s
	return s + randi()%div

static func random_float(start: float, end: float) -> float:
	return randf()*(end-start)+start

static func randomf(s: float, e: float) -> float: # shortened version of random_float
	return randf()*(e-s)+s

static func random_position(minx:int,maxx:int, miny:int,maxy:int):
	return Vector2(random_int(minx,maxx), random_int(miny,maxy))

static func random_vector(x_factor = 1.0, y_factor = 1.0):
	return Vector2(random_float(-1.0,1.0)*x_factor, random_float(-1.0,1.0)*y_factor).normalized()

### VECTORS AND ANGLES

# rounds a vector2d
static func round_angle_to_degree(normal: Vector2, angle_in_degrees: float) -> Vector2:
	var angle = normal.angle()
	angle = snapped(angle, deg_to_rad(angle_in_degrees))
	return Vector2(cos(angle), sin(angle))

# rounds a vector2d and returns angle
static func round_angle_to_degree_with_angle(normal: Vector2, angle_in_degrees: float) -> Array:
	var angle = normal.angle()
	angle = snapped(angle, deg_to_rad(angle_in_degrees))
	return [Vector2(cos(angle), sin(angle)), rad2deg360(angle)]

static func angle_frame_45(angle: int) -> int:
	return int(clamp(angle,0,359) / 45)

static func angle_frame_90(angle: int) -> int:
	return int(clamp(angle,0,359) / 90)

static func rad2deg360(radians) -> int:
	var degrees = rad_to_deg(radians)
	if degrees < 0:
		degrees += 360
	return int(degrees)

static func normal_to_degrees(n):
	return atan2(n.y, n.x) * 180 / PI

static func normal_to_360_degrees(n):
	var theta = atan2(n.y, n.x)
	var deg = rad_to_deg(theta)
	if deg < 0: deg += 360
	return deg

static func normal_to_45(n):
	var deg = normal_to_360_degrees(n)
	return snapped(deg, 45)

static func normal_to_90(n):
	var deg = normal_to_360_degrees(n)
	if deg >= 360: deg -= 360
	return snapped(deg, 90)

### POSITIONS

static func nearest_position(parent, position):
	var nearest = 1000*1000
	var nearest_pos = false
	for node in parent.get_children():
		var dist2 = position.distance_squared_to(node.position)
		if dist2 < nearest:
			nearest_pos = node.position
			nearest = dist2
	return nearest_pos

static func nearest_global_position(parent, position):
	var nearest = 1000*1000
	var nearest_pos = false
	for node in parent.get_children():
		var dist2 = position.distance_squared_to(node.global_position)
		if dist2 < nearest:
			nearest_pos = node.global_position
			nearest = dist2
	return nearest_pos

### CURVES

static func quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float):
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	return [q0, q1]

static func cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float):
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	var q2 = p2.lerp(p3, t)

	var r0 = q0.lerp(q1, t)
	var r1 = q1.lerp(q2, t)

	var s = r0.lerp(r1, t)
	return s

### VALUES

static func move_towards(target, current, amount):
	if target > current:
		if current + amount >= target:
			return target
		return current + amount
	elif target < current:
		if current - amount <= target:
			return target
		return current - amount
	return current
