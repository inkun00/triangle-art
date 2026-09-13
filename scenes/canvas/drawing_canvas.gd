class_name DrawingCanvas
extends Control

const TriangleMath = preload("res://scripts/core/triangle_math.gd")
const TriangleCommands = preload("res://scripts/core/triangle_commands.gd")
const TriangleNode = preload("res://scenes/triangle/triangle_node.gd")
const TriangleTemplates = preload("res://scripts/core/triangle_templates.gd")
const ProjectStorage = preload("res://scripts/core/project_storage.gd")
const SoundManager = preload("res://scripts/core/sound_manager.gd")

## Canvas managing grid rendering, triangle instances, and interaction dispatch.

signal selection_changed(node: TriangleNode)
signal multi_selection_changed(nodes: Array[TriangleNode])
signal triangle_geometry_updated(node: TriangleNode)
signal action_performed(command: Variant)
signal undo_requested
signal redo_requested
signal toast_requested(msg: String)
signal zoom_changed(zoom: float)
signal scale_lock_toggled(locked: bool)
signal canvas_size_changed(new_size: Vector2)

enum MenuAction {
	DUPLICATE = 1,
	DELETE = 2,
	EQUILATERAL = 3,
	GROUP = 4,
	UNGROUP = 5,
	ROTATE = 6,
	FLIP_H = 7,
	FLIP_V = 8,
	LAYER_UP = 9,
	LAYER_DOWN = 10,
	SCALE_UP = 11,
	SCALE_DOWN = 12,
	TOGGLE_SCALE_LOCK = 13,
	REMOVE_OUTLINE = 14,
	NEW_TRIANGLE = 100,
	UNDO = 101,
	REDO = 102,
	CLEAR_ALL = 103
}

@export var canvas_size: Vector2 = Vector2(1200, 800)
@export var grid_step: float = 40.0
@export var grid_color: Color = Color(0.82, 0.86, 0.93, 0.85)
@export var major_grid_color: Color = Color(0.66, 0.72, 0.83, 1.0)
@export var canvas_bg_color: Color = Color(0.97, 0.98, 1.0, 1.0)
@export var snap_enabled: bool = false:
	set(val):
		snap_enabled = val
		_update_snap_for_all()

@export var zoom_level: float = 1.0
@export var min_zoom: float = 0.25
@export var max_zoom: float = 4.0
var pan_offset: Vector2 = Vector2.ZERO
var is_panning: bool = false
var pan_start_mouse: Vector2 = Vector2.ZERO
var pan_start_offset: Vector2 = Vector2.ZERO

var touch_points: Dictionary = {}
var touch_start_dist: float = 0.0
var touch_start_zoom: float = 1.0
var touch_start_mid: Vector2 = Vector2.ZERO
var touch_start_pan: Vector2 = Vector2.ZERO

var is_scale_locked: bool = false
var active_snap_indicators: Array[Vector2] = []
var _was_snapped: bool = false

var triangles: Array[TriangleNode] = []
var selected_triangle: TriangleNode = null
var selected_triangles: Array[TriangleNode] = []
var active_interacting_triangle: TriangleNode = null
var show_guide: bool = false
var active_guide_name: String = "물고기 (Fish)"
var guide_triangles: Array[Dictionary] = []

var is_marquee_selecting: bool = false
var marquee_start: Vector2 = Vector2.ZERO
var marquee_current: Vector2 = Vector2.ZERO
var drag_multi_start_positions: Dictionary = {}

var is_dragging_group_rotation: bool = false
var drag_multi_group_center: Vector2 = Vector2.ZERO
var drag_multi_start_angle: float = 0.0
var drag_multi_start_mouse: Vector2 = Vector2.ZERO
var drag_multi_start_verts: Dictionary = {}
var drag_multi_start_centroids: Dictionary = {}
var current_group_rotation_deg: float = 0.0

var context_menu: PopupMenu = null
var last_right_click_pos: Vector2 = Vector2.ZERO

@onready var container: Node2D = $TrianglesContainer

func _ready() -> void:
	custom_minimum_size = Vector2(200, 200)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_setup_context_menu()
	resized.connect(_on_canvas_resized)
	await get_tree().process_frame
	fit_canvas_in_view()
	queue_redraw()

func _on_canvas_resized() -> void:
	center_canvas_in_view()
	_apply_zoom_and_pan()

func fit_canvas_in_view(margin: float = 30.0) -> void:
	if size.x > 0 and size.y > 0:
		var avail_w: float = maxf(size.x - margin * 2.0, 100.0)
		var avail_h: float = maxf(size.y - margin * 2.0, 100.0)
		var fit_zoom_x: float = avail_w / canvas_size.x
		var fit_zoom_y: float = avail_h / canvas_size.y
		var ideal_zoom: float = minf(fit_zoom_x, fit_zoom_y)
		zoom_level = clampf(minf(ideal_zoom, 1.0), min_zoom, max_zoom)
		center_canvas_in_view()
		_apply_zoom_and_pan()
	else:
		center_canvas_in_view()
		_apply_zoom_and_pan()

func set_canvas_size(new_size: Vector2) -> void:
	var clamped_size: Vector2 = Vector2(
		clampf(new_size.x, 300.0, 4096.0),
		clampf(new_size.y, 300.0, 4096.0)
	)
	if canvas_size != clamped_size:
		canvas_size = clamped_size
		canvas_size_changed.emit(canvas_size)
		if show_guide and not active_guide_name.is_empty():
			var center: Vector2 = canvas_size / 2.0
			guide_triangles = TriangleTemplates.get_template_data(active_guide_name, center)
		fit_canvas_in_view()
		queue_redraw()

func center_canvas_in_view() -> void:
	if size.x > 0 and size.y > 0:
		pan_offset = (size - canvas_size * zoom_level) / 2.0
	else:
		pan_offset = Vector2(40.0, 40.0)

func canvas_to_world(pos: Vector2) -> Vector2:
	return (pos - pan_offset) / zoom_level

func world_to_canvas(pos: Vector2) -> Vector2:
	return pan_offset + pos * zoom_level

func set_zoom(new_zoom: float, pivot_canvas_pos: Vector2 = Vector2.ZERO) -> void:
	if pivot_canvas_pos == Vector2.ZERO:
		pivot_canvas_pos = size / 2.0
	var clamped_zoom: float = clampf(new_zoom, min_zoom, max_zoom)
	var world_mouse: Vector2 = (pivot_canvas_pos - pan_offset) / zoom_level
	pan_offset = pivot_canvas_pos - world_mouse * clamped_zoom
	zoom_level = clamped_zoom
	_apply_zoom_and_pan()

