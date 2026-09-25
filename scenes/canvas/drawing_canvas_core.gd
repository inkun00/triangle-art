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
signal context_menu_opened(target_triangle: TriangleNode, global_pos: Vector2)

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
	LAYER_FRONT = 15,
	LAYER_BACK = 16,
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
var challenge_guide: Array[Dictionary] = []
var selected_triangle: TriangleNode = null
var selected_triangles: Array[TriangleNode] = []
var active_interacting_triangle: TriangleNode = null

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

var is_dragging_group_scale: bool = false
var drag_group_scale_corner_idx: int = -1
var drag_group_scale_start_dist: float = 1.0
var drag_group_scale_start_mouse: Vector2 = Vector2.ZERO
var drag_group_scale_center: Vector2 = Vector2.ZERO
var drag_group_scale_start_positions: Dictionary = {}
var drag_group_scale_start_verts: Dictionary = {}
var current_group_scale_factor: float = 1.0

var context_menu: PopupMenu = null
var last_right_click_pos: Vector2 = Vector2.ZERO

# Double click (mouse) and double tap (touch/tablet) detection
const DOUBLE_CLICK_MAX_TIME_MSEC: int = 350
const DOUBLE_CLICK_MAX_DIST: float = 20.0
const DOUBLE_TAP_MAX_TIME_MSEC: int = 400
const DOUBLE_TAP_MAX_DIST: float = 35.0

var last_mouse_click_time_msec: int = 0
var last_mouse_click_local_pos: Vector2 = Vector2.ZERO

var last_touch_down_time_msec: int = 0
var last_touch_down_local_pos: Vector2 = Vector2.ZERO

var last_popup_trigger_time_msec: int = 0

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
	if is_inside_tree() and size.x > 50 and size.y > 50:
		fit_canvas_in_view()
		queue_redraw()

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
		fit_canvas_in_view()
		queue_redraw()

func set_challenge_guide(data: Array[Dictionary]) -> void:
	challenge_guide = data.duplicate(true)
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

func get_triangle_index(triangle: TriangleNode) -> int:
	return container.get_children().find(triangle)

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

func get_group_scale_corner_positions() -> Array[Vector2]:
	var bbox: Rect2 = get_group_bounding_box()
	if bbox.size.x <= 0.0 and bbox.size.y <= 0.0:
		return []
	var pad: float = 8.0 / zoom_level
	var p_min: Vector2 = bbox.position - Vector2(pad, pad)
	var p_max: Vector2 = bbox.position + bbox.size + Vector2(pad, pad)
	return [
		p_min,
		Vector2(p_max.x, p_min.y),
		Vector2(p_min.x, p_max.y),
		p_max
	]

func hit_test_group_scale_handle(world_point: Vector2) -> int:
	if selected_triangles.size() <= 1:
		return -1
	var corners: Array[Vector2] = get_group_scale_corner_positions()
	var hit_rad: float = 14.0 / zoom_level
	for i in range(corners.size()):
		if world_point.distance_to(corners[i]) <= hit_rad:
			return i
	return -1

func _start_group_scale_drag(world_pos: Vector2, corner_idx: int) -> void:
	is_dragging_group_scale = true
	drag_group_scale_corner_idx = corner_idx
	drag_group_scale_center = get_group_center()
	drag_group_scale_start_mouse = world_pos
	drag_group_scale_start_dist = maxf(world_pos.distance_to(drag_group_scale_center), 10.0)
	current_group_scale_factor = 1.0
	drag_group_scale_start_positions.clear()
	drag_group_scale_start_verts.clear()

	for t in selected_triangles:
		if is_instance_valid(t):
			drag_group_scale_start_positions[t] = t.position
			drag_group_scale_start_verts[t] = [t.vertex_a, t.vertex_b, t.vertex_c]

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

