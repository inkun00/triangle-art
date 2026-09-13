class_name TriangleMath
extends RefCounted

## Pure geometric math and classification functions for Triangle Art.

const EPSILON: float = 0.0001
const ANGLE_TOLERANCE: float = 0.8 # degrees tolerance for right angle, equilateral, etc.
const SIDE_TOLERANCE_PX: float = 1.5

static func calculate_area(a: Vector2, b: Vector2, c: Vector2) -> float:
	return absf(0.5 * ((b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y)))

static func is_valid_triangle(a: Vector2, b: Vector2, c: Vector2, min_area: float = 15.0) -> bool:
	if a.distance_to(b) < 3.0 or b.distance_to(c) < 3.0 or c.distance_to(a) < 3.0:
		return false
	return calculate_area(a, b, c) >= min_area

static func get_side_lengths_px(a: Vector2, b: Vector2, c: Vector2) -> Dictionary:
	return {
		"ab": a.distance_to(b),
		"bc": b.distance_to(c),
		"ca": c.distance_to(a)
	}

static func get_side_lengths_grid(a: Vector2, b: Vector2, c: Vector2, grid_step: float = 40.0) -> Dictionary:
	var step: float = maxf(grid_step, 1.0)
	return {
		"ab": a.distance_to(b) / step,
		"bc": b.distance_to(c) / step,
		"ca": c.distance_to(a) / step
	}

static func get_raw_angles_deg(a: Vector2, b: Vector2, c: Vector2) -> Dictionary:
	var v_ab: Vector2 = b - a
	var v_ac: Vector2 = c - a
	var v_ba: Vector2 = a - b
	var v_bc: Vector2 = c - b
	var v_ca: Vector2 = a - c
	var v_cb: Vector2 = b - c

	var len_ab: float = v_ab.length()
	var len_bc: float = v_bc.length()
	var len_ca: float = v_ca.length()

	if len_ab < EPSILON or len_bc < EPSILON or len_ca < EPSILON:
		return {"a": 60.0, "b": 60.0, "c": 60.0}

	var dot_a: float = clampf(v_ab.dot(v_ac) / (len_ab * len_ca), -1.0, 1.0)
	var dot_b: float = clampf(v_ba.dot(v_bc) / (len_ab * len_bc), -1.0, 1.0)
	var dot_c: float = clampf(v_ca.dot(v_cb) / (len_ca * len_bc), -1.0, 1.0)

	var ang_a: float = rad_to_deg(acos(dot_a))
	var ang_b: float = rad_to_deg(acos(dot_b))
	var ang_c: float = rad_to_deg(acos(dot_c))

	return {
		"a": ang_a,
		"b": ang_b,
		"c": ang_c
	}

## Returns integer angles whose sum is guaranteed to be exactly 180 degrees.
static func get_display_angles_deg(a: Vector2, b: Vector2, c: Vector2) -> Dictionary:
	var raw: Dictionary = get_raw_angles_deg(a, b, c)
	var ang_a: float = raw["a"]
	var ang_b: float = raw["b"]
	var ang_c: float = raw["c"]

	var round_a: int = roundi(ang_a)
	var round_b: int = roundi(ang_b)
	var round_c: int = roundi(ang_c)

	var sum_deg: int = round_a + round_b + round_c
	var diff: int = 180 - sum_deg

	if diff != 0:
		# Calculate remainder errors
		var err_a: float = absf(ang_a - float(round_a))
		var err_b: float = absf(ang_b - float(round_b))
		var err_c: float = absf(ang_c - float(round_c))

		if err_a >= err_b and err_a >= err_c:
			round_a += diff
		elif err_b >= err_a and err_b >= err_c:
			round_b += diff
		else:
			round_c += diff

	return {
		"a": round_a,
		"b": round_b,
		"c": round_c
	}