func reset_zoom() -> void:
	fit_canvas_in_view()

func _apply_zoom_and_pan() -> void:
	if container:
		container.position = pan_offset
		container.scale = Vector2(zoom_level, zoom_level)
	for t in triangles:
		if is_instance_valid(t):
			t.zoom_level = zoom_level
	zoom_changed.emit(zoom_level)
	queue_redraw()

func set_scale_locked(val: bool) -> void:
	is_scale_locked = val
	for t in triangles:
		if is_instance_valid(t):
			t.is_scale_locked = is_scale_locked
	scale_lock_toggled.emit(is_scale_locked)

func _update_snap_for_all() -> void:
	for t in triangles:
		t.snap_enabled = snap_enabled

func add_triangle_node(triangle: TriangleNode) -> void:
	if not triangles.has(triangle):
		triangles.append(triangle)
		container.add_child(triangle)
		triangle.grid_step = grid_step
		triangle.snap_enabled = snap_enabled
		triangle.is_scale_locked = is_scale_locked
		triangle.zoom_level = zoom_level
		triangle.action_committed.connect(_on_triangle_action_committed)
		triangle.geometry_changed.connect(_on_triangle_geometry_changed)
	select_triangle(triangle)
	queue_redraw()

func remove_triangle_node(triangle: TriangleNode) -> void:
	if triangles.has(triangle):
		triangles.erase(triangle)
		if triangle.action_committed.is_connected(_on_triangle_action_committed):
			triangle.action_committed.disconnect(_on_triangle_action_committed)
		if triangle.geometry_changed.is_connected(_on_triangle_geometry_changed):
			triangle.geometry_changed.disconnect(_on_triangle_geometry_changed)
		if triangle.get_parent() == container:
			container.remove_child(triangle)
		if selected_triangle == triangle:
			select_triangle(null)
	queue_redraw()

func set_grid_step(new_step: float) -> void:
	grid_step = maxf(new_step, 5.0)
	for t in triangles:
		t.grid_step = grid_step
	queue_redraw()

func select_triangle(triangle: TriangleNode, add_to_selection: bool = false) -> void:
	if triangle == null:
		for t in selected_triangles:
			if is_instance_valid(t):
				t.set_selected(false)
		selected_triangles.clear()
		selected_triangle = null
		_update_selection_handles()
		selection_changed.emit(null)
		multi_selection_changed.emit(selected_triangles)
		queue_redraw()
		return

	# If triangle is in a group, include all group members!
	var group_members: Array[TriangleNode] = []
	if not triangle.group_id.is_empty():
		for t in triangles:
			if is_instance_valid(t) and t.group_id == triangle.group_id:
				group_members.append(t)
	else:
		group_members.append(triangle)

	if not add_to_selection:
		for t in selected_triangles:
			if is_instance_valid(t) and not group_members.has(t):
				t.set_selected(false)
		selected_triangles = group_members.duplicate()
	else:
		for m in group_members:
			if not selected_triangles.has(m):
				selected_triangles.append(m)

	for t in selected_triangles:
		if is_instance_valid(t):
			t.set_selected(true)

	selected_triangle = triangle
	_update_selection_handles()
	selection_changed.emit(selected_triangle)
	multi_selection_changed.emit(selected_triangles)
	queue_redraw()

func select_triangles(list: Array[TriangleNode]) -> void:
	var expanded: Array[TriangleNode] = []
	for t in list:
		if not is_instance_valid(t):
			continue
		if not t.group_id.is_empty():
			for other in triangles:
				if is_instance_valid(other) and other.group_id == t.group_id:
					if not expanded.has(other):
						expanded.append(other)
		else:
			if not expanded.has(t):
				expanded.append(t)

	for t in selected_triangles:
		if is_instance_valid(t) and not expanded.has(t):
			t.set_selected(false)

	selected_triangles = expanded.duplicate()
	for t in selected_triangles:
		if is_instance_valid(t):
			t.set_selected(true)

	selected_triangle = selected_triangles.back() if not selected_triangles.is_empty() else null
	_update_selection_handles()
	selection_changed.emit(selected_triangle)
	multi_selection_changed.emit(selected_triangles)
	queue_redraw()

func _update_selection_handles() -> void:
	var is_multi: bool = selected_triangles.size() > 1
	for t in triangles:
		if is_instance_valid(t):
			var should_hide: bool = is_multi and selected_triangles.has(t)
			if t.hide_rotation_handle != should_hide:
				t.hide_rotation_handle = should_hide
				t.queue_redraw()

func get_group_bounding_box() -> Rect2:
	if selected_triangles.is_empty():
		return Rect2()
	var min_pt: Vector2 = Vector2(INF, INF)
	var max_pt: Vector2 = Vector2(-INF, -INF)
	for t in selected_triangles:
		if is_instance_valid(t):
			var pts: Array[Vector2] = [
				t.position + t.vertex_a,
				t.position + t.vertex_b,
				t.position + t.vertex_c
			]
			for p in pts:
				min_pt.x = minf(min_pt.x, p.x)
				min_pt.y = minf(min_pt.y, p.y)
				max_pt.x = maxf(max_pt.x, p.x)
				max_pt.y = maxf(max_pt.y, p.y)
	if min_pt.x == INF:
		return Rect2()
	return Rect2(min_pt, max_pt - min_pt)

func get_group_center() -> Vector2:
	if selected_triangles.is_empty():
		return Vector2.ZERO
	var center: Vector2 = Vector2.ZERO
	var count: int = 0
	for t in selected_triangles:
		if is_instance_valid(t):
			center += t.position + t.get_centroid()
			count += 1
	return center / float(maxi(count, 1))

func get_group_rotation_handle_pos() -> Vector2:
	var bbox: Rect2 = get_group_bounding_box()
	var handle_x: float = bbox.position.x + bbox.size.x * 0.5
	var offset: float = 28.0 / zoom_level
	var handle_y: float = bbox.position.y - offset
	if handle_y < 25.0 / zoom_level:
		handle_y = bbox.position.y + bbox.size.y + offset
	return Vector2(handle_x, handle_y)

func hit_test_group_rotation_handle(world_point: Vector2) -> bool:
	if selected_triangles.size() <= 1:
		return false
	var handle_pos: Vector2 = get_group_rotation_handle_pos()
	var hit_radius: float = 16.0 / zoom_level
	return world_point.distance_to(handle_pos) <= hit_radius

