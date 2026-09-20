class_name TestTriangleNode
extends RefCounted

## Tests for TriangleNode geometry, cloning, and interaction.

const TriangleNode = preload("res://scenes/triangle/triangle_node.gd")
const TriangleCommands = preload("res://scripts/core/triangle_commands.gd")
const TriangleMath = preload("res://scripts/core/triangle_math.gd")

static func run(runner) -> void:
	test_triangle_cloning(runner)
	test_triangle_vertex_update(runner)
	test_triangle_handle_hit(runner)
	test_triangle_body_hit(runner)
	test_triangle_drag_and_interaction(runner)
	test_korean_font_resource(runner)
	test_rotation_handle_and_drag(runner)
	test_group_and_ungroup_commands(runner)
	test_multi_color_command(runner)
	test_equilateral_math_and_grid_steps(runner)
	test_context_menu_actions(runner)
	test_group_duplicate_preservation(runner)
	test_canvas_size_and_bounds(runner)
	test_custom_color_palette(runner)
	test_project_save_and_load_v2(runner)
	test_touch_gestures(runner)
	test_continuous_rotation_handle_drag_no_drift(runner)
	test_multi_rotation_360_degrees_no_drift(runner)
	test_group_rotation_handle_drag_no_drift(runner)
	test_large_triangle_rotation(runner)
	test_asymmetric_large_triangle_handle_anchored(runner)
	test_large_triangle_top_clipping_flip(runner)
	test_corner_rotation_drag(runner)
	test_zoom_adaptive_hit_radius(runner)
	test_triangle_double_click_and_touch(runner)

static func test_triangle_cloning(runner) -> void:
	var t: TriangleNode = TriangleNode.new()
	t.vertex_a = Vector2(0, -60)
	t.vertex_b = Vector2(-50, 40)
	t.vertex_c = Vector2(50, 40)
	t.fill_color = Color.CORAL
	t.position = Vector2(100, 100)

	var clone: TriangleNode = t.clone_triangle()
	runner.assert_eq(clone.vertex_a, t.vertex_a, "Clone must have same vertex_a")
	runner.assert_eq(clone.vertex_b, t.vertex_b, "Clone must have same vertex_b")
	runner.assert_eq(clone.vertex_c, t.vertex_c, "Clone must have same vertex_c")
	runner.assert_eq(clone.fill_color, t.fill_color, "Clone must have same color")
	runner.assert_eq(clone.position, t.position + Vector2(24, 24), "Clone should have offset position")

	t.free()
	clone.free()

static func test_triangle_vertex_update(runner) -> void:
	var t: TriangleNode = TriangleNode.new()
	t.vertex_a = Vector2(0, 0)
	t.set_vertex_position(0, Vector2(15, 25))
	runner.assert_eq(t.vertex_a, Vector2(15, 25), "set_vertex_position must update vertex_a")
	t.free()

static func test_triangle_handle_hit(runner) -> void:
	var t: TriangleNode = TriangleNode.new()
	t.position = Vector2(100, 100)
	t.vertex_a = Vector2(0, -50)
	t.vertex_b = Vector2(-50, 40)
	t.vertex_c = Vector2(50, 40)

	# Canvas point for vertex A: position (100, 100) + vertex_a (0, -50) = (100, 50)
	var hit_idx = t.hit_test_handle(Vector2(100, 50))
	runner.assert_eq(hit_idx, 0, "Should hit vertex A handle at (100, 50)")

	# Canvas point for vertex B: (100 - 50, 100 + 40) = (50, 140)
	var hit_b = t.hit_test_handle(Vector2(50, 140))
	runner.assert_eq(hit_b, 1, "Should hit vertex B handle at (50, 140)")

	# Far away point
	var miss_idx = t.hit_test_handle(Vector2(500, 500))
	runner.assert_eq(miss_idx, -1, "Far away point should miss handles")

	t.free()

static func test_triangle_body_hit(runner) -> void:
	var t: TriangleNode = TriangleNode.new()
	t.position = Vector2(200, 200)
	t.vertex_a = Vector2(0, -60)
	t.vertex_b = Vector2(-50, 40)
	t.vertex_c = Vector2(50, 40)

	# Canvas point inside triangle: position (200, 200) + centroid (0, 6.6) = (200, 206)
	var inside_hit = t.hit_test_body(Vector2(200, 206))
	runner.assert_true(inside_hit, "Centroid point should hit triangle body")

	# Canvas point outside triangle: (200, 290) - below triangle
	var outside_hit = t.hit_test_body(Vector2(200, 290))
	runner.assert_false(outside_hit, "Point outside triangle should NOT hit body")

	# Canvas point far away: (10, 10)
	var far_hit = t.hit_test_body(Vector2(10, 10))
	runner.assert_false(far_hit, "Far point should NOT hit body")

	t.free()