static func classify_triangle(a: Vector2, b: Vector2, c: Vector2) -> Dictionary:
	var sides: Dictionary = get_side_lengths_px(a, b, c)
	var s_ab: float = sides["ab"]
	var s_bc: float = sides["bc"]
	var s_ca: float = sides["ca"]

	var angles: Dictionary = get_raw_angles_deg(a, b, c)
	var ang_a: float = angles["a"]
	var ang_b: float = angles["b"]
	var ang_c: float = angles["c"]

	# Check side equality
	var eq_ab_bc: bool = absf(s_ab - s_bc) <= SIDE_TOLERANCE_PX
	var eq_bc_ca: bool = absf(s_bc - s_ca) <= SIDE_TOLERANCE_PX
	var eq_ca_ab: bool = absf(s_ca - s_ab) <= SIDE_TOLERANCE_PX

	var is_equilateral: bool = eq_ab_bc and eq_bc_ca
	var is_isosceles: bool = is_equilateral or eq_ab_bc or eq_bc_ca or eq_ca_ab

	# Check angle characteristics
	var max_angle: float = maxf(ang_a, maxf(ang_b, ang_c))
	var is_right: bool = false

	if absf(ang_a - 90.0) <= ANGLE_TOLERANCE or absf(ang_b - 90.0) <= ANGLE_TOLERANCE or absf(ang_c - 90.0) <= ANGLE_TOLERANCE:
		is_right = true

	var angle_type: String = "예각"
	if is_right:
		angle_type = "직각"
	elif max_angle > 90.0 + ANGLE_TOLERANCE:
		angle_type = "둔각"

	# Build composite name
	var display_name: String = ""
	if is_equilateral:
		display_name = "정삼각형"
	elif is_right and is_isosceles:
		display_name = "직각이등변삼각형"
	elif is_right:
		display_name = "직각삼각형"
	elif angle_type == "둔각" and is_isosceles:
		display_name = "둔각이등변삼각형"
	elif angle_type == "둔각":
		display_name = "둔각삼각형"
	elif is_isosceles:
		display_name = "이등변삼각형"
	else:
		display_name = "예각삼각형"

	return {
		"name": display_name,
		"is_equilateral": is_equilateral,
		"is_isosceles": is_isosceles,
		"is_right": is_right,
		"angle_type": angle_type,
		"max_angle": max_angle
	}

## Creates an equilateral triangle centered at `center`.
## Height = side * sqrt(3)/2. Top vertex points upward.
static func create_equilateral_vertices(side_length: float = 120.0, center: Vector2 = Vector2.ZERO) -> Array[Vector2]:
	var h: float = side_length * sqrt(3.0) / 2.0
	# Centroid divides height into 2/3 and 1/3
	var top_y: float = center.y - (2.0 / 3.0) * h
	var bot_y: float = center.y + (1.0 / 3.0) * h
	var half_w: float = side_length / 2.0

	var v_a: Vector2 = Vector2(center.x, top_y)
	var v_b: Vector2 = Vector2(center.x - half_w, bot_y)
	var v_c: Vector2 = Vector2(center.x + half_w, bot_y)

	return [v_a, v_b, v_c]