func _start_group_rotation_drag(world_pos: Vector2) -> void:
	is_dragging_group_rotation = true
	drag_multi_group_center = get_group_center()
	drag_multi_start_mouse = world_pos
	drag_multi_start_angle = (world_pos - drag_multi_group_center).angle()
	current_group_rotation_deg = 0.0
	drag_multi_start_positions.clear()
	drag_multi_start_verts.clear()
	drag_multi_start_centroids.clear()

	for t in selected_triangles:
		if is_instance_valid(t):
			drag_multi_start_positions[t] = t.position
			drag_multi_start_verts[t] = [t.vertex_a, t.vertex_b, t.vertex_c]
			drag_multi_start_centroids[t] = t.get_centroid()

func group_selected() -> void:
	if selected_triangles.size() < 2:
		return
	var gid: String = "group_%d_%d" % [Time.get_ticks_msec(), randi() % 10000]
	var cmd = TriangleCommands.GroupCommand.new(self, selected_triangles, gid)
	action_performed.emit(cmd)
	multi_selection_changed.emit(selected_triangles)
	queue_redraw()

func ungroup_selected() -> void:
	var to_ungroup: Array[TriangleNode] = []
	for t in selected_triangles:
		if is_instance_valid(t) and not t.group_id.is_empty():
			to_ungroup.append(t)
	if to_ungroup.is_empty():
		return
	var cmd = TriangleCommands.UngroupCommand.new(self, to_ungroup)
	action_performed.emit(cmd)
	multi_selection_changed.emit(selected_triangles)
	queue_redraw()

func has_group_in_selection() -> bool:
	for t in selected_triangles:
		if is_instance_valid(t) and not t.group_id.is_empty():
			return true
	return false

func add_new_equilateral_triangle(center_pos: Vector2 = Vector2.ZERO) -> TriangleNode:
	if center_pos == Vector2.ZERO:
		center_pos = canvas_size / 2.0
		if snap_enabled:
			center_pos = TriangleMath.snap_point(center_pos, grid_step)

	var new_node: TriangleNode = TriangleNode.new()

	var side_len: float = maxf(grid_step * 3.0, 100.0)
	var verts = TriangleMath.create_equilateral_vertices(side_len, Vector2.ZERO)
	new_node.vertex_a = verts[0]
	new_node.vertex_b = verts[1]
	new_node.vertex_c = verts[2]
	new_node.position = center_pos
	new_node.fill_color = Color(0.25, 0.55, 0.95, 0.88)

	var cmd = TriangleCommands.CreateCommand.new(self, new_node)
	action_performed.emit(cmd)
	if SoundManager.instance:
		SoundManager.instance.play_create()
	return new_node

func make_selected_equilateral() -> void:
	if not selected_triangle or not is_instance_valid(selected_triangle):
		return
	var t: TriangleNode = selected_triangle
	var centroid: Vector2 = t.get_centroid()
	var sides = TriangleMath.get_side_lengths_px(t.vertex_a, t.vertex_b, t.vertex_c)
	var avg_side: float = (sides["ab"] + sides["bc"] + sides["ca"]) / 3.0
	if snap_enabled:
		avg_side = maxf(roundf(avg_side / grid_step) * grid_step, grid_step * 2.0)
	else:
		avg_side = maxf(avg_side, 40.0)

	var old_verts: Array[Vector2] = [t.vertex_a, t.vertex_b, t.vertex_c]
	var new_verts: Array[Vector2] = TriangleMath.create_equilateral_vertices(avg_side, centroid)
	var cmd = TriangleCommands.TransformVerticesCommand.new(t, old_verts, new_verts)
	action_performed.emit(cmd)
	queue_redraw()

func duplicate_selected() -> Array:
	if selected_triangles.is_empty():
		return []

	# Map each existing group_id in selection to a new unique group_id for the clones
	var group_map: Dictionary = {}
	for t in selected_triangles:
		if is_instance_valid(t) and not t.group_id.is_empty():
			if not group_map.has(t.group_id):
				group_map[t.group_id] = "grp_" + str(Time.get_ticks_usec()) + "_" + str(randi() % 10000)

	var clones: Array[TriangleNode] = []
	for t in selected_triangles:
		if is_instance_valid(t):
			var clone: TriangleNode = t.clone_triangle()
			if not t.group_id.is_empty():
				clone.group_id = group_map.get(t.group_id, "")
			if clone.position.x > canvas_size.x - 40:
				clone.position.x = canvas_size.x / 2.0
			if clone.position.y > canvas_size.y - 40:
				clone.position.y = canvas_size.y / 2.0
			clones.append(clone)

	var cmd = TriangleCommands.BatchCreateCommand.new(self, clones)
	action_performed.emit(cmd)
	select_triangles(clones)
	if SoundManager.instance:
		SoundManager.instance.play_create()
	return clones

func delete_selected() -> void:
	if selected_triangles.is_empty():
		return
	var cmd = TriangleCommands.BatchDeleteCommand.new(self, selected_triangles)
	action_performed.emit(cmd)
	select_triangle(null)
	if SoundManager.instance:
		SoundManager.instance.play_delete()

func preview_selected_color(col: Color) -> void:
	for t in selected_triangles:
		if is_instance_valid(t):
			t.fill_color = col
			t.queue_redraw()

func set_selected_color(col: Color, saved_old_colors: Dictionary = {}) -> void:
	if selected_triangles.is_empty():
		return
	var cmd = TriangleCommands.MultiColorCommand.new(selected_triangles, col, saved_old_colors)
	action_performed.emit(cmd)

func preview_selected_outline_color(col: Color) -> void:
	for t in selected_triangles:
		if is_instance_valid(t):
			t.outline_color = col
			t.queue_redraw()

func set_selected_outline_color(col: Color, saved_old_colors: Dictionary = {}) -> void:
	if selected_triangles.is_empty():
		return
	var cmd = TriangleCommands.MultiOutlineColorCommand.new(selected_triangles, col, saved_old_colors)
	action_performed.emit(cmd)

func remove_selected_outline() -> void:
	set_selected_outline_color(Color(0, 0, 0, 0))

func bring_forward() -> void:
	if not selected_triangle:
		return
	var old_idx: int = container.get_children().find(selected_triangle)
	var max_idx: int = container.get_child_count() - 1
	if old_idx < max_idx:
		var new_idx: int = old_idx + 1
		var cmd = TriangleCommands.LayerCommand.new(self, selected_triangle, old_idx, new_idx)
		action_performed.emit(cmd)

func send_backward() -> void:
	if not selected_triangle:
		return
	var old_idx: int = container.get_children().find(selected_triangle)
	if old_idx > 0:
		var new_idx: int = old_idx - 1
		var cmd = TriangleCommands.LayerCommand.new(self, selected_triangle, old_idx, new_idx)
		action_performed.emit(cmd)

