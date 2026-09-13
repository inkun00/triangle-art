class_name TriangleNode
extends Node2D

const TriangleMath = preload("res://scripts/core/triangle_math.gd")
const TriangleCommands = preload("res://scripts/core/triangle_commands.gd")
const SoundManager = preload("res://scripts/core/sound_manager.gd")
const KOREAN_FONT = preload("res://assets/fonts/korean_font.ttf")

## Interactive Triangle Scene Node for Triangle Art.

signal selected_changed(node: TriangleNode, is_selected: bool)
signal geometry_changed(node: TriangleNode)
signal action_committed(command: Variant)

enum DragMode { NONE, BODY, VERTEX_A, VERTEX_B, VERTEX_C, ROTATION }

@export var vertex_a: Vector2 = Vector2(0, -50)
@export var vertex_b: Vector2 = Vector2(-50, 40)
@export var vertex_c: Vector2 = Vector2(50, 40)
@export var fill_color: Color = Color(0.26, 0.58, 0.95, 0.88)
@export var outline_color: Color = Color(0.12, 0.22, 0.38, 1.0)
@export var outline_width: float = 3.0
@export var is_selected: bool = false
@export var show_measurements: bool = true
@export var grid_step: float = 40.0
@export var snap_enabled: bool = false
@export var group_id: String = ""
@export var is_scale_locked: bool = false
@export var hide_rotation_handle: bool = false
@export var zoom_level: float = 1.0:
	set(val):
		zoom_level = maxf(val, 0.05)
		queue_redraw()

var current_drag: DragMode = DragMode.NONE
var drag_start_mouse: Vector2 = Vector2.ZERO
var drag_start_pos: Vector2 = Vector2.ZERO
var drag_start_vertex: Vector2 = Vector2.ZERO
var drag_start_verts: Array[Vector2] = []
var drag_start_centroid: Vector2 = Vector2.ZERO
var drag_start_angle: float = 0.0
var drag_start_handle_local: Vector2 = Vector2.ZERO
var drag_start_anchor_local: Vector2 = Vector2.ZERO
var current_drag_delta_rad: float = 0.0
var current_rotation_deg: float = 0.0

const HANDLE_HIT_RADIUS: float = 18.0
const HANDLE_DRAW_RADIUS: float = 9.0
const ROTATION_HANDLE_RADIUS: float = 8.0

func _ready() -> void:
	queue_redraw()

func set_selected(selected: bool) -> void:
	if is_selected != selected:
		is_selected = selected
		z_index = 10 if is_selected else 0
		selected_changed.emit(self, is_selected)
		queue_redraw()

func set_vertex_position(vertex_idx: int, new_local_pos: Vector2) -> void:
	match vertex_idx:
		0: vertex_a = new_local_pos
		1: vertex_b = new_local_pos
		2: vertex_c = new_local_pos
	geometry_changed.emit(self)
	queue_redraw()

func get_vertices() -> Array[Vector2]:
	return [vertex_a, vertex_b, vertex_c]

func set_vertices(verts: Array[Vector2]) -> void:
	if verts.size() >= 3:
		vertex_a = verts[0]
		vertex_b = verts[1]
		vertex_c = verts[2]
		geometry_changed.emit(self)
		queue_redraw()

func get_centroid() -> Vector2:
	return (vertex_a + vertex_b + vertex_c) / 3.0

func rotate_by_deg(angle_deg: float) -> void:
	var old_verts: Array[Vector2] = [vertex_a, vertex_b, vertex_c]
	var center: Vector2 = get_centroid()
	var new_verts = TriangleMath.rotate_vertices(old_verts, deg_to_rad(angle_deg), center)
	var cmd = TriangleCommands.TransformVerticesCommand.new(self, old_verts, new_verts)
	action_committed.emit(cmd)

func flip_h() -> void:
	var old_verts: Array[Vector2] = [vertex_a, vertex_b, vertex_c]
	var center: Vector2 = get_centroid()
	var new_verts = TriangleMath.flip_vertices_h(old_verts, center)
	var cmd = TriangleCommands.TransformVerticesCommand.new(self, old_verts, new_verts)
	action_committed.emit(cmd)

func flip_v() -> void:
	var old_verts: Array[Vector2] = [vertex_a, vertex_b, vertex_c]
	var center: Vector2 = get_centroid()
	var new_verts = TriangleMath.flip_vertices_v(old_verts, center)
	var cmd = TriangleCommands.TransformVerticesCommand.new(self, old_verts, new_verts)
	action_committed.emit(cmd)

