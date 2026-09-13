class_name TestTriangleMath
extends RefCounted

## Unit tests for TriangleMath

const TriangleMath = preload("res://scripts/core/triangle_math.gd")
const TriangleTemplates = preload("res://scripts/core/triangle_templates.gd")
const ProjectStorage = preload("res://scripts/core/project_storage.gd")
const TriangleNode = preload("res://scenes/triangle/triangle_node.gd")

static func run(runner) -> void:
	test_equilateral_triangle(runner)
	test_right_triangle(runner)
	test_angle_sum_always_180(runner)
	test_collinear_detection(runner)
	test_grid_lengths(runner)
	test_point_in_triangle(runner)
	test_templates(runner)
	test_rotation_and_flip(runner)
	test_project_serialization(runner)
	test_proportional_scale(runner)
	test_inter_triangle_snap(runner)
	test_vertex_snap(runner)

static func test_equilateral_triangle(runner) -> void:
	var verts = TriangleMath.create_equilateral_vertices(120.0, Vector2(200, 200))
	var a = verts[0]
	var b = verts[1]
	var c = verts[2]

	var angles = TriangleMath.get_display_angles_deg(a, b, c)
	runner.assert_eq(angles["a"], 60, "Equilateral angle A must be 60")
	runner.assert_eq(angles["b"], 60, "Equilateral angle B must be 60")
	runner.assert_eq(angles["c"], 60, "Equilateral angle C must be 60")

	var info = TriangleMath.classify_triangle(a, b, c)
	runner.assert_true(info["is_equilateral"], "Triangle must be classified as equilateral")
	runner.assert_eq(info["name"], "정삼각형", "Display name must be 정삼각형")

static func test_right_triangle(runner) -> void:
	var a = Vector2(0, 0)
	var b = Vector2(120, 0)
	var c = Vector2(0, 90)

	var angles = TriangleMath.get_display_angles_deg(a, b, c)
	runner.assert_eq(angles["a"], 90, "Angle at origin must be 90")
	runner.assert_eq(angles["a"] + angles["b"] + angles["c"], 180, "Angle sum must be 180")

	var info = TriangleMath.classify_triangle(a, b, c)
	runner.assert_true(info["is_right"], "Must be detected as right triangle")
	runner.assert_eq(info["name"], "직각삼각형", "Name must be 직각삼각형")

static func test_angle_sum_always_180(runner) -> void:
	var test_triangles = [
		[Vector2(10, 20), Vector2(185, 45), Vector2(70, 210)],
		[Vector2(50, 50), Vector2(300, 80), Vector2(120, 150)],
		[Vector2(0, 0), Vector2(55, 12), Vector2(18, 99)],
		[Vector2(100, 100), Vector2(200, 100), Vector2(100, 200)],
		[Vector2(33, 77), Vector2(144, 288), Vector2(99, 12)]
	]

	for tri in test_triangles:
		var angles = TriangleMath.get_display_angles_deg(tri[0], tri[1], tri[2])
		var sum_deg: int = angles["a"] + angles["b"] + angles["c"]
		runner.assert_eq(sum_deg, 180, "Sum of display angles must be exactly 180 degrees")

static func test_collinear_detection(runner) -> void:
	var a = Vector2(0, 0)
	var b = Vector2(50, 50)
	var c = Vector2(100, 100)

	var valid = TriangleMath.is_valid_triangle(a, b, c, 10.0)
	runner.assert_false(valid, "Collinear points must not form a valid triangle")

static func test_grid_lengths(runner) -> void:
	var a = Vector2(0, 0)
	var b = Vector2(80, 0)
	var c = Vector2(0, 120)

	var sides = TriangleMath.get_side_lengths_grid(a, b, c, 40.0)
	runner.assert_float_approx(sides["ab"], 2.0, 0.01, "Side AB should be 2.0 grid units")
	runner.assert_float_approx(sides["ca"], 3.0, 0.01, "Side CA should be 3.0 grid units")

static func test_point_in_triangle(runner) -> void:
	var a = Vector2(0, 0)
	var b = Vector2(100, 0)
	var c = Vector2(50, 100)

	var inside_pt = Vector2(50, 30)
	var outside_pt = Vector2(200, 200)

	runner.assert_true(TriangleMath.is_point_in_triangle(inside_pt, a, b, c), "Point should be inside triangle")
	runner.assert_false(TriangleMath.is_point_in_triangle(outside_pt, a, b, c), "Point should be outside triangle")

static func test_templates(runner) -> void:
	var names = TriangleTemplates.get_template_names()
	runner.assert_eq(names.size(), 8, "Should have 8 template presets")

	for t_name in names:
		var items = TriangleTemplates.get_template_data(t_name, Vector2(500, 300))
		runner.assert_true(items.size() >= 3, "Template %s should have at least 3 triangles" % t_name)
		for item in items:
			var valid = TriangleMath.is_valid_triangle(item["a"], item["b"], item["c"], 5.0)
			runner.assert_true(valid, "Every template triangle in %s must be valid" % t_name)

static func test_rotation_and_flip(runner) -> void:
	var verts: Array[Vector2] = [Vector2(0, -50), Vector2(-40, 30), Vector2(40, 30)]
	var center = Vector2(0, 0)

	# 360 degree rotation should return approximately original points
	var rot_360 = TriangleMath.rotate_vertices(verts, TAU, center)
	runner.assert_float_approx(rot_360[0].x, verts[0].x, 0.01, "360 deg rot X")
	runner.assert_float_approx(rot_360[0].y, verts[0].y, 0.01, "360 deg rot Y")

	# Flipping twice should return original points
	var flip_2x = TriangleMath.flip_vertices_h(TriangleMath.flip_vertices_h(verts, center), center)
	runner.assert_eq(flip_2x[0], verts[0], "Double flip H must return original vertex A")
	runner.assert_eq(flip_2x[1], verts[1], "Double flip H must return original vertex B")