func set_triangle_index(triangle: TriangleNode, new_index: int) -> void:
	if triangle.get_parent() == container:
		var clamped_idx: int = clampi(new_index, 0, container.get_child_count() - 1)
		container.move_child(triangle, clamped_idx)
		queue_redraw()

func clear_all_triangles() -> void:
	if triangles.is_empty():
		return
	var cmd = TriangleCommands.ClearAllCommand.new(self, triangles)
	action_performed.emit(cmd)

func load_template_triangles(template_name: String) -> void:
	var center: Vector2 = canvas_size / 2.0
	var raw_data: Array[Dictionary] = TriangleTemplates.get_template_data(template_name, center)
	if raw_data.is_empty():
		return

	var new_nodes: Array = []
	for item in raw_data:
		var node: TriangleNode = TriangleNode.new()
		node.position = item["pos"]
		node.vertex_a = item["a"]
		node.vertex_b = item["b"]
		node.vertex_c = item["c"]
		node.fill_color = item["color"]
		new_nodes.append(node)

	var cmd = TriangleCommands.BatchCreateCommand.new(self, new_nodes)
	action_performed.emit(cmd)
	if not new_nodes.is_empty():
		select_triangle(new_nodes[new_nodes.size() - 1])

func scale_selected(factor: float) -> void:
	if selected_triangles.size() > 1:
		var group_center: Vector2 = get_group_center()
		var starts: Dictionary = {}
		var ends: Dictionary = {}
		var pos_starts: Dictionary = {}
		var pos_ends: Dictionary = {}
		for t in selected_triangles:
			if is_instance_valid(t):
				var old_verts: Array[Vector2] = [t.vertex_a, t.vertex_b, t.vertex_c]
				var local_c: Vector2 = t.get_centroid()
				var world_c: Vector2 = t.position + local_c
				var new_world_c: Vector2 = group_center + (world_c - group_center) * factor
				var new_pos: Vector2 = new_world_c - local_c * factor

				var new_verts = TriangleMath.scale_vertices_proportional(old_verts, factor, local_c)
				if TriangleMath.is_valid_triangle(new_verts[0], new_verts[1], new_verts[2], 10.0):
					starts[t] = old_verts
					ends[t] = new_verts
					pos_starts[t] = t.position
					pos_ends[t] = new_pos
					t.position = new_pos
					t.vertex_a = new_verts[0]
					t.vertex_b = new_verts[1]
					t.vertex_c = new_verts[2]
					t.geometry_changed.emit(t)
					t.queue_redraw()
		if not ends.is_empty():
			var cmd = TriangleCommands.MultiTransformVerticesCommand.new(selected_triangles, starts, ends, pos_starts, pos_ends)
			action_performed.emit(cmd)
			queue_redraw()
	elif selected_triangle and is_instance_valid(selected_triangle):
		selected_triangle.scale_by_ratio(factor)
		queue_redraw()

func _on_triangle_action_committed(cmd: Variant) -> void:
	action_performed.emit(cmd)