func get_top_anchor() -> Vector2:
	var verts: Array[Vector2] = [vertex_a, vertex_b, vertex_c]
	verts.sort_custom(func(p1: Vector2, p2: Vector2) -> bool: return p1.y < p2.y)
	if absf(verts[0].y - verts[1].y) < 2.0:
		return (verts[0] + verts[1]) * 0.5
	return verts[0]

func get_bottom_anchor() -> Vector2:
	var verts: Array[Vector2] = [vertex_a, vertex_b, vertex_c]
	verts.sort_custom(func(p1: Vector2, p2: Vector2) -> bool: return p1.y > p2.y)
	if absf(verts[0].y - verts[1].y) < 2.0:
		return (verts[0] + verts[1]) * 0.5
	return verts[0]

func get_rotation_anchor() -> Vector2:
	var top_anchor: Vector2 = get_top_anchor()
	var c: Vector2 = get_centroid()
	var offset: float = 30.0 / zoom_level
	var dir: Vector2 = (top_anchor - c).normalized()
	if dir.length_squared() < 0.001 or dir.y >= 0.0:
		dir = Vector2.UP

	var world_handle_y: float = position.y + top_anchor.y + dir.y * offset
	if world_handle_y < 0.0:
		return get_bottom_anchor()
	return top_anchor

func get_rotation_handle_pos() -> Vector2:
	var anchor: Vector2 = get_rotation_anchor()
	var c: Vector2 = get_centroid()
	var dir: Vector2 = (anchor - c).normalized()
	if dir.length_squared() < 0.001:
		dir = Vector2.UP if anchor.y <= c.y else Vector2.DOWN
	var offset: float = 30.0 / zoom_level
	return anchor + dir * offset

func get_handle_hit_radius() -> float:
	return maxf(HANDLE_HIT_RADIUS, 22.0 / zoom_level)

func hit_test_rotation_handle(canvas_point: Vector2) -> bool:
	if hide_rotation_handle:
		return false
	var local_pt: Vector2 = canvas_point - position
	# 1. Primary rotation handle
	if local_pt.distance_to(get_rotation_handle_pos()) <= get_handle_hit_radius():
		return true
	# 2. Outer corner rotation zone (outside triangle body, between 18px and 36px from any vertex)
	if hit_test_corner_rotation(canvas_point):
		return true
	return false

func hit_test_primary_rotation_handle(canvas_point: Vector2) -> bool:
	if hide_rotation_handle:
		return false
	var local_pt: Vector2 = canvas_point - position
	return local_pt.distance_to(get_rotation_handle_pos()) <= get_handle_hit_radius()

func hit_test_corner_rotation(canvas_point: Vector2) -> bool:
	if hide_rotation_handle:
		return false
	var local_pt: Vector2 = canvas_point - position
	if TriangleMath.is_point_in_triangle(local_pt, vertex_a, vertex_b, vertex_c):
		return false
	var v_hit_rad: float = maxf(HANDLE_HIT_RADIUS, 18.0 / zoom_level)
	var corner_rot_rad: float = maxf(34.0, 36.0 / zoom_level)
	for v in [vertex_a, vertex_b, vertex_c]:
		var d: float = local_pt.distance_to(v)
		if d > v_hit_rad and d <= corner_rot_rad:
			return true
	return false

func hit_test_body(canvas_point: Vector2) -> bool:
	var local_pt: Vector2 = canvas_point - position
	return TriangleMath.is_point_in_triangle(local_pt, vertex_a, vertex_b, vertex_c)

func hit_test_handle(canvas_point: Vector2) -> int:
	var local_pt: Vector2 = canvas_point - position
	var hit_rad: float = maxf(HANDLE_HIT_RADIUS, 18.0 / zoom_level)
	if local_pt.distance_to(vertex_a) <= hit_rad:
		return 0
	if local_pt.distance_to(vertex_b) <= hit_rad:
		return 1
	if local_pt.distance_to(vertex_c) <= hit_rad:
		return 2
	return -1

func _start_rotation_drag(canvas_point: Vector2) -> void:
	current_drag = DragMode.ROTATION
	drag_start_mouse = canvas_point
	drag_start_pos = position
	drag_start_verts = [vertex_a, vertex_b, vertex_c]
	drag_start_centroid = get_centroid()
	drag_start_handle_local = get_rotation_handle_pos()
	drag_start_anchor_local = get_rotation_anchor()
	var c_canvas: Vector2 = position + drag_start_centroid
	drag_start_angle = (canvas_point - c_canvas).angle()
	current_drag_delta_rad = 0.0
	current_rotation_deg = 0.0
	queue_redraw()

