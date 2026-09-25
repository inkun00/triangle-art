class_name DrawingCanvas
extends "res://scenes/canvas/drawing_canvas_interaction.gd"

func export_project_json() -> String:
	return ProjectStorage.serialize_project(triangles, canvas_size)

func load_project_json(json_str: String) -> bool:
	var full_data: Dictionary = ProjectStorage.deserialize_project_full(json_str)
	var parsed: Array[Dictionary] = full_data.get("triangles", [] as Array[Dictionary])
	if not full_data.get("valid", false) or parsed.is_empty():
		return false

	var new_nodes: Array = []
	for item in parsed:
		var node: TriangleNode = TriangleNode.new()
		node.position = item["pos"]
		node.vertex_a = item["a"]
		node.vertex_b = item["b"]
		node.vertex_c = item["c"]
		node.fill_color = item["color"]
		node.outline_color = item.get("outline_color", Color.TRANSPARENT)
		node.outline_width = float(item.get("outline_width", 2.0))
		node.group_id = str(item.get("group_id", ""))
		new_nodes.append(node)

	var cmd = TriangleCommands.ReplaceProjectCommand.new(self, new_nodes, full_data["canvas_size"])
	action_performed.emit(cmd)
	return true

func _draw() -> void:
	# 1. Outer Workspace Desk Background
	var desk_bg: Color = Color(0.11, 0.13, 0.18, 1.0)
	draw_rect(Rect2(Vector2.ZERO, size), desk_bg, true)

	# 2. Canvas Paper (Artboard) bounds
	var paper_origin: Vector2 = world_to_canvas(Vector2.ZERO)
	var paper_extent: Vector2 = canvas_size * zoom_level
	var paper_rect: Rect2 = Rect2(paper_origin, paper_extent)

	# Realistic multi-layer drop shadow behind paper
	for i in range(4):
		var s_offset: Vector2 = Vector2(0.0, (i + 1) * 2.5)
		var s_expand: float = (i + 1) * 2.0
		var s_rect: Rect2 = Rect2(paper_origin - Vector2(s_expand, s_expand) + s_offset, paper_extent + Vector2(s_expand * 2.0, s_expand * 2.0))
		draw_rect(s_rect, Color(0.0, 0.0, 0.0, 0.09 - i * 0.015), true)

	# Paper background
	draw_rect(paper_rect, canvas_bg_color, true)

	# 3. Grid lines (restricted to Canvas Paper)
	var step: float = maxf(grid_step, 5.0)
	var sub_color: Color = Color(grid_color.r, grid_color.g, grid_color.b, 0.45)

	var draw_step: float = step
	while draw_step * zoom_level < 8.0:
		draw_step *= 2.0

	var cur_x: float = 0.0
	while cur_x <= canvas_size.x + 0.5:
		var sx: float = roundf(paper_origin.x + cur_x * zoom_level)
		if sx >= paper_rect.position.x - 1.0 and sx <= paper_rect.position.x + paper_rect.size.x + 1.0:
			var int_x: int = int(roundf(cur_x))
			var is_super_200: bool = (int_x % 200 == 0)
			var is_major_40: bool = (int_x % 40 == 0)
			var c: Color
			var lw: float
			if is_super_200:
				c = major_grid_color
				lw = 1.8
			elif is_major_40:
				c = major_grid_color
				lw = 1.2
			else:
				c = sub_color
				lw = 0.9
			draw_line(Vector2(sx, paper_rect.position.y), Vector2(sx, paper_rect.position.y + paper_rect.size.y), c, lw, true)
		cur_x += draw_step

	var cur_y: float = 0.0
	while cur_y <= canvas_size.y + 0.5:
		var sy: float = roundf(paper_origin.y + cur_y * zoom_level)
		if sy >= paper_rect.position.y - 1.0 and sy <= paper_rect.position.y + paper_rect.size.y + 1.0:
			var int_y: int = int(roundf(cur_y))
			var is_super_200: bool = (int_y % 200 == 0)
			var is_major_40: bool = (int_y % 40 == 0)
			var c: Color
			var lw: float
			if is_super_200:
				c = major_grid_color
				lw = 1.8
			elif is_major_40:
				c = major_grid_color
				lw = 1.2
			else:
				c = sub_color
				lw = 0.9
			draw_line(Vector2(paper_rect.position.x, sy), Vector2(paper_rect.position.x + paper_rect.size.x, sy), c, lw, true)
		cur_y += draw_step

	for item in challenge_guide:
		var pos: Vector2 = item["pos"]
		var a: Vector2 = world_to_canvas(pos + item["a"])
		var b: Vector2 = world_to_canvas(pos + item["b"])
		var c: Vector2 = world_to_canvas(pos + item["c"])
		var points: PackedVector2Array = PackedVector2Array([a, b, c])
		draw_colored_polygon(points, Color(0.15, 0.53, 0.9, 0.10))
		draw_polyline(PackedVector2Array([a, b, c, a]), Color(0.11, 0.42, 0.8, 0.55), 2.0, true)

	# Paper crisp border
	draw_rect(paper_rect, Color(0.28, 0.38, 0.55, 0.75), false, 1.5)

	# Paper dimension badge at top-left
	var font: Font = ThemeDB.fallback_font
	if font:
		var dim_str: String = "%d × %d px" % [int(canvas_size.x), int(canvas_size.y)]
		draw_string(font, paper_origin + Vector2(6.0, -8.0), dim_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.65, 0.75, 0.9, 0.8))

	# 4. Marquee selection rectangle (screen space)
	if is_marquee_selecting:
		var m_min: Vector2 = Vector2(minf(marquee_start.x, marquee_current.x), minf(marquee_start.y, marquee_current.y))
		var m_max: Vector2 = Vector2(maxf(marquee_start.x, marquee_current.x), maxf(marquee_start.y, marquee_current.y))
		var m_rect: Rect2 = Rect2(m_min, m_max - m_min)
		draw_rect(m_rect, Color(0.2, 0.5, 0.95, 0.15), true)
		draw_rect(m_rect, Color(0.25, 0.55, 0.95, 0.85), false, 1.5)

	# 5. Magnetic Snap Indicators (when touching edges or vertices!)
	if not active_snap_indicators.is_empty():
		if active_snap_indicators.size() >= 2:
			var p_a: Vector2 = world_to_canvas(active_snap_indicators[0])
			var p_b: Vector2 = world_to_canvas(active_snap_indicators[1])
			draw_line(p_a, p_b, Color(0.0, 0.85, 1.0, 0.9), 3.0)
		for pt in active_snap_indicators:
			var cpt: Vector2 = world_to_canvas(pt)
			draw_circle(cpt, 8.0, Color(0.0, 0.85, 1.0, 0.35))
			draw_arc(cpt, 5.5, 0.0, TAU, 16, Color(0.0, 0.95, 1.0, 0.95), 2.0)
			draw_circle(cpt, 2.5, Color.WHITE)

	# 6. Group / Multi-Selection Bounding Box & Group Rotation Handle
	if selected_triangles.size() > 1:
		_draw_group_selection_overlay()