func _on_triangle_geometry_changed(node: TriangleNode) -> void:
	if node == selected_triangle:
		triangle_geometry_updated.emit(node)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event
		if st.pressed:
			touch_points[st.index] = st.position
			if touch_points.size() == 2:
				var keys = touch_points.keys()
				var p0: Vector2 = touch_points[keys[0]]
				var p1: Vector2 = touch_points[keys[1]]
				touch_start_dist = maxf(p0.distance_to(p1), 10.0)
				touch_start_zoom = zoom_level
				touch_start_mid = (p0 + p1) / 2.0
				touch_start_pan = pan_offset
		else:
			touch_points.erase(st.index)
			if touch_points.size() < 2:
				touch_start_dist = 0.0

	elif event is InputEventScreenDrag:
		var sd: InputEventScreenDrag = event
		touch_points[sd.index] = sd.position
		if touch_points.size() >= 2:
			var keys = touch_points.keys()
			var p0: Vector2 = touch_points[keys[0]]
			var p1: Vector2 = touch_points[keys[1]]
			var cur_dist: float = maxf(p0.distance_to(p1), 10.0)
			var cur_mid: Vector2 = (p0 + p1) / 2.0
			pan_offset = touch_start_pan + (cur_mid - touch_start_mid)
			if touch_start_dist > 0.0:
				var ratio: float = cur_dist / touch_start_dist
				set_zoom(touch_start_zoom * ratio, cur_mid)
			else:
				_apply_zoom_and_pan()
			accept_event()
			return

	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		var local_pos: Vector2 = mb.position
		var is_shift: bool = mb.shift_pressed or mb.ctrl_pressed

		# 1. Mouse wheel zoom centered at cursor
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			set_zoom(zoom_level * 1.15, local_pos)
			accept_event()
			return
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			set_zoom(zoom_level / 1.15, local_pos)
			accept_event()
			return

		# 2. Middle mouse button panning
		if mb.button_index == MOUSE_BUTTON_MIDDLE:
			if mb.pressed:
				is_panning = true
				pan_start_mouse = local_pos
				pan_start_offset = pan_offset
			else:
				is_panning = false
			accept_event()
			return

		var world_pos: Vector2 = canvas_to_world(local_pos)

		if mb.button_index == MOUSE_BUTTON_LEFT:
			# Space + Left Click Pan
			if Input.is_key_pressed(KEY_SPACE):
				if mb.pressed:
					is_panning = true
					pan_start_mouse = local_pos
					pan_start_offset = pan_offset
				else:
					is_panning = false
				accept_event()
				return

			if mb.pressed:
				_handle_mouse_press(world_pos, is_shift, local_pos)
			else:
				_handle_mouse_release(world_pos, local_pos)
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			_handle_right_click(world_pos, mb.global_position)
			accept_event()

	elif event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event
		var local_pos: Vector2 = mm.position

		if is_panning:
			pan_offset = pan_start_offset + (local_pos - pan_start_mouse)
			_apply_zoom_and_pan()
			accept_event()
			return

		var world_mouse: Vector2 = canvas_to_world(local_pos)

		if is_marquee_selecting:
			marquee_current = local_pos
			queue_redraw()
			accept_event()
		elif is_dragging_group_rotation:
			var cur_angle: float = (world_mouse - drag_multi_group_center).angle()
			var delta_rad: float = cur_angle - drag_multi_start_angle
			if snap_enabled:
				var deg: float = rad_to_deg(delta_rad)
				deg = roundf(deg / 15.0) * 15.0
				delta_rad = deg_to_rad(deg)
			var prev_rot: float = current_group_rotation_deg
			current_group_rotation_deg = roundf(rad_to_deg(delta_rad))
			if prev_rot != current_group_rotation_deg and SoundManager.instance:
				SoundManager.instance.play_rotate_tick()

			for t in selected_triangles:
				if is_instance_valid(t) and drag_multi_start_positions.has(t):
					var start_pos: Vector2 = drag_multi_start_positions[t]
					var raw_verts: Array = drag_multi_start_verts[t]
					var start_verts: Array[Vector2] = [raw_verts[0], raw_verts[1], raw_verts[2]]
					var local_c: Vector2 = drag_multi_start_centroids[t]
					var world_c_0: Vector2 = start_pos + local_c
					var new_world_c: Vector2 = drag_multi_group_center + (world_c_0 - drag_multi_group_center).rotated(delta_rad)
					t.position = new_world_c - local_c

					var new_verts: Array[Vector2] = TriangleMath.rotate_vertices(start_verts, delta_rad, local_c)
					t.vertex_a = new_verts[0]
					t.vertex_b = new_verts[1]
					t.vertex_c = new_verts[2]

					t.geometry_changed.emit(t)
					t.queue_redraw()

			queue_redraw()
			accept_event()
		elif active_interacting_triangle and is_instance_valid(active_interacting_triangle):
			if active_interacting_triangle.current_drag == TriangleNode.DragMode.BODY and selected_triangles.size() > 1:
				var delta: Vector2 = world_mouse - active_interacting_triangle.drag_start_mouse
				for st in selected_triangles:
					if is_instance_valid(st) and drag_multi_start_positions.has(st):
						var raw_pos: Vector2 = drag_multi_start_positions[st] + delta
						st.position = TriangleMath.snap_point(raw_pos, grid_step) if snap_enabled else raw_pos

				var other_candidates: Array[TriangleNode] = []
				for t in triangles:
					if not selected_triangles.has(t) and is_instance_valid(t):
						other_candidates.append(t)
				var snap_res = TriangleMath.find_inter_triangle_snap(active_interacting_triangle, other_candidates, 14.0 / zoom_level)
				if snap_res["snapped"]:
					var s_offset: Vector2 = snap_res["offset"]
					for st in selected_triangles:
						if is_instance_valid(st):
							st.position += s_offset
					active_snap_indicators = snap_res["snap_points"]
					if not _was_snapped:
						if SoundManager.instance:
							SoundManager.instance.play_snap()
						_was_snapped = true
				else:
					active_snap_indicators.clear()
					_was_snapped = false

				for st in selected_triangles:
					if is_instance_valid(st):
						st.geometry_changed.emit(st)
						st.queue_redraw()
			elif active_interacting_triangle.current_drag == TriangleNode.DragMode.BODY:
				active_interacting_triangle.handle_input_drag(world_mouse)
				var snap_res = TriangleMath.find_inter_triangle_snap(active_interacting_triangle, triangles, 14.0 / zoom_level)
				if snap_res["snapped"]:
					active_interacting_triangle.position += snap_res["offset"]
					active_snap_indicators = snap_res["snap_points"]
					active_interacting_triangle.geometry_changed.emit(active_interacting_triangle)
					active_interacting_triangle.queue_redraw()
					if not _was_snapped:
						if SoundManager.instance:
							SoundManager.instance.play_snap()
						_was_snapped = true
				else:
					active_snap_indicators.clear()
					_was_snapped = false
			elif active_interacting_triangle.current_drag in [TriangleNode.DragMode.VERTEX_A, TriangleNode.DragMode.VERTEX_B, TriangleNode.DragMode.VERTEX_C]:
				var lock_scale: bool = is_scale_locked or active_interacting_triangle.is_scale_locked or Input.is_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_ALT)
				if not lock_scale:
					var v_snap = TriangleMath.find_vertex_snap(world_mouse, active_interacting_triangle, triangles, 14.0 / zoom_level)
					if v_snap["snapped"]:
						active_interacting_triangle.handle_input_drag(v_snap["snapped_pos"])
						active_snap_indicators = v_snap["snap_points"]
						if not _was_snapped:
							if SoundManager.instance:
								SoundManager.instance.play_snap()
							_was_snapped = true
					else:
						active_interacting_triangle.handle_input_drag(world_mouse)
						active_snap_indicators.clear()
						_was_snapped = false
				else:
					active_interacting_triangle.handle_input_drag(world_mouse)
					active_snap_indicators.clear()
					_was_snapped = false
			else:
				active_interacting_triangle.handle_input_drag(world_mouse)
				active_snap_indicators.clear()

			queue_redraw()
			accept_event()
		else:
			_update_hover_cursor(world_mouse)

func _update_hover_cursor(world_mouse: Vector2) -> void:
	if is_dragging_group_rotation or (active_interacting_triangle and active_interacting_triangle.current_drag == TriangleNode.DragMode.ROTATION):
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		return
	if active_interacting_triangle and active_interacting_triangle.current_drag == TriangleNode.DragMode.BODY:
		mouse_default_cursor_shape = Control.CURSOR_MOVE
		return
	if active_interacting_triangle and active_interacting_triangle.current_drag in [TriangleNode.DragMode.VERTEX_A, TriangleNode.DragMode.VERTEX_B, TriangleNode.DragMode.VERTEX_C]:
		mouse_default_cursor_shape = Control.CURSOR_CROSS
		return

	if selected_triangles.size() > 1 and hit_test_group_rotation_handle(world_mouse):
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		return
	if selected_triangle and is_instance_valid(selected_triangle):
		if selected_triangle.hit_test_rotation_handle(world_mouse):
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			return
		if selected_triangle.hit_test_handle(world_mouse) != -1:
			mouse_default_cursor_shape = Control.CURSOR_CROSS
			return
		if selected_triangle.hit_test_body(world_mouse):
			mouse_default_cursor_shape = Control.CURSOR_MOVE
			return
	for st in selected_triangles:
		if is_instance_valid(st) and st.hit_test_body(world_mouse):
			mouse_default_cursor_shape = Control.CURSOR_MOVE
			return
	mouse_default_cursor_shape = Control.CURSOR_ARROW

func _setup_context_menu() -> void:
	context_menu = PopupMenu.new()
	context_menu.name = "CanvasContextMenu"
	context_menu.id_pressed.connect(_on_context_menu_id_pressed)
	add_child(context_menu)

func _handle_right_click(world_pos: Vector2, global_pos: Vector2) -> void:
	last_right_click_pos = world_pos

	# 1. Check if clicked inside an already selected triangle
	var clicked_selected: bool = false
	for st in selected_triangles:
		if is_instance_valid(st) and st.hit_test_body(world_pos):
			clicked_selected = true
			break

	if not clicked_selected:
		# Check other triangles (top to bottom)
		var hit_triangle: TriangleNode = null
		for i in range(triangles.size() - 1, -1, -1):
			var t: TriangleNode = triangles[i]
			if is_instance_valid(t) and t.hit_test_body(world_pos):
				hit_triangle = t
				break
		if hit_triangle:
			select_triangle(hit_triangle)
		else:
			select_triangle(null)

	_show_context_menu(global_pos)