func handle_input_press(canvas_point: Vector2) -> bool:
	# 1. Primary rotation handle test (when already selected)
	if is_selected and hit_test_primary_rotation_handle(canvas_point):
		_start_rotation_drag(canvas_point)
		return true

	# 2. Handle hit test (selects and allows vertex drag)
	var handle_idx: int = hit_test_handle(canvas_point)
	if handle_idx != -1:
		set_selected(true)
		drag_start_mouse = canvas_point
		drag_start_pos = position
		drag_start_verts = [vertex_a, vertex_b, vertex_c]
		match handle_idx:
			0:
				current_drag = DragMode.VERTEX_A
				drag_start_vertex = vertex_a
			1:
				current_drag = DragMode.VERTEX_B
				drag_start_vertex = vertex_b
			2:
				current_drag = DragMode.VERTEX_C
				drag_start_vertex = vertex_c
		return true

	# 3. Outer corner rotation zone (when already selected)
	if is_selected and hit_test_corner_rotation(canvas_point):
		_start_rotation_drag(canvas_point)
		return true

	# 4. Body hit test (selects and allows body movement)
	if hit_test_body(canvas_point):
		set_selected(true)
		current_drag = DragMode.BODY
		drag_start_mouse = canvas_point
		drag_start_pos = position
		return true

	return false

func handle_input_drag(canvas_point: Vector2) -> void:
	if current_drag == DragMode.NONE:
		return

	var delta: Vector2 = canvas_point - drag_start_mouse

	if current_drag == DragMode.BODY:
		var raw_new_pos: Vector2 = drag_start_pos + delta
		if snap_enabled:
			position = TriangleMath.snap_point(raw_new_pos, grid_step)
		else:
			position = raw_new_pos
		geometry_changed.emit(self)
		queue_redraw()
	elif current_drag == DragMode.ROTATION:
		var c_canvas: Vector2 = position + drag_start_centroid
		var cur_angle: float = (canvas_point - c_canvas).angle()
		var delta_rad: float = cur_angle - drag_start_angle
		if snap_enabled:
			var deg: float = rad_to_deg(delta_rad)
			deg = roundf(deg / 15.0) * 15.0
			delta_rad = deg_to_rad(deg)
		var prev_rot: float = current_rotation_deg
		current_rotation_deg = roundf(wrapf(rad_to_deg(delta_rad), -180.0, 180.0))
		if prev_rot != current_rotation_deg and SoundManager.instance:
			SoundManager.instance.play_rotate_tick()
		var new_verts = TriangleMath.rotate_vertices(drag_start_verts, delta_rad, drag_start_centroid)
		vertex_a = new_verts[0]
		vertex_b = new_verts[1]
		vertex_c = new_verts[2]
		geometry_changed.emit(self)
		queue_redraw()
	elif current_drag in [DragMode.VERTEX_A, DragMode.VERTEX_B, DragMode.VERTEX_C]:
		var target_canvas_pt: Vector2 = canvas_point
		if snap_enabled:
			target_canvas_pt = TriangleMath.snap_point(canvas_point, grid_step)
		var new_local: Vector2 = target_canvas_pt - position

		var lock_scale: bool = is_scale_locked or Input.is_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_ALT)
		if lock_scale:
			var centroid: Vector2 = get_centroid()
			var orig_dist: float = (drag_start_vertex - centroid).length()
			var cur_dist: float = (new_local - centroid).length()
			if orig_dist > 2.0:
				var scale_ratio: float = maxf(cur_dist / orig_dist, 0.1)
				var new_verts = TriangleMath.scale_vertices_proportional(drag_start_verts, scale_ratio, centroid)
				if TriangleMath.is_valid_triangle(new_verts[0], new_verts[1], new_verts[2], 10.0):
					vertex_a = new_verts[0]
					vertex_b = new_verts[1]
					vertex_c = new_verts[2]
					geometry_changed.emit(self)
					queue_redraw()
		else:
			var test_a: Vector2 = vertex_a
			var test_b: Vector2 = vertex_b
			var test_c: Vector2 = vertex_c
			var v_idx: int = 0

			match current_drag:
				DragMode.VERTEX_A:
					test_a = new_local
					v_idx = 0
				DragMode.VERTEX_B:
					test_b = new_local
					v_idx = 1
				DragMode.VERTEX_C:
					test_c = new_local
					v_idx = 2

			# Prevent collapsed collinear triangle
			if TriangleMath.is_valid_triangle(test_a, test_b, test_c, 10.0):
				set_vertex_position(v_idx, new_local)