func _get_selected_layer_targets() -> Array[TriangleNode]:
	var targets: Array[TriangleNode] = []
	if selected_triangles.size() > 1:
		targets = selected_triangles.duplicate()
	elif selected_triangle and is_instance_valid(selected_triangle):
		if not selected_triangle.group_id.is_empty():
			for t in triangles:
				if is_instance_valid(t) and t.group_id == selected_triangle.group_id:
					targets.append(t)
		else:
			targets.append(selected_triangle)
	return targets

func _build_children_entities(children: Array) -> Array:
	var entities: Array = []
	var visited_groups: Dictionary = {}
	for c in children:
		if not (c is TriangleNode):
			continue
		if not c.group_id.is_empty():
			if visited_groups.has(c.group_id):
				continue
			visited_groups[c.group_id] = true
			var grp: Array = []
			for other in children:
				if other is TriangleNode and other.group_id == c.group_id:
					grp.append(other)
			entities.append(grp)
		else:
			entities.append([c])
	return entities

func bring_forward() -> void:
	var targets: Array[TriangleNode] = _get_selected_layer_targets()
	if targets.is_empty():
		return

	var current_children: Array = container.get_children()
	var entities: Array = _build_children_entities(current_children)

	var is_entity_selected: Array[bool] = []
	for ent in entities:
		var sel: bool = false
		for node in ent:
			if targets.has(node):
				sel = true
				break
		is_entity_selected.append(sel)

	var changed: bool = false
	for i in range(entities.size() - 2, -1, -1):
		if is_entity_selected[i] and not is_entity_selected[i + 1]:
			var temp = entities[i]
			entities[i] = entities[i + 1]
			entities[i + 1] = temp
			is_entity_selected[i] = false
			is_entity_selected[i + 1] = true
			changed = true

	if changed:
		var new_children: Array = []
		for ent in entities:
			for node in ent:
				new_children.append(node)
		var cmd = TriangleCommands.ReorderChildrenCommand.new(self, current_children, new_children)
		action_performed.emit(cmd)

func send_backward() -> void:
	var targets: Array[TriangleNode] = _get_selected_layer_targets()
	if targets.is_empty():
		return

	var current_children: Array = container.get_children()
	var entities: Array = _build_children_entities(current_children)

	var is_entity_selected: Array[bool] = []
	for ent in entities:
		var sel: bool = false
		for node in ent:
			if targets.has(node):
				sel = true
				break
		is_entity_selected.append(sel)

	var changed: bool = false
	for i in range(1, entities.size()):
		if is_entity_selected[i] and not is_entity_selected[i - 1]:
			var temp = entities[i]
			entities[i] = entities[i - 1]
			entities[i - 1] = temp
			is_entity_selected[i] = false
			is_entity_selected[i - 1] = true
			changed = true

	if changed:
		var new_children: Array = []
		for ent in entities:
			for node in ent:
				new_children.append(node)
		var cmd = TriangleCommands.ReorderChildrenCommand.new(self, current_children, new_children)
		action_performed.emit(cmd)

func bring_to_front() -> void:
	var targets: Array[TriangleNode] = _get_selected_layer_targets()
	if targets.is_empty():
		return

	var current_children: Array = container.get_children()
	var entities: Array = _build_children_entities(current_children)

	var unselected_entities: Array = []
	var selected_entities: Array = []

	for ent in entities:
		var sel: bool = false
		for node in ent:
			if targets.has(node):
				sel = true
				break
		if sel:
			selected_entities.append(ent)
		else:
			unselected_entities.append(ent)

	var new_entities: Array = unselected_entities + selected_entities
	var new_children: Array = []
	for ent in new_entities:
		for node in ent:
			new_children.append(node)

	if new_children != current_children:
		var cmd = TriangleCommands.ReorderChildrenCommand.new(self, current_children, new_children)
		action_performed.emit(cmd)