func _draw_group_selection_overlay() -> void:
	var bbox: Rect2 = get_group_bounding_box()
	if bbox.size.x <= 0.0 and bbox.size.y <= 0.0:
		return

	# Add padding
	var pad: float = 8.0 / zoom_level
	var p_min: Vector2 = world_to_canvas(bbox.position - Vector2(pad, pad))
	var p_max: Vector2 = world_to_canvas(bbox.position + bbox.size + Vector2(pad, pad))
	var c_rect: Rect2 = Rect2(p_min, p_max - p_min)

	# 1. Subtle selection tinted fill and stroke
	draw_rect(c_rect, Color(0.18, 0.55, 0.95, 0.04), true)
	draw_rect(c_rect, Color(0.22, 0.58, 0.98, 0.75), false, 1.4)

	# 2. Corner Scale Handles (4 corners)
	var corner_world: Array[Vector2] = get_group_scale_corner_positions()
	var handle_size: float = 8.0
	var half_h: Vector2 = Vector2(handle_size * 0.5, handle_size * 0.5)
	for i in range(corner_world.size()):
		var c_pos: Vector2 = world_to_canvas(corner_world[i])
		var h_rect: Rect2 = Rect2(c_pos - half_h, Vector2(handle_size, handle_size))
		# Shadow
		draw_rect(Rect2(h_rect.position + Vector2(1, 1), h_rect.size), Color(0, 0, 0, 0.25), true)
		# White body
		draw_rect(h_rect, Color.WHITE, true)
		# Border (highlight if dragging this corner)
		var b_col: Color = Color(0.2, 0.55, 0.95, 1.0)
		if is_dragging_group_scale and drag_group_scale_corner_idx == i:
			b_col = Color(0.96, 0.82, 0.28, 1.0)
		draw_rect(h_rect, b_col, false, 1.5)

	# 2b. If currently dragging group scale, draw percentage badge
	if is_dragging_group_scale and drag_group_scale_corner_idx >= 0 and drag_group_scale_corner_idx < corner_world.size():
		var font: Font = ThemeDB.fallback_font
		var scale_pct: int = int(roundf(current_group_scale_factor * 100.0))
		var scale_text: String = "%d%%" % scale_pct
		var str_size: Vector2 = font.get_string_size(scale_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 13)
		var padding: Vector2 = Vector2(6, 3)
		var c_pos: Vector2 = world_to_canvas(corner_world[drag_group_scale_corner_idx])
		var badge_rect: Rect2 = Rect2(c_pos + Vector2(12, 12) - padding, str_size + padding * 2.0)
		draw_rect(badge_rect, Color(0.1, 0.15, 0.25, 0.95), true, -1.0)
		draw_rect(badge_rect, Color(0.96, 0.82, 0.28, 0.9), false, 1.2)
		var baseline: Vector2 = Vector2(badge_rect.position.x + padding.x, badge_rect.position.y + padding.y + font.get_ascent(13))
		draw_string(font, baseline, scale_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 13, Color(1, 1, 1, 0.95))

	# 3. Group Rotation Handle
	var group_rot_h_world: Vector2 = get_group_rotation_handle_pos()
	var is_at_bottom: bool = (group_rot_h_world.y > bbox.position.y + bbox.size.y * 0.5)
	var anchor_y: float = c_rect.position.y + c_rect.size.y if is_at_bottom else c_rect.position.y
	var anchor_mid: Vector2 = Vector2(c_rect.position.x + c_rect.size.x * 0.5, anchor_y)
	var rot_pos: Vector2 = world_to_canvas(group_rot_h_world)

	# Connecting stem line
	draw_line(anchor_mid, rot_pos, Color(0.2, 0.45, 0.85, 0.7), 1.6, true)

	# Outer halo
	draw_circle(rot_pos, 9.0, Color(0, 0, 0, 0.22))
	# White outer border
	draw_circle(rot_pos, 6.5, Color.WHITE)
	# Inner emerald green
	draw_circle(rot_pos, 4.5, Color(0.13, 0.75, 0.42, 1.0))
	# Center dot
	draw_circle(rot_pos, 2.0, Color.WHITE)

	# 4. If currently dragging rotation, draw degree badge and pivot indicator
	if is_dragging_group_rotation:
		# Pivot indicator at center of rotation
		var pivot_pos: Vector2 = world_to_canvas(drag_multi_group_center)
		draw_circle(pivot_pos, 6.0, Color(0.13, 0.75, 0.42, 0.25))
		draw_arc(pivot_pos, 4.5, 0.0, TAU, 16, Color(0.13, 0.75, 0.42, 0.95), 1.6)
		draw_circle(pivot_pos, 1.8, Color.WHITE)

		# Degree badge
		var font: Font = ThemeDB.fallback_font
		var deg_text: String = "%d°" % int(current_group_rotation_deg)
		var str_size: Vector2 = font.get_string_size(deg_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 13)
		var padding: Vector2 = Vector2(6, 3)
		var badge_rect: Rect2 = Rect2(rot_pos + Vector2(0, -22) - str_size / 2.0 - padding, str_size + padding * 2.0)
		draw_rect(badge_rect, Color(0.1, 0.15, 0.25, 0.95), true, -1.0)
		draw_rect(badge_rect, Color(0.13, 0.75, 0.42, 0.9), false, 1.2)
		var baseline: Vector2 = Vector2(badge_rect.position.x + padding.x, badge_rect.position.y + padding.y + font.get_ascent(13))
		draw_string(font, baseline, deg_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 13, Color(1, 1, 1, 0.95))