func handle_input_release(canvas_point: Vector2) -> void:
	if current_drag == DragMode.NONE:
		return

	if current_drag == DragMode.BODY:
		if position != drag_start_pos:
			var cmd = TriangleCommands.MoveCommand.new(self, drag_start_pos, position)
			action_committed.emit(cmd)
	elif current_drag == DragMode.ROTATION:
		current_drag_delta_rad = 0.0
		if drag_start_verts.size() == 3 and (vertex_a != drag_start_verts[0] or vertex_b != drag_start_verts[1] or vertex_c != drag_start_verts[2]):
			var cmd = TriangleCommands.TransformVerticesCommand.new(self, drag_start_verts, [vertex_a, vertex_b, vertex_c])
			action_committed.emit(cmd)
	elif current_drag in [DragMode.VERTEX_A, DragMode.VERTEX_B, DragMode.VERTEX_C]:
		if drag_start_verts.size() == 3 and (vertex_a != drag_start_verts[0] or vertex_b != drag_start_verts[1] or vertex_c != drag_start_verts[2]):
			var cmd = TriangleCommands.TransformVerticesCommand.new(self, drag_start_verts, [vertex_a, vertex_b, vertex_c])
			action_committed.emit(cmd)

	current_drag = DragMode.NONE
	queue_redraw()

func scale_by_ratio(factor: float) -> void:
	var centroid: Vector2 = get_centroid()
	var old_verts: Array[Vector2] = [vertex_a, vertex_b, vertex_c]
	var new_verts = TriangleMath.scale_vertices_proportional(old_verts, factor, centroid)
	if TriangleMath.is_valid_triangle(new_verts[0], new_verts[1], new_verts[2], 10.0):
		var cmd = TriangleCommands.TransformVerticesCommand.new(self, old_verts, new_verts)
		action_committed.emit(cmd)

func _draw() -> void:
	# 1. Fill polygon
	var poly_pts: PackedVector2Array = PackedVector2Array([vertex_a, vertex_b, vertex_c])
	draw_colored_polygon(poly_pts, fill_color)

	# 2. Outline
	var line_pts: PackedVector2Array = PackedVector2Array([vertex_a, vertex_b, vertex_c, vertex_a])
	if outline_color.a > 0.001 and outline_width > 0.0:
		draw_polyline(line_pts, outline_color, outline_width, true)

	# Selection highlight ring
	if is_selected:
		var sel_width: float = maxf(outline_width + 1.2, 2.5)
		draw_polyline(line_pts, Color(0.18, 0.55, 0.95, 0.75), sel_width, true)

	# 3. If selected, draw handles, rotation handle & measurements
	if is_selected:
		if show_measurements:
			_draw_measurements()
		_draw_handles()
		if not hide_rotation_handle:
			_draw_rotation_handle()

func _draw_rotation_handle() -> void:
	var rot_pos: Vector2
	var anchor_pt: Vector2
	if current_drag == DragMode.ROTATION:
		rot_pos = drag_start_centroid + (drag_start_handle_local - drag_start_centroid).rotated(current_drag_delta_rad)
		anchor_pt = drag_start_centroid + (drag_start_anchor_local - drag_start_centroid).rotated(current_drag_delta_rad)
	else:
		rot_pos = get_rotation_handle_pos()
		anchor_pt = get_rotation_anchor()

	var draw_scale: float = 1.0 / zoom_level
	var line_w: float = 1.8 * draw_scale
	var r_outer: float = (HANDLE_DRAW_RADIUS + 3.0) * draw_scale
	var r_mid: float = HANDLE_DRAW_RADIUS * draw_scale
	var r_inner: float = (HANDLE_DRAW_RADIUS - 2.2) * draw_scale
	var r_dot: float = 2.5 * draw_scale

	# Connecting stem line directly from anchor vertex to handle
	draw_line(anchor_pt, rot_pos, Color(0.2, 0.45, 0.85, 0.7), line_w, true)

	# Outer halo
	draw_circle(rot_pos, r_outer, Color(0, 0, 0, 0.22))
	# White outer border
	draw_circle(rot_pos, r_mid, Color.WHITE)
	# Inner emerald green
	draw_circle(rot_pos, r_inner, Color(0.13, 0.75, 0.42, 1.0))
	# Center dot
	draw_circle(rot_pos, r_dot, Color.WHITE)

	# If currently rotating, draw degree pill badge
	if current_drag == DragMode.ROTATION:
		var font: Font = KOREAN_FONT if KOREAN_FONT else ThemeDB.fallback_font
		var deg_text: String = "%d°" % int(current_rotation_deg)
		_draw_pill_text(font, int(13 * draw_scale), deg_text, rot_pos + Vector2(0, -22 * draw_scale), Color(0.1, 0.15, 0.25), Color(1, 1, 1, 0.95), Color(0.13, 0.75, 0.42, 0.9))

