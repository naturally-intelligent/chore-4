@tool
extends Node

### RANDOM NUMBERS

func random_chance(chance: int) -> bool:
	return randi_range(0, chance) == 0

func random_choice(chance: int) -> int:
	return randi_range(1, chance)

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
	var steps := int((end - start) / step)
	return start + float(randi()%(steps+1)) * step

func randomf(s: float, e: float) -> float: # shortened version of random_float
	return randf_range(s, e)

func random_position(minx:int,maxx:int, miny:int,maxy:int) -> Vector2:
	return Vector2(random_int(minx,maxx), random_int(miny,maxy))

func random_vector_position(vector1: Vector2, vector2: Vector2) -> Vector2:
	return Vector2(random_int(int(vector1.x),int(vector2.x)), random_int(int(vector1.y),int(vector2.y)))

func random_vector(x_factor := 1.0, y_factor := 1.0) -> Vector2:
	return Vector2(random_float(-1.0,1.0)*x_factor, random_float(-1.0,1.0)*y_factor).normalized()

func random_vector_offset(x_factor := 1, y_factor := 1) -> Vector2:
	return Vector2(random_int(-x_factor,x_factor), random_int(-y_factor,y_factor))

func random_left_right_vector() -> Vector2:
	if ((randi()%2) == 0):
		return Vector2.LEFT
	else:
		return Vector2.RIGHT

### VECTORS AND ANGLES

# rounds a vector2d
func round_angle_to_degree(normal: Vector2, angle_in_degrees: float) -> Vector2:
	var angle := normal.angle()
	angle = snapped(angle, deg_to_rad(angle_in_degrees))
	return Vector2(cos(angle), sin(angle))

# rounds a vector2d and returns angle
func round_angle_to_degree_with_angle(normal: Vector2, angle_in_degrees: float) -> Array:
	var angle := normal.angle()
	angle = snapped(angle, deg_to_rad(angle_in_degrees))
	return [Vector2(cos(angle), sin(angle)), rad2deg360(angle)]

func angle_frame_45(angle: int) -> int:
	return int(clamp(angle,0,359) / 45)

func angle_frame_90(angle: int) -> int:
	return int(clamp(angle,0,359) / 90)

func rad2deg360(radians: float) -> int:
	var degrees := rad_to_deg(radians)
	if degrees < 0:
		degrees += 360
	return int(degrees)

func normal_to_degrees(n: Vector2) -> float:
	return atan2(n.y, n.x) * 180 / PI

func normal_to_360_degrees(n: Vector2) -> float:
	var theta := atan2(n.y, n.x)
	var deg := rad_to_deg(theta)
	if deg < 0: deg += 360
	return deg

func normal_to_45(n: Vector2) -> float:
	var deg := normal_to_360_degrees(n)
	return snappedf(deg, 45)

func normal_to_90(n: Vector2) -> float:
	var deg := normal_to_360_degrees(n)
	if deg >= 360: deg -= 360
	return snappedf(deg, 90)

func radians_to_vector(radians: float) -> Vector2:
	return Vector2(cos(radians), sin(radians))

func cap_vector(v: Vector2, xy_max: float) -> Vector2:
	if v.x > xy_max: v.x = xy_max
	if v.y > xy_max: v.y = xy_max
	if v.x < -xy_max: v.x = -xy_max
	if v.y < -xy_max: v.y = -xy_max
	return v

# GEOMETRY

func segment_intersect_rect2(from: Vector2, to: Vector2, rect2: Rect2) -> Variant:
	var intersections := []
	var left_test = Geometry2D.segment_intersects_segment(from, to, Vector2(rect2.position.x, rect2.position.y), Vector2(rect2.position.x, rect2.end.y))
	var right_test = Geometry2D.segment_intersects_segment(from, to, Vector2(rect2.end.x, rect2.position.y), Vector2(rect2.end.x, rect2.end.y))
	var top_test = Geometry2D.segment_intersects_segment(from, to, Vector2(rect2.position.x, rect2.position.y), Vector2(rect2.end.x, rect2.position.y))
	var bottom_test = Geometry2D.segment_intersects_segment(from, to, Vector2(rect2.position.x, rect2.end.y), Vector2(rect2.end.x, rect2.end.y))
	if left_test: intersections.append(left_test)
	if right_test: intersections.append(right_test)
	if top_test: intersections.append(top_test)
	if bottom_test: intersections.append(bottom_test)
	if intersections.size() == 1:
		return intersections[0]
	return closest_point(from, intersections)