func send_to_back() -> void:
	var targets: Array[TriangleNode] = _get_selected_layer_targets()
	if targets.is_empty():
		return

	var current_children: Array = container.get_children()
	var entities: Array = _build_children_entities(current_children)

	var unselected_entities: Array = []
	var selected_entities: Array = []

	for ent in entities:
		var sel: bool = false
		for node in ent:
			if targets.has(node):
				sel = true
				break
		if sel:
			selected_entities.append(ent)
		else:
			unselected_entities.append(ent)

	var new_entities: Array = selected_entities + unselected_entities
	var new_children: Array = []
	for ent in new_entities:
		for node in ent:
			new_children.append(node)

	if new_children != current_children:
		var cmd = TriangleCommands.ReorderChildrenCommand.new(self, current_children, new_children)
		action_performed.emit(cmd)

func apply_children_order(new_order: Array) -> void:
	for i in range(new_order.size()):
		var t = new_order[i]
		if t is Node and t.get_parent() == container:
			container.move_child(t, i)
	triangles.clear()
	for child in container.get_children():
		if child is TriangleNode:
			triangles.append(child)
	queue_redraw()

func set_triangle_index(triangle: TriangleNode, new_index: int) -> void:
	if triangle.get_parent() == container:
		var clamped_idx: int = clampi(new_index, 0, container.get_child_count() - 1)
		container.move_child(triangle, clamped_idx)
		triangles.clear()
		for child in container.get_children():
			if child is TriangleNode:
				triangles.append(child)
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
	var targets: Array[TriangleNode] = []
	if selected_triangles.size() > 1:
		targets = selected_triangles.duplicate()
	elif selected_triangle and is_instance_valid(selected_triangle):
		if not selected_triangle.group_id.is_empty():
			for t in triangles:
				if is_instance_valid(t) and t.group_id == selected_triangle.group_id:
					targets.append(t)
		else:
			targets = [selected_triangle]

	if targets.is_empty():
		return

	if targets.size() > 1:
		var group_center: Vector2 = Vector2.ZERO
		var count: int = 0
		for t in targets:
			if is_instance_valid(t):
				group_center += t.position + t.get_centroid()
				count += 1
		group_center /= float(maxi(count, 1))

		var starts: Dictionary = {}
		var ends: Dictionary = {}
		var pos_starts: Dictionary = {}
		var pos_ends: Dictionary = {}
		var all_valid: bool = true
		var candidate_new_verts: Dictionary = {}
		var candidate_new_pos: Dictionary = {}

		for t in targets:
			if not is_instance_valid(t):
				continue
			var old_verts: Array[Vector2] = [t.vertex_a, t.vertex_b, t.vertex_c]
			var new_pos: Vector2 = group_center + (t.position - group_center) * factor
			var new_verts: Array[Vector2] = [
				t.vertex_a * factor,
				t.vertex_b * factor,
				t.vertex_c * factor
			]
			if not TriangleMath.is_valid_triangle(new_verts[0], new_verts[1], new_verts[2], 5.0):
				all_valid = false
				break
			candidate_new_verts[t] = new_verts
			candidate_new_pos[t] = new_pos

		if all_valid and not candidate_new_verts.is_empty():
			for t in candidate_new_verts.keys():
				starts[t] = [t.vertex_a, t.vertex_b, t.vertex_c]
				ends[t] = candidate_new_verts[t]
				pos_starts[t] = t.position
				pos_ends[t] = candidate_new_pos[t]

				t.position = candidate_new_pos[t]
				t.vertex_a = candidate_new_verts[t][0]
				t.vertex_b = candidate_new_verts[t][1]
				t.vertex_c = candidate_new_verts[t][2]
				t.geometry_changed.emit(t)
				t.queue_redraw()

			var cmd = TriangleCommands.MultiTransformVerticesCommand.new(targets, starts, ends, pos_starts, pos_ends)
			action_performed.emit(cmd)
			queue_redraw()
	elif targets.size() == 1:
		targets[0].scale_by_ratio(factor)
		queue_redraw()

func _on_triangle_action_committed(cmd: Variant) -> void:
	action_performed.emit(cmd)

func _on_triangle_geometry_changed(node: TriangleNode) -> void:
	if node == selected_triangle:
		triangle_geometry_updated.emit(node)

func _setup_context_menu() -> void:
	pass