static func test_project_serialization(runner) -> void:
	var t1: TriangleNode = TriangleNode.new()
	t1.position = Vector2(100, 150)
	t1.fill_color = Color("#EF4444")
	var t2: TriangleNode = TriangleNode.new()
	t2.position = Vector2(300, 400)
	t2.fill_color = Color("#10B981")

	var json_str = ProjectStorage.serialize_project([t1, t2])
	runner.assert_true(json_str.contains("triangle_art_project"), "JSON must contain project format identifier")

	var deserialized = ProjectStorage.deserialize_project(json_str)
	runner.assert_eq(deserialized.size(), 2, "Deserialized count must be 2")
	runner.assert_eq(deserialized[0]["pos"], Vector2(100, 150), "T1 position preserved")
	runner.assert_eq(deserialized[1]["pos"], Vector2(300, 400), "T2 position preserved")

	t1.free()
	t2.free()

static func test_proportional_scale(runner) -> void:
	var orig_verts: Array[Vector2] = [Vector2(0, 0), Vector2(100, 0), Vector2(30, 80)]
	var orig_angles = TriangleMath.get_display_angles_deg(orig_verts[0], orig_verts[1], orig_verts[2])
	var centroid: Vector2 = (orig_verts[0] + orig_verts[1] + orig_verts[2]) / 3.0

	# Scale up by 1.5x
	var scaled_up = TriangleMath.scale_vertices_proportional(orig_verts, 1.5, centroid)
	var angles_up = TriangleMath.get_display_angles_deg(scaled_up[0], scaled_up[1], scaled_up[2])
	runner.assert_eq(angles_up["a"], orig_angles["a"], "Scale up must preserve angle A")
	runner.assert_eq(angles_up["b"], orig_angles["b"], "Scale up must preserve angle B")
	runner.assert_eq(angles_up["c"], orig_angles["c"], "Scale up must preserve angle C")

	# Scale down by 0.5x
	var scaled_down = TriangleMath.scale_vertices_proportional(orig_verts, 0.5, centroid)
	var angles_down = TriangleMath.get_display_angles_deg(scaled_down[0], scaled_down[1], scaled_down[2])
	runner.assert_eq(angles_down["a"], orig_angles["a"], "Scale down must preserve angle A")
	runner.assert_eq(angles_down["b"], orig_angles["b"], "Scale down must preserve angle B")
	runner.assert_eq(angles_down["c"], orig_angles["c"], "Scale down must preserve angle C")

static func test_inter_triangle_snap(runner) -> void:
	var t1 = TriangleNode.new()
	t1.position = Vector2(100, 100)
	t1.vertex_a = Vector2(0, 0)
	t1.vertex_b = Vector2(80, 0)
	t1.vertex_c = Vector2(0, 60)

	var t2 = TriangleNode.new()
	# Position t2 so its vertex_a (0,0) is 6px away from t1's vertex_b (80,0) -> world (186, 100)
	t2.position = Vector2(186, 100)
	t2.vertex_a = Vector2(0, 0)
	t2.vertex_b = Vector2(80, 0)
	t2.vertex_c = Vector2(40, 50)

	# 1. Vertex-to-Vertex snap
	var snap1 = TriangleMath.find_inter_triangle_snap(t2, [t1], 14.0)
	runner.assert_true(snap1["snapped"], "t2 should snap to t1 vertex")
	runner.assert_eq(snap1["offset"], Vector2(-6, 0), "Snap offset should move t2 by (-6, 0)")

	# 2. Vertex-to-Edge snap
	# Place t2's vertex_a near the horizontal bottom edge of t1 (y=100, between x=100 and x=180)
	t2.position = Vector2(140, 105) # 5px below edge AB of t1
	var snap2 = TriangleMath.find_inter_triangle_snap(t2, [t1], 14.0)
	runner.assert_true(snap2["snapped"], "t2 vertex should snap to t1 horizontal edge")
	runner.assert_float_approx(snap2["offset"].y, -5.0, 0.1, "Offset should snap up by -5px")

	t1.free()
	t2.free()

static func test_vertex_snap(runner) -> void:
	var t1 = TriangleNode.new()
	t1.position = Vector2(200, 200)
	t1.vertex_a = Vector2(0, 0)
	t1.vertex_b = Vector2(100, 0)
	t1.vertex_c = Vector2(50, 80)

	# Dragged vertex near t1 vertex_b (world 300, 200)
	var drag_pt = Vector2(304, 203)
	var snap = TriangleMath.find_vertex_snap(drag_pt, null, [t1], 14.0)
	runner.assert_true(snap["snapped"], "Dragged vertex should snap to vertex")
	runner.assert_eq(snap["snapped_pos"], Vector2(300, 200), "Snapped point should be exactly (300, 200)")

	# Dragged vertex near t1 edge AB (y=200, x between 200 and 300)
	var drag_pt_edge = Vector2(250, 206)
	var snap_edge = TriangleMath.find_vertex_snap(drag_pt_edge, null, [t1], 14.0)
	runner.assert_true(snap_edge["snapped"], "Dragged vertex should snap to edge")
	runner.assert_eq(snap_edge["snapped_pos"], Vector2(250, 200), "Snapped point should be exactly on edge (250, 200)")

	t1.free()