static func test_triangle_drag_and_interaction(runner) -> void:
	var t: TriangleNode = TriangleNode.new()
	t.position = Vector2(200, 200)
	t.vertex_a = Vector2(0, -60)
	t.vertex_b = Vector2(-50, 40)
	t.vertex_c = Vector2(50, 40)

	# 1. Clicking blank canvas outside triangle should return false
	var miss_pressed = t.handle_input_press(Vector2(10, 10))
	runner.assert_false(miss_pressed, "Clicking outside should return false")

	# 2. Clicking vertex A handle should select and set VERTEX_A drag
	var handle_pressed = t.handle_input_press(Vector2(200, 140)) # 200 + 0, 200 - 60
	runner.assert_true(handle_pressed, "Clicking vertex handle should return true")
	runner.assert_true(t.is_selected, "Triangle should be selected")
	runner.assert_eq(t.current_drag, TriangleNode.DragMode.VERTEX_A, "Drag mode should be VERTEX_A")

	# Drag vertex to new canvas position (220, 130)
	t.handle_input_drag(Vector2(220, 130))
	# New local vertex_a should be (220, 130) - (200, 200) = (20, -70)
	runner.assert_eq(t.vertex_a, Vector2(20, -70), "Vertex A should be dragged to (20, -70)")

	t.handle_input_release(Vector2(220, 130))
	runner.assert_eq(t.current_drag, TriangleNode.DragMode.NONE, "Drag mode should reset to NONE on release")

	# 3. Clicking body should set BODY drag
	var body_pressed = t.handle_input_press(Vector2(200, 200))
	runner.assert_true(body_pressed, "Clicking body should return true")
	runner.assert_eq(t.current_drag, TriangleNode.DragMode.BODY, "Drag mode should be BODY")

	# Drag body by +30, +40
	t.handle_input_drag(Vector2(230, 240))
	runner.assert_eq(t.position, Vector2(230, 240), "Triangle position should move with drag")

	t.handle_input_release(Vector2(230, 240))
	runner.assert_eq(t.current_drag, TriangleNode.DragMode.NONE, "Drag mode should reset to NONE")

	t.free()