func _show_context_menu(global_pos: Vector2) -> void:
	if not context_menu:
		return
	context_menu.clear()

	var has_sel: bool = not selected_triangles.is_empty()

	if has_sel:
		context_menu.add_item("복제 (Ctrl+D)", MenuAction.DUPLICATE)
		context_menu.add_item("삭제 (Delete)", MenuAction.DELETE)
		context_menu.add_item("정삼각형화", MenuAction.EQUILATERAL)
		context_menu.add_separator()

		var can_group: bool = selected_triangles.size() >= 2
		var can_ungroup: bool = has_group_in_selection()

		context_menu.add_item("그룹화 (Ctrl+G)", MenuAction.GROUP)
		context_menu.set_item_disabled(context_menu.get_item_count() - 1, not can_group)

		context_menu.add_item("그룹 해제 (Ctrl+Shift+G)", MenuAction.UNGROUP)
		context_menu.set_item_disabled(context_menu.get_item_count() - 1, not can_ungroup)
		context_menu.add_separator()

		context_menu.add_item("회전 45°", MenuAction.ROTATE)
		context_menu.add_item("좌우 반전", MenuAction.FLIP_H)
		context_menu.add_item("상하 반전", MenuAction.FLIP_V)
		context_menu.add_separator()

		context_menu.add_item("앞으로 가져오기", MenuAction.LAYER_UP)
		context_menu.add_item("뒤로 보내기", MenuAction.LAYER_DOWN)
		context_menu.add_separator()

		context_menu.add_item("크기 확대 (+20%)", MenuAction.SCALE_UP)
		context_menu.add_item("크기 축소 (-20%)", MenuAction.SCALE_DOWN)
		context_menu.add_item("비율 고정: " + ("켜짐" if is_scale_locked else "꺼짐"), MenuAction.TOGGLE_SCALE_LOCK)
		context_menu.add_separator()
		context_menu.add_item("✕ 테두리 삭제 (외곽선 없음)", MenuAction.REMOVE_OUTLINE)
	else:
		context_menu.add_item("+ 새 정삼각형 생성", MenuAction.NEW_TRIANGLE)
		context_menu.add_separator()
		context_menu.add_item("실행 취소 (Ctrl+Z)", MenuAction.UNDO)
		context_menu.add_item("다시 실행 (Ctrl+Y)", MenuAction.REDO)
		context_menu.add_separator()
		context_menu.add_item("캔버스 전체 삭제", MenuAction.CLEAR_ALL)

	context_menu.reset_size()
	context_menu.popup(Rect2i(Vector2i(global_pos), Vector2i.ZERO))

func _on_context_menu_id_pressed(id: int) -> void:
	match id:
		MenuAction.DUPLICATE:
			duplicate_selected()
			toast_requested.emit("삼각형이 복제되었습니다 (복제).")
		MenuAction.DELETE:
			delete_selected()
			toast_requested.emit("삼각형이 삭제되었습니다 (삭제).")
		MenuAction.EQUILATERAL:
			make_selected_equilateral()
			toast_requested.emit("정삼각형으로 변환되었습니다.")
		MenuAction.GROUP:
			group_selected()
			toast_requested.emit("선택한 삼각형들이 그룹화되었습니다 (그룹화).")
		MenuAction.UNGROUP:
			ungroup_selected()
			toast_requested.emit("삼각형 그룹이 해제되었습니다 (그룹 해제).")
		MenuAction.ROTATE:
			rotate_selected(45.0)
			toast_requested.emit("삼각형을 45° 회전했습니다.")
		MenuAction.FLIP_H:
			flip_selected_h()
			toast_requested.emit("삼각형을 좌우 반전했습니다.")
		MenuAction.FLIP_V:
			flip_selected_v()
			toast_requested.emit("삼각형을 상하 반전했습니다.")
		MenuAction.LAYER_UP:
			bring_forward()
			toast_requested.emit("삼각형을 한 단계 앞으로 가져왔습니다.")
		MenuAction.LAYER_DOWN:
			send_backward()
			toast_requested.emit("삼각형을 한 단계 뒤로 보냈습니다.")
		MenuAction.SCALE_UP:
			scale_selected(1.2)
			toast_requested.emit("삼각형 크기를 20% 확대했습니다.")
		MenuAction.SCALE_DOWN:
			scale_selected(0.8)
			toast_requested.emit("삼각형 크기를 20% 축소했습니다.")
		MenuAction.TOGGLE_SCALE_LOCK:
			set_scale_locked(!is_scale_locked)
			toast_requested.emit("삼각형 비율 고정: " + ("켜짐" if is_scale_locked else "꺼짐"))
		MenuAction.REMOVE_OUTLINE:
			remove_selected_outline()
			toast_requested.emit("테두리가 삭제되었습니다 (테두리 없음).")
		MenuAction.NEW_TRIANGLE:
			var target_pos: Vector2 = last_right_click_pos
			if snap_enabled:
				target_pos = TriangleMath.snap_point(target_pos, grid_step)
			add_new_equilateral_triangle(target_pos)
			toast_requested.emit("클릭한 위치에 새 정삼각형이 생성되었습니다.")
		MenuAction.UNDO:
			undo_requested.emit()
		MenuAction.REDO:
			redo_requested.emit()
		MenuAction.CLEAR_ALL:
			clear_all_triangles()
			toast_requested.emit("캔버스를 모두 비웠습니다.")