## Point in triangle test (Barycentric technique)
static func is_point_in_triangle(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	var d1: float = (p.x - b.x) * (a.y - b.y) - (a.x - b.x) * (p.y - b.y)
	var d2: float = (p.x - c.x) * (b.y - c.y) - (b.x - c.x) * (p.y - c.y)
	var d3: float = (p.x - a.x) * (c.y - a.y) - (c.x - a.x) * (p.y - a.y)

	var has_neg: bool = (d1 < 0.0) or (d2 < 0.0) or (d3 < 0.0)
	var has_pos: bool = (d1 > 0.0) or (d2 > 0.0) or (d3 > 0.0)

	return !(has_neg and has_pos)

## Snaps a vector to a grid step.
static func snap_point(pt: Vector2, grid_step: float = 40.0) -> Vector2:
	if grid_step <= 0.0:
		return pt
	return Vector2(
		roundf(pt.x / grid_step) * grid_step,
		roundf(pt.y / grid_step) * grid_step
	)

## Rotates an array of vertices around a centroid by angle_rad radians.
static func rotate_vertices(verts: Array[Vector2], angle_rad: float, center: Vector2 = Vector2.ZERO) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for v in verts:
		var offset: Vector2 = v - center
		var rotated: Vector2 = offset.rotated(angle_rad)
		result.append(center + rotated)
	return result

## Flips an array of vertices horizontally relative to center.x
static func flip_vertices_h(verts: Array[Vector2], center: Vector2 = Vector2.ZERO) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for v in verts:
		var dx: float = v.x - center.x
		result.append(Vector2(center.x - dx, v.y))
	return result

## Flips an array of vertices vertically relative to center.y
static func flip_vertices_v(verts: Array[Vector2], center: Vector2 = Vector2.ZERO) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for v in verts:
		var dy: float = v.y - center.y
		result.append(Vector2(v.x, center.y - dy))
	return result

## Scales an array of vertices proportionally around center by scale_ratio.
## Preserves all angles and shape proportions perfectly.
static func scale_vertices_proportional(verts: Array[Vector2], scale_ratio: float, center: Vector2 = Vector2.ZERO) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var ratio: float = maxf(scale_ratio, 0.05)
	for v in verts:
		var offset: Vector2 = v - center
		result.append(center + offset * ratio)
	return result

## Finds the closest point on a finite line segment (seg_a -> seg_b) to point pt.
static func get_closest_point_on_segment(pt: Vector2, seg_a: Vector2, seg_b: Vector2) -> Vector2:
	var ab: Vector2 = seg_b - seg_a
	var len_sq: float = ab.length_squared()
	if len_sq < EPSILON:
		return seg_a
	var t: float = clampf((pt - seg_a).dot(ab) / len_sq, 0.0, 1.0)
	return seg_a + ab * t

## Finds magnetic snapping between a moving triangle and other triangles.
## Handles Vertex-to-Vertex and Vertex-to-Edge (edge touching) magnetic alignment.
static func find_inter_triangle_snap(moving_triangle: Node, other_triangles: Array, snap_dist: float = 14.0) -> Dictionary:
	var default_res: Dictionary = {"snapped": false, "offset": Vector2.ZERO, "snap_points": []}
	if not moving_triangle:
		return default_res

	var m_pos: Vector2 = moving_triangle.position
	var m_verts: Array[Vector2] = [
		m_pos + moving_triangle.vertex_a,
		m_pos + moving_triangle.vertex_b,
		m_pos + moving_triangle.vertex_c
	]

	var best_dist: float = snap_dist
	var best_offset: Vector2 = Vector2.ZERO
	var best_snap_pt: Vector2 = Vector2.ZERO
	var snapped: bool = false

	# 1. Vertex-to-Vertex snap (highest magnetic priority)
	for other in other_triangles:
		if other == moving_triangle or not is_instance_valid(other):
			continue
		var o_pos: Vector2 = other.position
		var o_verts: Array[Vector2] = [
			o_pos + other.vertex_a,
			o_pos + other.vertex_b,
			o_pos + other.vertex_c
		]

		for mv in m_verts:
			for ov in o_verts:
				var d: float = mv.distance_to(ov)
				if d < best_dist:
					best_dist = d
					best_offset = ov - mv
					best_snap_pt = ov
					snapped = true

	if snapped:
		return {"snapped": true, "offset": best_offset, "snap_points": [best_snap_pt]}

	# 2. Vertex-to-Edge snap (moving vertex touches other triangle's edge)
	for other in other_triangles:
		if other == moving_triangle or not is_instance_valid(other):
			continue
		var o_pos: Vector2 = other.position
		var o_verts: Array[Vector2] = [
			o_pos + other.vertex_a,
			o_pos + other.vertex_b,
			o_pos + other.vertex_c
		]
		var o_edges: Array = [
			[o_verts[0], o_verts[1]],
			[o_verts[1], o_verts[2]],
			[o_verts[2], o_verts[0]]
		]

		for mv in m_verts:
			for edge in o_edges:
				var pt_on_seg: Vector2 = get_closest_point_on_segment(mv, edge[0], edge[1])
				var d: float = mv.distance_to(pt_on_seg)
				if d < best_dist:
					best_dist = d
					best_offset = pt_on_seg - mv
					best_snap_pt = pt_on_seg
					snapped = true

	if snapped:
		return {"snapped": true, "offset": best_offset, "snap_points": [best_snap_pt]}

	# 3. Edge-to-Vertex snap (other vertex touches moving triangle's edge)
	var m_edges: Array = [
		[m_verts[0], m_verts[1]],
		[m_verts[1], m_verts[2]],
		[m_verts[2], m_verts[0]]
	]
	for other in other_triangles:
		if other == moving_triangle or not is_instance_valid(other):
			continue
		var o_pos: Vector2 = other.position
		var o_verts: Array[Vector2] = [
			o_pos + other.vertex_a,
			o_pos + other.vertex_b,
			o_pos + other.vertex_c
		]

		for ov in o_verts:
			for edge in m_edges:
				var pt_on_seg: Vector2 = get_closest_point_on_segment(ov, edge[0], edge[1])
				var d: float = ov.distance_to(pt_on_seg)
				if d < best_dist:
					best_dist = d
					best_offset = ov - pt_on_seg
					best_snap_pt = ov
					snapped = true

	if snapped:
		var all_snap_pts: Array[Vector2] = [best_snap_pt]
		var shifted_m_verts: Array[Vector2] = [
			m_verts[0] + best_offset,
			m_verts[1] + best_offset,
			m_verts[2] + best_offset
		]
		for smv in shifted_m_verts:
			for other in other_triangles:
				if other == moving_triangle or not is_instance_valid(other):
					continue
				var o_pos: Vector2 = other.position
				var o_verts: Array[Vector2] = [o_pos + other.vertex_a, o_pos + other.vertex_b, o_pos + other.vertex_c]
				for ov in o_verts:
					if smv.distance_to(ov) < 2.0 and not all_snap_pts.has(ov):
						all_snap_pts.append(ov)
		return {"snapped": true, "offset": best_offset, "snap_points": all_snap_pts}

	return default_res

## Finds magnetic snapping for a single dragged vertex against other triangles (vertices and edges).
static func find_vertex_snap(moving_vertex_world: Vector2, moving_triangle: Node, other_triangles: Array, snap_dist: float = 14.0) -> Dictionary:
	var default_res: Dictionary = {"snapped": false, "snapped_pos": moving_vertex_world, "snap_points": []}
	var best_dist: float = snap_dist
	var best_pt: Vector2 = moving_vertex_world
	var snapped: bool = false

	# 1. Vertex-to-Vertex snap (highest priority)
	for other in other_triangles:
		if other == moving_triangle or not is_instance_valid(other):
			continue
		var o_pos: Vector2 = other.position
		var o_verts: Array[Vector2] = [o_pos + other.vertex_a, o_pos + other.vertex_b, o_pos + other.vertex_c]
		for ov in o_verts:
			var d: float = moving_vertex_world.distance_to(ov)
			if d < best_dist:
				best_dist = d
				best_pt = ov
				snapped = true

	if snapped:
		return {"snapped": true, "snapped_pos": best_pt, "snap_points": [best_pt]}

	# 2. Vertex-to-Edge snap (moving vertex touches other triangle's edge)
	for other in other_triangles:
		if other == moving_triangle or not is_instance_valid(other):
			continue
		var o_pos: Vector2 = other.position
		var o_verts: Array[Vector2] = [o_pos + other.vertex_a, o_pos + other.vertex_b, o_pos + other.vertex_c]
		var o_edges: Array = [
			[o_verts[0], o_verts[1]],
			[o_verts[1], o_verts[2]],
			[o_verts[2], o_verts[0]]
		]
		for edge in o_edges:
			var pt_on_seg: Vector2 = get_closest_point_on_segment(moving_vertex_world, edge[0], edge[1])
			var d: float = moving_vertex_world.distance_to(pt_on_seg)
			if d < best_dist:
				best_dist = d
				best_pt = pt_on_seg
				snapped = true

	if snapped:
		return {"snapped": true, "snapped_pos": best_pt, "snap_points": [best_pt]}

	return default_res