static func test_korean_font_resource(runner) -> void:
	var font_res = load("res://assets/fonts/korean_font.ttf")
	runner.assert_true(font_res != null, "Korean font resource must load successfully")
	if font_res is Font:
		var test_size = font_res.get_string_size("삼각형 아트", HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
		runner.assert_true(test_size.x > 0.0, "Font must measure Korean glyph string with positive width")

static func test_rotation_handle_and_drag(runner) -> void:
	var t: TriangleNode = TriangleNode.new()
	t.position = Vector2(200, 200)
	t.vertex_a = Vector2(0, -60)
	t.vertex_b = Vector2(-50, 40)
	t.vertex_c = Vector2(50, 40)
	t.set_selected(true)

	var rot_h_pos = t.position + t.get_rotation_handle_pos()
	var hit_rot = t.hit_test_rotation_handle(rot_h_pos)
	runner.assert_true(hit_rot, "Should hit rotation handle at calculated position")

	var press_rot = t.handle_input_press(rot_h_pos)
	runner.assert_true(press_rot, "Pressing rotation handle should succeed")
	runner.assert_eq(t.current_drag, TriangleNode.DragMode.ROTATION, "Drag mode should be ROTATION")

	var rot_pt = t.position + t.get_centroid() + Vector2(60, 0)
	t.handle_input_drag(rot_pt)
	runner.assert_true(t.current_rotation_deg != 0.0, "Rotation degree should be non-zero after drag")

	t.handle_input_release(rot_pt)
	runner.assert_eq(t.current_drag, TriangleNode.DragMode.NONE, "Drag mode resets to NONE on release")
	t.free()

static func test_group_and_ungroup_commands(runner) -> void:
	var t1: TriangleNode = TriangleNode.new()
	var t2: TriangleNode = TriangleNode.new()

	runner.assert_eq(t1.group_id, "", "Initial group_id should be empty")
	runner.assert_eq(t2.group_id, "", "Initial group_id should be empty")

	var dummy_canvas: Node = Node.new()
	var cmd = TriangleCommands.GroupCommand.new(dummy_canvas, [t1, t2], "grp_test_123")
	cmd.execute()

	runner.assert_eq(t1.group_id, "grp_test_123", "t1 should have group_id")
	runner.assert_eq(t2.group_id, "grp_test_123", "t2 should have group_id")

	cmd.undo()
	runner.assert_eq(t1.group_id, "", "Undo should revert group_id to empty")
	runner.assert_eq(t2.group_id, "", "Undo should revert group_id to empty")

	t1.free()
	t2.free()
	dummy_canvas.free()

static func test_multi_color_command(runner) -> void:
	var t1: TriangleNode = TriangleNode.new()
	var t2: TriangleNode = TriangleNode.new()
	t1.fill_color = Color.RED
	t2.fill_color = Color.BLUE

	var cmd = TriangleCommands.MultiColorCommand.new([t1, t2], Color.GREEN)
	cmd.execute()
	runner.assert_eq(t1.fill_color, Color.GREEN, "t1 color should be green")
	runner.assert_eq(t2.fill_color, Color.GREEN, "t2 color should be green")

	cmd.undo()
	runner.assert_eq(t1.fill_color, Color.RED, "t1 color should be restored to red")
	runner.assert_eq(t2.fill_color, Color.BLUE, "t2 color should be restored to blue")

	t1.free()
	t2.free()

static func test_equilateral_math_and_grid_steps(runner) -> void:
	for side in [40.0, 80.0, 120.0]:
		var verts = TriangleMath.create_equilateral_vertices(side, Vector2(100, 100))
		var info = TriangleMath.classify_triangle(verts[0], verts[1], verts[2])
		runner.assert_true(info["is_equilateral"], "create_equilateral_vertices must be classified as equilateral for side %f" % side)
		runner.assert_eq(info["name"], "정삼각형", "Triangle name must be 정삼각형")

static func test_context_menu_actions(runner) -> void:
	var canvas_scene = load("res://scenes/canvas/drawing_canvas.tscn")
	var canvas = canvas_scene.instantiate()
	runner.add_child(canvas)
	runner.assert_true(canvas != null, "Canvas should instantiate successfully")
	runner.assert_true(canvas.context_menu != null, "Context menu should be created")

	# Test menu items when a triangle is selected
	var t: TriangleNode = TriangleNode.new()
	canvas.add_triangle_node(t)
	canvas._show_context_menu(Vector2(200, 200))
	runner.assert_true(canvas.context_menu.get_item_count() > 5, "Context menu should have items when triangle is selected")

	# Test right-click on blank canvas clears selection
	canvas._handle_right_click(Vector2(50, 50), Vector2(50, 50))
	runner.assert_true(canvas.selected_triangles.is_empty(), "Right click on blank canvas should clear selection")

	runner.remove_child(canvas)
	canvas.free()

static func test_group_duplicate_preservation(runner) -> void:
	var canvas_scene = load("res://scenes/canvas/drawing_canvas.tscn")
	var canvas = canvas_scene.instantiate()
	runner.add_child(canvas)

	var mgr = preload("res://scripts/core/command_manager.gd").new()
	canvas.action_performed.connect(func(cmd): mgr.push_and_execute(cmd))

	var t1: TriangleNode = TriangleNode.new()
	var t2: TriangleNode = TriangleNode.new()
	t1.group_id = "grp_original_1"
	t2.group_id = "grp_original_1"
	canvas.add_triangle_node(t1)
	canvas.add_triangle_node(t2)

	var sel_list: Array[TriangleNode] = [t1, t2]
	canvas.select_triangles(sel_list)
	runner.assert_eq(canvas.selected_triangles.size(), 2, "Both triangles should be selected")

	var clones = canvas.duplicate_selected()
	runner.assert_eq(clones.size(), 2, "Two clones should be created")

	var c1: TriangleNode = clones[0]
	var c2: TriangleNode = clones[1]

	runner.assert_true(not c1.group_id.is_empty(), "Clone 1 should have a group_id")
	runner.assert_true(not c2.group_id.is_empty(), "Clone 2 should have a group_id")
	runner.assert_true(c1.group_id != "grp_original_1", "Clones must have a new distinct group_id")
	runner.assert_eq(c1.group_id, c2.group_id, "Both clones must share the same new group_id")

	# Test selecting one clone automatically selects the other via group
	canvas.select_triangle(c1)
	runner.assert_true(canvas.selected_triangles.has(c1), "Selection should contain c1")
	runner.assert_true(canvas.selected_triangles.has(c2), "Selection should contain c2 via group")

	# Test Undo / Redo
	runner.assert_eq(canvas.triangles.size(), 4, "Canvas should have 4 triangles")
	mgr.undo()
	runner.assert_eq(canvas.triangles.size(), 2, "Undo should reduce triangle count back to 2")
	mgr.redo()
	runner.assert_eq(canvas.triangles.size(), 4, "Redo should restore clones to 4")

	runner.remove_child(canvas)
	canvas.free()

static func test_canvas_size_and_bounds(runner) -> void:
	var canvas_scene = load("res://scenes/canvas/drawing_canvas.tscn")
	var canvas = canvas_scene.instantiate()
	runner.add_child(canvas)

	runner.assert_eq(canvas.canvas_size, Vector2(1200, 800), "Default canvas size should be 1200x800")

	# Change canvas size
	var new_sz = Vector2(1080, 1080)
	canvas.set_canvas_size(new_sz)
	runner.assert_eq(canvas.canvas_size, new_sz, "Canvas size should be updated to 1080x1080")

	# Test clamping bounds (min 300, max 4096)
	canvas.set_canvas_size(Vector2(50, 10000))
	runner.assert_eq(canvas.canvas_size.x, 300.0, "Canvas width should be clamped to min 300")
	runner.assert_eq(canvas.canvas_size.y, 4096.0, "Canvas height should be clamped to max 4096")

	runner.remove_child(canvas)
	canvas.free()

static func test_custom_color_palette(runner) -> void:
	var palette_scene = load("res://scenes/ui/color_palette.tscn")
	var palette = palette_scene.instantiate()
	runner.add_child(palette)

	var init_count: int = palette.custom_colors.size()
	var test_col: Color = Color(0.123, 0.456, 0.789)
	palette.add_custom_color(test_col)

	runner.assert_true(palette.custom_colors.has(test_col), "Palette should contain newly added custom color")
	runner.assert_eq(palette.custom_colors.size(), init_count + 1, "Custom colors count should increase by 1")

	# Test duplicate color prevention
	palette.add_custom_color(test_col)
	runner.assert_eq(palette.custom_colors.size(), init_count + 1, "Duplicate color should not be added again")

	# Test remove custom color
	palette.remove_custom_color(test_col)
	runner.assert_false(palette.custom_colors.has(test_col), "Removed color should no longer be in custom colors")

	runner.remove_child(palette)
	palette.free()

static func test_project_save_and_load_v2(runner) -> void:
	var canvas_scene = load("res://scenes/canvas/drawing_canvas.tscn")
	var canvas = canvas_scene.instantiate()
	runner.add_child(canvas)

	var mgr = preload("res://scripts/core/command_manager.gd").new()
	canvas.action_performed.connect(func(cmd): mgr.push_and_execute(cmd))

	# Setup custom canvas size
	canvas.set_canvas_size(Vector2(1080, 1080))

	# Create two triangles with outlines and groups
	var t1: TriangleNode = TriangleNode.new()
	t1.position = Vector2(300, 300)
	t1.vertex_a = Vector2(0, -60)
	t1.vertex_b = Vector2(-50, 40)
	t1.vertex_c = Vector2(50, 40)
	t1.fill_color = Color.RED
	t1.outline_color = Color.YELLOW
	t1.outline_width = 4.0
	t1.group_id = "grp_test_v2"
	canvas.add_triangle_node(t1)

	var t2: TriangleNode = TriangleNode.new()
	t2.position = Vector2(500, 300)
	t2.vertex_a = Vector2(0, -40)
	t2.vertex_b = Vector2(-30, 30)
	t2.vertex_c = Vector2(30, 30)
	t2.fill_color = Color.BLUE
	t2.outline_color = Color.WHITE
	t2.outline_width = 3.0
	t2.group_id = "grp_test_v2"
	canvas.add_triangle_node(t2)

	# Export to JSON
	var json_str: String = canvas.export_project_json()
	runner.assert_true(json_str.contains("\"version\": 2"), "JSON should be version 2 format")
	runner.assert_true(json_str.contains("grp_test_v2"), "JSON should contain group_id")
	runner.assert_true(json_str.contains("1080"), "JSON should contain canvas_size 1080")

	# Reset canvas to different state
	canvas.set_canvas_size(Vector2(800, 600))
	canvas.clear_all_triangles()
	runner.assert_eq(canvas.triangles.size(), 0, "Canvas should be cleared")
	runner.assert_eq(canvas.canvas_size, Vector2(800, 600), "Canvas size should be 800x600")

	# Load project JSON back
	var load_res: bool = canvas.load_project_json(json_str)
	runner.assert_true(load_res, "load_project_json should return true")
	runner.assert_eq(canvas.canvas_size, Vector2(1080, 1080), "Canvas size should be restored to 1080x1080")
	runner.assert_eq(canvas.triangles.size(), 2, "Both triangles should be restored")

	var restored_t1: TriangleNode = canvas.triangles[0]
	var restored_t2: TriangleNode = canvas.triangles[1]
	runner.assert_eq(restored_t1.group_id, "grp_test_v2", "Triangle 1 group_id restored")
	runner.assert_eq(restored_t2.group_id, "grp_test_v2", "Triangle 2 group_id restored")
	runner.assert_eq(restored_t1.outline_width, 4.0, "Triangle 1 outline_width restored")
	runner.assert_eq(restored_t2.outline_width, 3.0, "Triangle 2 outline_width restored")

	runner.remove_child(canvas)
	canvas.free()

static func test_touch_gestures(runner) -> void:
	var canvas_scene = load("res://scenes/canvas/drawing_canvas.tscn")
	var canvas = canvas_scene.instantiate()
	runner.add_child(canvas)

	var init_zoom = canvas.zoom_level

	# Simulate two finger touch
	var touch0 = InputEventScreenTouch.new()
	touch0.index = 0
	touch0.position = Vector2(200, 200)
	touch0.pressed = true
	canvas._gui_input(touch0)

	var touch1 = InputEventScreenTouch.new()
	touch1.index = 1
	touch1.position = Vector2(400, 200)
	touch1.pressed = true
	canvas._gui_input(touch1)

	runner.assert_eq(canvas.touch_points.size(), 2, "Should record 2 touch points")
	runner.assert_true(canvas.touch_start_dist > 150.0, "touch_start_dist should be calculated")

	# Simulate drag apart (pinch zoom in)
	var drag1 = InputEventScreenDrag.new()
	drag1.index = 1
	drag1.position = Vector2(600, 200)
	canvas._gui_input(drag1)

	runner.assert_true(canvas.zoom_level > init_zoom, "Zoom level should increase after pinching apart")

	# Release fingers
	touch0.pressed = false
	touch1.pressed = false
	canvas._gui_input(touch0)
	canvas._gui_input(touch1)
	runner.assert_eq(canvas.touch_points.size(), 0, "Touch points should be empty after release")

	runner.remove_child(canvas)
	canvas.free()

static func test_continuous_rotation_handle_drag_no_drift(runner) -> void:
	var t: TriangleNode = TriangleNode.new()
	t.position = Vector2(300, 300)
	t.vertex_a = Vector2(0, -60)
	t.vertex_b = Vector2(-50, 40)
	t.vertex_c = Vector2(50, 40)
	t.set_selected(true)

	var orig_centroid = t.position + t.get_centroid()
	var rot_h_pos = t.position + t.get_rotation_handle_pos()
	t.handle_input_press(rot_h_pos)

	# Simulate 100 consecutive mouse motion events during drag
	for i in range(100):
		var angle = -PI/2.0 + (float(i) / 100.0) * TAU
		var drag_pt = orig_centroid + Vector2(cos(angle), sin(angle)) * 70.0
		t.handle_input_drag(drag_pt)

	t.handle_input_release(orig_centroid + Vector2(0, -70))
	var final_centroid = t.position + t.get_centroid()
	var drift = final_centroid.distance_to(orig_centroid)
	runner.assert_true(drift < 0.01, "Rotation handle drag should not drift centroid (drift=%f)" % drift)
	t.free()

static func test_multi_rotation_360_degrees_no_drift(runner) -> void:
	var canvas_scene = load("res://scenes/canvas/drawing_canvas.tscn")
	var canvas = canvas_scene.instantiate()
	runner.add_child(canvas)

	var mgr = preload("res://scripts/core/command_manager.gd").new()
	canvas.action_performed.connect(func(cmd): mgr.push_and_execute(cmd))

	var t1: TriangleNode = TriangleNode.new()
	t1.position = Vector2(400, 300)
	t1.vertex_a = Vector2(0, -60)
	t1.vertex_b = Vector2(-50, 40)
	t1.vertex_c = Vector2(50, 40)
	canvas.add_triangle_node(t1)

	var t2: TriangleNode = TriangleNode.new()
	t2.position = Vector2(500, 300)
	t2.vertex_a = Vector2(0, -60)
	t2.vertex_b = Vector2(-50, 40)
	t2.vertex_c = Vector2(50, 40)
	canvas.add_triangle_node(t2)

	var sel: Array[TriangleNode] = [t1, t2]
	canvas.select_triangles(sel)

	var t1_orig_centroid = t1.position + t1.get_centroid()
	var t2_orig_centroid = t2.position + t2.get_centroid()
	var t1_orig_pos = t1.position
	var t2_orig_pos = t2.position

	# Rotate 8 times by 45 deg = 360 deg
	for i in range(8):
		canvas.rotate_selected(45.0)

	var t1_drift = (t1.position + t1.get_centroid()).distance_to(t1_orig_centroid)
	var t2_drift = (t2.position + t2.get_centroid()).distance_to(t2_orig_centroid)
	runner.assert_true(t1_drift < 0.01, "T1 multi-rotation 360 deg should return to original with zero drift (drift=%f)" % t1_drift)
	runner.assert_true(t2_drift < 0.01, "T2 multi-rotation 360 deg should return to original with zero drift (drift=%f)" % t2_drift)
	runner.assert_true(t1.position.distance_to(t1_orig_pos) < 0.01, "T1 position should be restored")
	runner.assert_true(t2.position.distance_to(t2_orig_pos) < 0.01, "T2 position should be restored")

	# Test Undo all 8 rotations
	for i in range(8):
		mgr.undo()

	runner.assert_true(t1.position.distance_to(t1_orig_pos) < 0.01, "T1 position after Undo should be restored")
	runner.assert_true(t2.position.distance_to(t2_orig_pos) < 0.01, "T2 position after Undo should be restored")

	runner.remove_child(canvas)
	canvas.free()

static func test_group_rotation_handle_drag_no_drift(runner) -> void:
	var canvas_scene = load("res://scenes/canvas/drawing_canvas.tscn")
	var canvas = canvas_scene.instantiate()
	runner.add_child(canvas)

	var mgr = preload("res://scripts/core/command_manager.gd").new()
	canvas.action_performed.connect(func(cmd): mgr.push_and_execute(cmd))

	var t1: TriangleNode = TriangleNode.new()
	t1.position = Vector2(300, 200)
	t1.vertex_a = Vector2(0, -50)
	t1.vertex_b = Vector2(-40, 30)
	t1.vertex_c = Vector2(40, 30)
	t1.group_id = "test_grp_rotation"
	canvas.add_triangle_node(t1)

	var t2: TriangleNode = TriangleNode.new()
	t2.position = Vector2(450, 250)
	t2.vertex_a = Vector2(10, -40)
	t2.vertex_b = Vector2(-30, 40)
	t2.vertex_c = Vector2(50, 20)
	t2.group_id = "test_grp_rotation"
	canvas.add_triangle_node(t2)

	# Selecting t1 should automatically select t2 because of group_id
	canvas.select_triangle(t1)
	runner.assert_eq(canvas.selected_triangles.size(), 2, "Group selection should select both triangles")
	runner.assert_true(t1.hide_rotation_handle, "t1 individual rotation handle should be hidden when grouped")
	runner.assert_true(t2.hide_rotation_handle, "t2 individual rotation handle should be hidden when grouped")

	# Check group rotation handle position and hit test
	var rot_handle_pos: Vector2 = canvas.get_group_rotation_handle_pos()
	runner.assert_true(canvas.hit_test_group_rotation_handle(rot_handle_pos), "Hit test at group rotation handle position should succeed")

	var t1_orig_centroid = t1.position + t1.get_centroid()
	var t2_orig_centroid = t2.position + t2.get_centroid()
	var t1_orig_pos = t1.position
	var t2_orig_pos = t2.position

	# Simulate dragging the group rotation handle in a circle (72 steps = 360 deg)
	canvas._start_group_rotation_drag(rot_handle_pos)
	runner.assert_true(canvas.is_dragging_group_rotation, "is_dragging_group_rotation should be true")

	var group_center: Vector2 = canvas.drag_multi_group_center
	var drag_radius: float = rot_handle_pos.distance_to(group_center)
	var steps: int = 72
	for s in range(1, steps + 1):
		var ang: float = canvas.drag_multi_start_angle + (float(s) / float(steps)) * TAU
		var cur_pt: Vector2 = group_center + Vector2(cos(ang), sin(ang)) * drag_radius
		var fake_event = InputEventMouseMotion.new()
		fake_event.position = canvas.world_to_canvas(cur_pt)
		canvas._gui_input(fake_event)

	# Release at 360 deg
	canvas._handle_mouse_release(rot_handle_pos)
	runner.assert_false(canvas.is_dragging_group_rotation, "is_dragging_group_rotation should be false after release")

	var t1_drift = (t1.position + t1.get_centroid()).distance_to(t1_orig_centroid)
	var t2_drift = (t2.position + t2.get_centroid()).distance_to(t2_orig_centroid)
	runner.assert_true(t1_drift < 0.001, "T1 drift after 360 deg group drag must be near zero (drift=%f)" % t1_drift)
	runner.assert_true(t2_drift < 0.001, "T2 drift after 360 deg group drag must be near zero (drift=%f)" % t2_drift)
	runner.assert_true(t1.position.distance_to(t1_orig_pos) < 0.001, "T1 position should return exactly to start position")
	runner.assert_true(t2.position.distance_to(t2_orig_pos) < 0.001, "T2 position should return exactly to start position")

	# Test Undo
	mgr.undo()
	runner.assert_true(t1.position.distance_to(t1_orig_pos) < 0.001, "T1 position after Undo should be restored")
	runner.assert_true(t2.position.distance_to(t2_orig_pos) < 0.001, "T2 position after Undo should be restored")

	runner.remove_child(canvas)
	canvas.free()

static func test_large_triangle_rotation(runner) -> void:
	var t = TriangleNode.new()
	t.position = Vector2(600, 400)
	# Large triangle side ~600px
	t.vertex_a = Vector2(0, -350)
	t.vertex_b = Vector2(-300, 200)
	t.vertex_c = Vector2(300, 200)
	t.set_selected(true)

	var rot_handle_local = t.get_rotation_handle_pos()
	var rot_handle_world = t.position + rot_handle_local
	print("[DEBUG] Large triangle rot handle local: ", rot_handle_local, " world: ", rot_handle_world)
	print("[DEBUG] Centroid: ", t.get_centroid())

	var hit = t.hit_test_rotation_handle(rot_handle_world)
	runner.assert_true(hit, "Should hit rotation handle at rot_handle_world")

	var pressed = t.handle_input_press(rot_handle_world)
	runner.assert_true(pressed, "Should press rotation handle")
	runner.assert_eq(t.current_drag, TriangleNode.DragMode.ROTATION, "Drag mode should be ROTATION")

	# Test dragging by small amount (e.g. 10px to right)
	var drag_pt = rot_handle_world + Vector2(20, 0)
	t.handle_input_drag(drag_pt)
	print("[DEBUG] After 20px drag: current_rotation_deg=", t.current_rotation_deg)

	# Test dragging by 45 degrees
	var c_canvas = t.position + t.drag_start_centroid
	var ang_45 = t.drag_start_angle + deg_to_rad(45.0)
	var rad = rot_handle_world.distance_to(c_canvas)
	var drag_45_pt = c_canvas + Vector2(cos(ang_45), sin(ang_45)) * rad
	t.handle_input_drag(drag_45_pt)
	print("[DEBUG] After 45 deg drag: current_rotation_deg=", t.current_rotation_deg)
	runner.assert_eq(int(t.current_rotation_deg), 45, "Should be 45 deg")

	t.free()

static func test_asymmetric_large_triangle_handle_anchored(runner) -> void:
	var t = TriangleNode.new()
	t.position = Vector2(400, 300)
	# Stretched, highly asymmetric triangle (apex at x=-200, y=-150; other vertices far right)
	t.vertex_a = Vector2(-200, -150)
	t.vertex_b = Vector2(300, 200)
	t.vertex_c = Vector2(500, 300)
	t.set_selected(true)

	var rot_h_local = t.get_rotation_handle_pos()
	# Handle should be anchored near vertex_a (apex), NOT 400px away at centroid x=200
	var dist_to_apex = rot_h_local.distance_to(t.vertex_a)
	runner.assert_true(dist_to_apex < 50.0, "Rotation handle should be anchored within 50px of apex, dist=%f" % dist_to_apex)

	var rot_h_world = t.position + rot_h_local
	var hit = t.hit_test_rotation_handle(rot_h_world)
	runner.assert_true(hit, "Should hit rotation handle on asymmetric triangle")

	var pressed = t.handle_input_press(rot_h_world)
	runner.assert_true(pressed, "Should press rotation handle on asymmetric triangle")
	runner.assert_eq(t.current_drag, TriangleNode.DragMode.ROTATION, "Should enter ROTATION drag mode")
	t.free()

static func test_large_triangle_top_clipping_flip(runner) -> void:
	var t = TriangleNode.new()
	# Triangle whose top vertex goes above the canvas (position.y + vertex_a.y < 0)
	t.position = Vector2(400, 50)
	t.vertex_a = Vector2(0, -100) # world y = -50 (off-screen / behind toolbar)
	t.vertex_b = Vector2(-150, 100)
	t.vertex_c = Vector2(150, 100)
	t.set_selected(true)

	var rot_h_local = t.get_rotation_handle_pos()
	var rot_h_world = t.position + rot_h_local
	# Because top vertex is above canvas y=0, handle should flip to bottom anchor (y > 0)
	runner.assert_true(rot_h_world.y > 0.0, "Rotation handle should flip to bottom anchor when top is clipped, world_y=%f" % rot_h_world.y)

	var hit = t.hit_test_rotation_handle(rot_h_world)
	runner.assert_true(hit, "Should hit flipped rotation handle")
	t.free()

static func test_corner_rotation_drag(runner) -> void:
	var t = TriangleNode.new()
	t.position = Vector2(300, 300)
	t.vertex_a = Vector2(0, -100)
	t.vertex_b = Vector2(-100, 80)
	t.vertex_c = Vector2(100, 80)
	t.set_selected(true)

	# Click in the corner rotation zone just outside vertex_b (distance 25px away outward)
	var dir_out = (t.vertex_b - t.get_centroid()).normalized()
	var corner_zone_world = t.position + t.vertex_b + dir_out * 26.0

	var hit_corner = t.hit_test_corner_rotation(corner_zone_world)
	runner.assert_true(hit_corner, "Point 26px outside vertex_b should be in corner rotation zone")

	var pressed = t.handle_input_press(corner_zone_world)
	runner.assert_true(pressed, "Pressing corner rotation zone should succeed")
	runner.assert_eq(t.current_drag, TriangleNode.DragMode.ROTATION, "Should enter ROTATION mode from corner zone")
	t.free()

static func test_zoom_adaptive_hit_radius(runner) -> void:
	var t = TriangleNode.new()
	t.zoom_level = 1.0
	var rad_1 = t.get_handle_hit_radius()
	runner.assert_eq(rad_1, 22.0, "Hit radius at zoom 1.0 should be 22.0")

	t.zoom_level = 0.5
	var rad_half = t.get_handle_hit_radius()
	runner.assert_eq(rad_half, 44.0, "Hit radius at zoom 0.5 should be 44.0 to preserve screen-space size")
	t.free()

static func test_triangle_double_click_and_touch(runner) -> void:
	var canvas_scene = load("res://scenes/canvas/drawing_canvas.tscn")
	var canvas = canvas_scene.instantiate()
	runner.add_child(canvas)

	var t1: TriangleNode = TriangleNode.new()
	t1.position = Vector2(300, 300)
	t1.vertex_a = Vector2(0, -50)
	t1.vertex_b = Vector2(-50, 40)
	t1.vertex_c = Vector2(50, 40)
	canvas.add_triangle_node(t1)

	var t1_click_pos: Vector2 = canvas.world_to_canvas(t1.position + t1.get_centroid())

	var menu_state = {"count": 0, "last_tri": null}
	canvas.context_menu_opened.connect(func(tri: TriangleNode, _pos: Vector2):
		menu_state["count"] += 1
		menu_state["last_tri"] = tri
	)

	# 1. Test Mouse Left Double-Click with mb.double_click = true
	var mb_dc = InputEventMouseButton.new()
	mb_dc.button_index = MOUSE_BUTTON_LEFT
	mb_dc.pressed = true
	mb_dc.double_click = true
	mb_dc.position = t1_click_pos
	mb_dc.global_position = t1_click_pos
	canvas._gui_input(mb_dc)

	runner.assert_eq(menu_state["count"], 1, "Mouse double-click with double_click=true should open context menu")
	runner.assert_eq(menu_state["last_tri"], t1, "Context menu opened should target t1")
	runner.assert_eq(canvas.selected_triangle, t1, "t1 should be selected after double click")
	runner.assert_eq(t1.position, Vector2(300, 300), "Double click should not displace triangle position")
	canvas.context_menu.hide()

	# 2. Test Mouse Left Double-Click with consecutive rapid clicks (<350ms)
	canvas.select_triangle(null)
	canvas.last_popup_trigger_time_msec = 0
	canvas.last_mouse_click_time_msec = 0

	var mb1_down = InputEventMouseButton.new()
	mb1_down.button_index = MOUSE_BUTTON_LEFT
	mb1_down.pressed = true
	mb1_down.double_click = false
	mb1_down.position = t1_click_pos
	mb1_down.global_position = t1_click_pos
	canvas._gui_input(mb1_down)

	var mb1_up = InputEventMouseButton.new()
	mb1_up.button_index = MOUSE_BUTTON_LEFT
	mb1_up.pressed = false
	mb1_up.double_click = false
	mb1_up.position = t1_click_pos
	mb1_up.global_position = t1_click_pos
	canvas._gui_input(mb1_up)

	runner.assert_eq(menu_state["count"], 1, "First single click should not trigger context menu")

	# Second click within rapid threshold (simulating rapid consecutive click on desktop/web)
	var mb2_down = InputEventMouseButton.new()
	mb2_down.button_index = MOUSE_BUTTON_LEFT
	mb2_down.pressed = true
	mb2_down.double_click = false
	mb2_down.position = t1_click_pos + Vector2(2, 1)
	mb2_down.global_position = t1_click_pos + Vector2(2, 1)
	canvas._gui_input(mb2_down)

	runner.assert_eq(menu_state["count"], 2, "Second rapid click should trigger double click context menu")
	runner.assert_eq(menu_state["last_tri"], t1, "Context menu should target t1 on second click")
	runner.assert_eq(t1.position, Vector2(300, 300), "Consecutive clicks should not move triangle")
	canvas.context_menu.hide()

	# 3. Test Tablet Screen Touch with st.double_tap = true
	canvas.select_triangle(null)
	canvas.last_popup_trigger_time_msec = 0

	var st_dt = InputEventScreenTouch.new()
	st_dt.index = 0
	st_dt.pressed = true
	st_dt.double_tap = true
	st_dt.position = t1_click_pos
	canvas._gui_input(st_dt)

	runner.assert_eq(menu_state["count"], 3, "ScreenTouch with double_tap=true should open context menu")
	runner.assert_eq(menu_state["last_tri"], t1, "Touch double-tap should target t1")
	runner.assert_eq(canvas.selected_triangle, t1, "t1 should be selected after touch double-tap")
	canvas.context_menu.hide()

	# 4. Test Tablet Screen Touch with consecutive rapid touches (<400ms)
	canvas.select_triangle(null)
	canvas.last_popup_trigger_time_msec = 0
	canvas.last_touch_down_time_msec = 0

	var st1_down = InputEventScreenTouch.new()
	st1_down.index = 0
	st1_down.pressed = true
	st1_down.double_tap = false
	st1_down.position = t1_click_pos
	canvas._gui_input(st1_down)

	var st1_up = InputEventScreenTouch.new()
	st1_up.index = 0
	st1_up.pressed = false
	st1_up.position = t1_click_pos
	canvas._gui_input(st1_up)

	runner.assert_eq(menu_state["count"], 3, "First touch should not trigger context menu")

	# Second touch slightly moved within rapid threshold
	var st2_down = InputEventScreenTouch.new()
	st2_down.index = 0
	st2_down.pressed = true
	st2_down.double_tap = false
	st2_down.position = t1_click_pos + Vector2(6, 4)
	canvas._gui_input(st2_down)

	runner.assert_eq(menu_state["count"], 4, "Second rapid touch on tablet should trigger double-tap context menu")
	runner.assert_eq(menu_state["last_tri"], t1, "Touch double-tap should target t1")
	canvas.context_menu.hide()

	# 5. Test Double-Click on empty canvas space does NOT open triangle context menu
	canvas.last_popup_trigger_time_msec = 0
	var mb_empty = InputEventMouseButton.new()
	mb_empty.button_index = MOUSE_BUTTON_LEFT
	mb_empty.pressed = true
	mb_empty.double_click = true
	mb_empty.position = Vector2(10, 10)
	mb_empty.global_position = Vector2(10, 10)
	canvas._gui_input(mb_empty)

	runner.assert_eq(menu_state["count"], 4, "Double click on empty space should NOT trigger context menu")

	# 6. Test Multi-selection double click preserves group selection
	var t2: TriangleNode = TriangleNode.new()
	t2.position = Vector2(500, 500)
	t2.vertex_a = Vector2(0, -50)
	t2.vertex_b = Vector2(-50, 40)
	t2.vertex_c = Vector2(50, 40)
	canvas.add_triangle_node(t2)

	var sel_list: Array[TriangleNode] = [t1, t2]
	canvas.select_triangles(sel_list)
	runner.assert_eq(canvas.selected_triangles.size(), 2, "Both t1 and t2 should be selected")

	var t2_click_pos: Vector2 = canvas.world_to_canvas(t2.position + t2.get_centroid())
	canvas.last_popup_trigger_time_msec = 0
	var mb_multi = InputEventMouseButton.new()
	mb_multi.button_index = MOUSE_BUTTON_LEFT
	mb_multi.pressed = true
	mb_multi.double_click = true
	mb_multi.position = t2_click_pos
	mb_multi.global_position = t2_click_pos
	canvas._gui_input(mb_multi)

	runner.assert_eq(menu_state["count"], 5, "Double click on multi-selected triangle should open context menu")
	runner.assert_eq(canvas.selected_triangles.size(), 2, "Multi-selection of 2 triangles must be preserved")

	runner.remove_child(canvas)
	canvas.free()