func _handle_mouse_press(world_pos: Vector2, is_shift: bool = false, local_pos: Vector2 = Vector2.ZERO) -> void:
	drag_multi_start_positions.clear()
	active_snap_indicators.clear()

	# 0. Check group rotation handle first if multi-selected
	if selected_triangles.size() > 1 and hit_test_group_rotation_handle(world_pos):
		_start_group_rotation_drag(world_pos)
		queue_redraw()
		return

	# 1. First check if any already selected triangle handle or body was clicked
	for st in selected_triangles:
		if is_instance_valid(st) and st.handle_input_press(world_pos):
			active_interacting_triangle = st
			selected_triangle = st
			if selected_triangles.size() > 1:
				if st.current_drag == TriangleNode.DragMode.ROTATION:
					st.current_drag = TriangleNode.DragMode.NONE
					_start_group_rotation_drag(world_pos)
					queue_redraw()
					return
				elif st.current_drag == TriangleNode.DragMode.BODY:
					for t in selected_triangles:
						drag_multi_start_positions[t] = t.position
			queue_redraw()
			return

	# 2. Iterate from top to bottom through other triangles
	for i in range(triangles.size() - 1, -1, -1):
		var t: TriangleNode = triangles[i]
		if not selected_triangles.has(t) and is_instance_valid(t):
			if t.handle_input_press(world_pos):
				select_triangle(t, is_shift)
				active_interacting_triangle = t
				if selected_triangles.size() > 1:
					if t.current_drag == TriangleNode.DragMode.ROTATION:
						t.current_drag = TriangleNode.DragMode.NONE
						_start_group_rotation_drag(world_pos)
						queue_redraw()
						return
					elif t.current_drag == TriangleNode.DragMode.BODY:
						for st in selected_triangles:
							drag_multi_start_positions[st] = st.position
				queue_redraw()
				return

	# 3. Clicked on blank canvas -> deselect unless shift
	if not is_shift:
		select_triangle(null)

	is_marquee_selecting = true
	marquee_start = local_pos
	marquee_current = local_pos
	active_interacting_triangle = null
	queue_redraw()

func _handle_mouse_release(world_pos: Vector2, local_pos: Vector2 = Vector2.ZERO) -> void:
	active_snap_indicators.clear()

	if is_dragging_group_rotation:
		is_dragging_group_rotation = false
		if absf(current_group_rotation_deg) > 0.05:
			var starts: Dictionary = drag_multi_start_verts.duplicate()
			var pos_starts: Dictionary = drag_multi_start_positions.duplicate()
			var ends: Dictionary = {}
			var pos_ends: Dictionary = {}
			for t in selected_triangles:
				if is_instance_valid(t):
					ends[t] = [t.vertex_a, t.vertex_b, t.vertex_c]
					pos_ends[t] = t.position
			var cmd = TriangleCommands.MultiTransformVerticesCommand.new(selected_triangles, starts, ends, pos_starts, pos_ends)
			action_performed.emit(cmd)
		drag_multi_start_positions.clear()
		drag_multi_start_verts.clear()
		drag_multi_start_centroids.clear()
		current_group_rotation_deg = 0.0
		queue_redraw()
		return

	if is_marquee_selecting:
		is_marquee_selecting = false
		var m_min: Vector2 = Vector2(minf(marquee_start.x, marquee_current.x), minf(marquee_start.y, marquee_current.y))
		var m_max: Vector2 = Vector2(maxf(marquee_start.x, marquee_current.x), maxf(marquee_start.y, marquee_current.y))
		var w_min: Vector2 = canvas_to_world(m_min)
		var w_max: Vector2 = canvas_to_world(m_max)
		var w_rect: Rect2 = Rect2(w_min, w_max - w_min)

		if w_rect.size.x > 5.0 and w_rect.size.y > 5.0:
			var newly_selected: Array[TriangleNode] = []
			for t in triangles:
				if is_instance_valid(t):
					var c: Vector2 = t.position + t.get_centroid()
					var va: Vector2 = t.position + t.vertex_a
					var vb: Vector2 = t.position + t.vertex_b
					var vc: Vector2 = t.position + t.vertex_c
					if w_rect.has_point(c) or w_rect.has_point(va) or w_rect.has_point(vb) or w_rect.has_point(vc):
						newly_selected.append(t)
			if not newly_selected.is_empty():
				select_triangles(newly_selected)
		queue_redraw()

	if active_interacting_triangle and is_instance_valid(active_interacting_triangle):
		if active_interacting_triangle.current_drag == TriangleNode.DragMode.BODY and selected_triangles.size() > 1 and not drag_multi_start_positions.is_empty():
			var has_moved: bool = false
			var end_positions: Dictionary = {}
			for st in selected_triangles:
				if is_instance_valid(st):
					end_positions[st] = st.position
					if drag_multi_start_positions.get(st, st.position) != st.position:
						has_moved = true
			if has_moved:
				var cmd = TriangleCommands.MultiMoveCommand.new(selected_triangles, drag_multi_start_positions, end_positions)
				action_performed.emit(cmd)
			active_interacting_triangle.current_drag = TriangleNode.DragMode.NONE
		else:
			active_interacting_triangle.handle_input_release(world_pos)

		active_interacting_triangle = null
		drag_multi_start_positions.clear()
		_was_snapped = false
		queue_redraw()

func rotate_selected(angle_deg: float) -> void:
	if SoundManager.instance:
		SoundManager.instance.play_rotate_tick()
	if selected_triangles.size() > 1 or (selected_triangle and not selected_triangle.group_id.is_empty()):
		if selected_triangles.size() <= 1 and selected_triangle and not selected_triangle.group_id.is_empty():
			var expanded: Array[TriangleNode] = []
			for t in triangles:
				if is_instance_valid(t) and t.group_id == selected_triangle.group_id:
					expanded.append(t)
			if expanded.size() > 1:
				select_triangles(expanded)

		# Rotate all selected triangles around group centroid
		var group_center: Vector2 = get_group_center()

		var starts: Dictionary = {}
		var ends: Dictionary = {}
		var pos_starts: Dictionary = {}
		var pos_ends: Dictionary = {}
		var rad: float = deg_to_rad(angle_deg)

		for t in selected_triangles:
			var old_verts: Array[Vector2] = [t.vertex_a, t.vertex_b, t.vertex_c]
			var local_centroid: Vector2 = t.get_centroid()
			var world_centroid: Vector2 = t.position + local_centroid
			var new_world_centroid: Vector2 = group_center + (world_centroid - group_center).rotated(rad)
			var new_pos: Vector2 = new_world_centroid - local_centroid

			pos_starts[t] = t.position
			pos_ends[t] = new_pos
			t.position = new_pos

			var rotated_verts: Array[Vector2] = TriangleMath.rotate_vertices(old_verts, rad, local_centroid)
			starts[t] = old_verts
			ends[t] = rotated_verts
			t.vertex_a = rotated_verts[0]
			t.vertex_b = rotated_verts[1]
			t.vertex_c = rotated_verts[2]

			t.geometry_changed.emit(t)
			t.queue_redraw()

		var cmd = TriangleCommands.MultiTransformVerticesCommand.new(selected_triangles, starts, ends, pos_starts, pos_ends)
		action_performed.emit(cmd)
		queue_redraw()
	elif selected_triangle:
		selected_triangle.rotate_by_deg(angle_deg)
		queue_redraw()