func closest_point(origin: Vector2, targets: Array, closest_distance := 1000000.0) -> Vector2:
	var closest = null
	for target: Vector2 in targets:
		var target_distance := origin.distance_to(target)
		if target_distance < closest_distance:
			closest_distance = target_distance
			closest = target
	if closest:
		return closest
	return origin
	
### POSITIONS

func nearest_position(parent: Node, position: Vector2) -> Vector2:
	var nearest := 100000.0
	var nearest_pos := Vector2.ZERO
	for node in parent.get_children():
		var dist2 := position.distance_squared_to(node.position)
		if dist2 < nearest:
			nearest_pos = node.position
			nearest = dist2
	return nearest_pos

func nearest_global_position(parent: Node, position: Vector2) -> Vector2:
	var nearest := 100000.0
	var nearest_pos := Vector2.ZERO
	for node in parent.get_children():
		var dist2 := position.distance_squared_to(node.global_position)
		if dist2 < nearest:
			nearest_pos = node.global_position
			nearest = dist2
	return nearest_pos

func nearest_global_node(parent: Node, position: Vector2) -> Node2D:
	var nearest := 100000.0
	var nearest_pos := Vector2.ZERO
	var nearest_node: Node2D = null
	for node in parent.get_children():
		var dist2 := position.distance_squared_to(node.global_position)
		if dist2 < nearest:
			nearest_pos = node.global_position
			nearest = dist2
			nearest_node = node
	return nearest_node

### CURVES

func quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Array:
	var q0 := p0.lerp(p1, t)
	var q1 := p1.lerp(p2, t)
	return [q0, q1]

func cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var q0 := p0.lerp(p1, t)
	var q1 := p1.lerp(p2, t)
	var q2 := p2.lerp(p3, t)

	var r0 := q0.lerp(q1, t)
	var r1 := q1.lerp(q2, t)

	var s := r0.lerp(r1, t)
	return s

### VALUES

func move_towards(target: int, current: int, amount: int) -> int:
	if target > current:
		if current + amount >= target:
			return target
		return current + amount
	elif target < current:
		if current - amount <= target:
			return target
		return current - amount
	return current

### POLYGONS

func polygon_from_sprite(sprite: Sprite2D, mirror := false, epsilon := 2.0, area := Rect2()) -> Array:
	var image: Image = sprite.texture.get_image()
	var texture_size := sprite.texture.get_size()
	var texture_frames := Vector2(sprite.hframes, sprite.vframes)
	var sprite_size := texture_size / texture_frames
	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(image)
	# using sprite sheet?
	if not area:
		if sprite.hframes > 1 or sprite.vframes > 1:
			var sprite_size_2i := Vector2i(sprite_size)
			area = Rect2(sprite.frame_coords * sprite_size_2i, sprite_size_2i)
		else:
			area = Rect2(Vector2(), texture_size)
	var polygons := bitmap.opaque_to_polygons(area, epsilon)
	var final_polygon: PackedVector2Array
	# find the bounding box
	var bounding_min := polygons[0][0]
	var bounding_max := polygons[0][0]
	for j: Vector2 in polygons[0]:
		if j.x < bounding_min.x: bounding_min.x = j.x
		if j.y < bounding_min.y: bounding_min.y = j.y
		if j.x > bounding_max.x: bounding_max.x = j.x
		if j.y > bounding_max.y: bounding_max.y = j.y
	var bounding_mirror_x := (bounding_max.x - bounding_min.x) * 2
	var offset := Vector2.ZERO
	if mirror:
		offset.x = sprite_size.x - bounding_mirror_x
	# final polygon
	for point: Vector2 in polygons[0]:
		if mirror:
			point.x = bounding_mirror_x - point.x
		if sprite.centered:
			point -= sprite_size / 2
		point += offset
		final_polygon.append(point)
	# return all data
	return [final_polygon, bounding_min, bounding_max, sprite_size]
