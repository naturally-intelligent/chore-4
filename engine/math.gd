@tool
extends Node

### RANDOM NUMBERS

func random_int(start: int, end: int) -> int:
	return randi_range(start, end)
	#var div = end-start+1
	#if div == 0: return start
	#return start + randi()%div

func randomi(s: int, e: int) -> int:  # shortened version of random_int
	return randi_range(s, e)

func random_float(start: float, end: float) -> float:
	return randf_range(start, end)
	#return randf()*(end-start)+start

# random float with 'stepify' behavior
func random_float_step(start: float, end: float, step: float) -> float:
	var steps = int((end - start) / step)
	return start + float(randi()%(steps+1)) * step

func randomf(s: float, e: float) -> float: # shortened version of random_float
	return randf_range(s, e)

func random_position(minx:int,maxx:int, miny:int,maxy:int):
	return Vector2(random_int(minx,maxx), random_int(miny,maxy))

func random_vector_position(vector1: Vector2i, vector2: Vector2i):
	return Vector2i(random_int(vector1.x,vector2.x), random_int(vector1.y,vector2.y))

func random_vector(x_factor = 1.0, y_factor = 1.0):
	return Vector2(random_float(-1.0,1.0)*x_factor, random_float(-1.0,1.0)*y_factor).normalized()

func random_vector_offset(x_factor := 1, y_factor := 1):
	return Vector2(random_int(-x_factor,x_factor), random_int(-y_factor,y_factor))

### VECTORS AND ANGLES

# rounds a vector2d
func round_angle_to_degree(normal: Vector2, angle_in_degrees: float) -> Vector2:
	var angle = normal.angle()
	angle = snapped(angle, deg_to_rad(angle_in_degrees))
	return Vector2(cos(angle), sin(angle))

# rounds a vector2d and returns angle
func round_angle_to_degree_with_angle(normal: Vector2, angle_in_degrees: float) -> Array:
	var angle = normal.angle()
	angle = snapped(angle, deg_to_rad(angle_in_degrees))
	return [Vector2(cos(angle), sin(angle)), rad2deg360(angle)]

func angle_frame_45(angle: int) -> int:
	return int(clamp(angle,0,359) / 45)

func angle_frame_90(angle: int) -> int:
	return int(clamp(angle,0,359) / 90)

func rad2deg360(radians) -> int:
	var degrees = rad_to_deg(radians)
	if degrees < 0:
		degrees += 360
	return int(degrees)

func normal_to_degrees(n):
	return atan2(n.y, n.x) * 180 / PI

func normal_to_360_degrees(n):
	var theta = atan2(n.y, n.x)
	var deg = rad_to_deg(theta)
	if deg < 0: deg += 360
	return deg

func normal_to_45(n):
	var deg = normal_to_360_degrees(n)
	return snapped(deg, 45)

func normal_to_90(n):
	var deg = normal_to_360_degrees(n)
	if deg >= 360: deg -= 360
	return snapped(deg, 90)

func radians_to_vector(radians):
	return Vector2(cos(radians), sin(radians))

func cap_vector(v, max):
	if v.x > max: v.x = max
	if v.y > max: v.y = max
	if v.x < -max: v.x = -max
	if v.y < -max: v.y = -max
	return v

### POSITIONS

func nearest_position(parent, position):
	var nearest = 1000*1000
	var nearest_pos = false
	for node in parent.get_children():
		var dist2 = position.distance_squared_to(node.position)
		if dist2 < nearest:
			nearest_pos = node.position
			nearest = dist2
	return nearest_pos

func nearest_global_position(parent, position):
	var nearest = 1000*1000
	var nearest_pos = false
	for node in parent.get_children():
		var dist2 = position.distance_squared_to(node.global_position)
		if dist2 < nearest:
			nearest_pos = node.global_position
			nearest = dist2
	return nearest_pos

### CURVES

func quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float):
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	return [q0, q1]

func cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float):
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	var q2 = p2.lerp(p3, t)

	var r0 = q0.lerp(q1, t)
	var r1 = q1.lerp(q2, t)

	var s = r0.lerp(r1, t)
	return s

### VALUES

func move_towards(target, current, amount):
	if target > current:
		if current + amount >= target:
			return target
		return current + amount
	elif target < current:
		if current - amount <= target:
			return target
		return current - amount
	return current