func flip_selected_h() -> void:
	if selected_triangles.size() > 1:
		var group_center: Vector2 = Vector2.ZERO
		for t in selected_triangles:
			group_center += t.position + t.get_centroid()
		group_center /= float(selected_triangles.size())

		var starts: Dictionary = {}
		var ends: Dictionary = {}
		var pos_starts: Dictionary = {}
		var pos_ends: Dictionary = {}

		for t in selected_triangles:
			var old_verts: Array[Vector2] = [t.vertex_a, t.vertex_b, t.vertex_c]
			var local_centroid: Vector2 = t.get_centroid()
			var world_centroid: Vector2 = t.position + local_centroid
			var dx: float = world_centroid.x - group_center.x
			var new_world_centroid: Vector2 = Vector2(group_center.x - dx, world_centroid.y)
			var new_pos: Vector2 = new_world_centroid - local_centroid

			pos_starts[t] = t.position
			pos_ends[t] = new_pos
			t.position = new_pos

			var flipped_verts: Array[Vector2] = TriangleMath.flip_vertices_h(old_verts, local_centroid)
			starts[t] = old_verts
			ends[t] = flipped_verts
			t.vertex_a = flipped_verts[0]
			t.vertex_b = flipped_verts[1]
			t.vertex_c = flipped_verts[2]

			t.geometry_changed.emit(t)
			t.queue_redraw()

		var cmd = TriangleCommands.MultiTransformVerticesCommand.new(selected_triangles, starts, ends, pos_starts, pos_ends)
		action_performed.emit(cmd)
		queue_redraw()
	elif selected_triangle:
		selected_triangle.flip_h()
		queue_redraw()

func flip_selected_v() -> void:
	if selected_triangles.size() > 1:
		var group_center: Vector2 = Vector2.ZERO
		for t in selected_triangles:
			group_center += t.position + t.get_centroid()
		group_center /= float(selected_triangles.size())

		var starts: Dictionary = {}
		var ends: Dictionary = {}
		var pos_starts: Dictionary = {}
		var pos_ends: Dictionary = {}

		for t in selected_triangles:
			var old_verts: Array[Vector2] = [t.vertex_a, t.vertex_b, t.vertex_c]
			var local_centroid: Vector2 = t.get_centroid()
			var world_centroid: Vector2 = t.position + local_centroid
			var dy: float = world_centroid.y - group_center.y
			var new_world_centroid: Vector2 = Vector2(world_centroid.x, group_center.y - dy)
			var new_pos: Vector2 = new_world_centroid - local_centroid

			pos_starts[t] = t.position
			pos_ends[t] = new_pos
			t.position = new_pos

			var flipped_verts: Array[Vector2] = TriangleMath.flip_vertices_v(old_verts, local_centroid)
			starts[t] = old_verts
			ends[t] = flipped_verts
			t.vertex_a = flipped_verts[0]
			t.vertex_b = flipped_verts[1]
			t.vertex_c = flipped_verts[2]

			t.geometry_changed.emit(t)
			t.queue_redraw()

		var cmd = TriangleCommands.MultiTransformVerticesCommand.new(selected_triangles, starts, ends, pos_starts, pos_ends)
		action_performed.emit(cmd)
		queue_redraw()
	elif selected_triangle:
		selected_triangle.flip_v()
		queue_redraw()

func set_guide_state(enabled: bool, t_name: String = "") -> void:
	show_guide = enabled
	if not t_name.is_empty():
		active_guide_name = t_name
	if show_guide:
		var center: Vector2 = canvas_size / 2.0
		guide_triangles = TriangleTemplates.get_template_data(active_guide_name, center)
	else:
		guide_triangles.clear()
	queue_redraw()

func export_project_json() -> String:
	return ProjectStorage.serialize_project(triangles, canvas_size)

func load_project_json(json_str: String) -> bool:
	var full_data: Dictionary = ProjectStorage.deserialize_project_full(json_str)
	var parsed: Array[Dictionary] = full_data.get("triangles", [] as Array[Dictionary])
	if parsed.is_empty():
		return false

	if full_data.has("canvas_size") and full_data["canvas_size"] is Vector2:
		set_canvas_size(full_data["canvas_size"])

	clear_all_triangles()
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

	var cmd = TriangleCommands.BatchCreateCommand.new(self, new_nodes)
	action_performed.emit(cmd)
	if not new_nodes.is_empty():
		select_triangle(new_nodes[new_nodes.size() - 1])
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

	# Paper crisp border
	draw_rect(paper_rect, Color(0.28, 0.38, 0.55, 0.75), false, 1.5)

	# Paper dimension badge at top-left
	var font: Font = ThemeDB.fallback_font
	if font:
		var dim_str: String = "%d × %d px" % [int(canvas_size.x), int(canvas_size.y)]
		draw_string(font, paper_origin + Vector2(6.0, -8.0), dim_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.65, 0.75, 0.9, 0.8))

	# 4. Silhouette Guide Overlay (if active)
	if show_guide and not guide_triangles.is_empty():
		for item in guide_triangles:
			var pos: Vector2 = item["pos"]
			var p0: Vector2 = world_to_canvas(pos + item["a"])
			var p1: Vector2 = world_to_canvas(pos + item["b"])
			var p2: Vector2 = world_to_canvas(pos + item["c"])
			var fill_c: Color = item["color"]
			fill_c.a = 0.18
			draw_colored_polygon(PackedVector2Array([p0, p1, p2]), fill_c)
			draw_polyline(PackedVector2Array([p0, p1, p2, p0]), Color(0.25, 0.45, 0.8, 0.6), 2.2, true)

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

	# 2. Corner markers
	var corner_len: float = 8.0
	var c_col: Color = Color(0.22, 0.58, 0.98, 0.95)
	# Top-left
	draw_line(c_rect.position, c_rect.position + Vector2(corner_len, 0), c_col, 2.0)
	draw_line(c_rect.position, c_rect.position + Vector2(0, corner_len), c_col, 2.0)
	# Top-right
	var tr: Vector2 = c_rect.position + Vector2(c_rect.size.x, 0)
	draw_line(tr, tr - Vector2(corner_len, 0), c_col, 2.0)
	draw_line(tr, tr + Vector2(0, corner_len), c_col, 2.0)
	# Bottom-left
	var bl: Vector2 = c_rect.position + Vector2(0, c_rect.size.y)
	draw_line(bl, bl + Vector2(corner_len, 0), c_col, 2.0)
	draw_line(bl, bl - Vector2(0, corner_len), c_col, 2.0)
	# Bottom-right
	var br: Vector2 = c_rect.position + c_rect.size
	draw_line(br, br - Vector2(corner_len, 0), c_col, 2.0)
	draw_line(br, br - Vector2(0, corner_len), c_col, 2.0)

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