func _draw_handles() -> void:
	var draw_scale: float = 1.0 / zoom_level
	var r_outer: float = (HANDLE_DRAW_RADIUS + 3.0) * draw_scale
	var r_mid: float = HANDLE_DRAW_RADIUS * draw_scale
	var r_inner: float = (HANDLE_DRAW_RADIUS - 2.5) * draw_scale
	var r_dot: float = 2.5 * draw_scale

	var handles: Array[Vector2] = [vertex_a, vertex_b, vertex_c]
	for h in handles:
		# Outer halo/shadow
		draw_circle(h, r_outer, Color(0, 0, 0, 0.25))
		# Outer white ring
		draw_circle(h, r_mid, Color.WHITE)
		# Inner primary color
		draw_circle(h, r_inner, Color(0.18, 0.52, 0.98, 1.0))
		# Center white dot
		draw_circle(h, r_dot, Color.WHITE)

func _draw_measurements() -> void:
	var font: Font = KOREAN_FONT if KOREAN_FONT else ThemeDB.fallback_font
	var font_size: int = 14
	var font_color: Color = Color(0.1, 0.14, 0.22, 1.0)
	var bg_color: Color = Color(1.0, 1.0, 1.0, 0.92)
	var centroid: Vector2 = get_centroid()

	# Display angles (Sum is always 180)
	var angles: Dictionary = TriangleMath.get_display_angles_deg(vertex_a, vertex_b, vertex_c)
	var pts: Array[Vector2] = [vertex_a, vertex_b, vertex_c]
	var angle_keys: Array[String] = ["a", "b", "c"]

	for i in range(3):
		var pt: Vector2 = pts[i]
		var ang_val: int = angles[angle_keys[i]]
		var text: String = str(ang_val) + "°"
		var dir_out: Vector2 = (pt - centroid).normalized()
		var text_pos: Vector2 = pt + dir_out * 24.0

		_draw_pill_text(font, font_size, text, text_pos, font_color, bg_color, Color(0.2, 0.5, 0.9, 0.8))

	# Display side lengths (in grid units)
	var sides: Dictionary = TriangleMath.get_side_lengths_grid(vertex_a, vertex_b, vertex_c, grid_step)
	var edge_mid_ab: Vector2 = (vertex_a + vertex_b) / 2.0
	var edge_mid_bc: Vector2 = (vertex_b + vertex_c) / 2.0
	var edge_mid_ca: Vector2 = (vertex_c + vertex_a) / 2.0

	var edge_mids: Array[Vector2] = [edge_mid_ab, edge_mid_bc, edge_mid_ca]
	var edge_keys: Array[String] = ["ab", "bc", "ca"]

	for i in range(3):
		var mid: Vector2 = edge_mids[i]
		var s_val: float = sides[edge_keys[i]]
		var s_text: String = "%.1f" % s_val
		if absf(s_val - roundf(s_val)) < 0.05:
			s_text = "%d" % roundi(s_val)

		var dir_edge_out: Vector2 = (mid - centroid).normalized()
		var badge_pos: Vector2 = mid + dir_edge_out * 18.0

		_draw_pill_text(font, font_size, s_text, badge_pos, Color(0.15, 0.2, 0.3), Color(0.97, 0.98, 1.0, 0.95), Color(0.7, 0.75, 0.85))

func _draw_pill_text(font: Font, font_size: int, text: String, center_pos: Vector2, text_color: Color, bg_color: Color, border_color: Color) -> void:
	var str_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var padding: Vector2 = Vector2(6, 3)
	var rect: Rect2 = Rect2(center_pos - str_size / 2.0 - padding, str_size + padding * 2.0)

	# Rounded rect background
	draw_rect(rect, bg_color, true, -1.0)
	draw_rect(rect, border_color, false, 1.2)

	# Text
	var baseline: Vector2 = Vector2(rect.position.x + padding.x, rect.position.y + padding.y + font.get_ascent(font_size))
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_color)

func clone_triangle() -> TriangleNode:
	var script_res = get_script()
	var new_t: TriangleNode = script_res.new()
	new_t.vertex_a = vertex_a
	new_t.vertex_b = vertex_b
	new_t.vertex_c = vertex_c
	new_t.fill_color = fill_color
	new_t.outline_color = outline_color
	new_t.outline_width = outline_width
	new_t.grid_step = grid_step
	new_t.snap_enabled = snap_enabled
	new_t.show_measurements = show_measurements
	new_t.zoom_level = zoom_level
	new_t.position = position + Vector2(24, 24)
	return new_t

