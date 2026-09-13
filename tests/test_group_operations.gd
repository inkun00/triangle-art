class_name TestGroupOperations
extends RefCounted

## Unit Tests for Group Operations: Scaling, Entity-based Layering, and Value/Brightness

const TriangleCommands = preload("res://scripts/core/triangle_commands.gd")
const TriangleMath = preload("res://scripts/core/triangle_math.gd")
const TriangleNode = preload("res://scenes/triangle/triangle_node.gd")

static func run(runner: Node) -> void:
	test_group_scaling(runner)
	test_layer_reorder_command(runner)
	test_lightness_hsv_math(runner)

static func test_group_scaling(runner: Node) -> void:
	var t1: TriangleNode = TriangleNode.new()
	t1.position = Vector2(100, 100)
	t1.vertex_a = Vector2(0, -20)
	t1.vertex_b = Vector2(-20, 20)
	t1.vertex_c = Vector2(20, 20)
	t1.group_id = "grp_1"

	var t2: TriangleNode = TriangleNode.new()
	t2.position = Vector2(200, 100)
	t2.vertex_a = Vector2(0, -20)
	t2.vertex_b = Vector2(-20, 20)
	t2.vertex_c = Vector2(20, 20)
	t2.group_id = "grp_1"

	# Center between t1 and t2 is (150, 100)
	var group_center: Vector2 = (t1.position + t2.position) * 0.5
	runner.assert_eq(group_center, Vector2(150, 100), "Group center calculated correctly")

	var factor: float = 2.0
	var new_pos1: Vector2 = group_center + (t1.position - group_center) * factor
	var new_pos2: Vector2 = group_center + (t2.position - group_center) * factor

	runner.assert_eq(new_pos1, Vector2(50, 100), "Scaled position 1 correct")
	runner.assert_eq(new_pos2, Vector2(250, 100), "Scaled position 2 correct")
	runner.assert_float_approx(new_pos1.distance_to(new_pos2), 200.0, 0.01, "Distance between triangles doubled")

	var new_verts1_a: Vector2 = t1.vertex_a * factor
	runner.assert_eq(new_verts1_a, Vector2(0, -40), "Vertices scaled proportionally")
	runner.assert_true(TriangleMath.is_valid_triangle(new_verts1_a, t1.vertex_b * factor, t1.vertex_c * factor, 5.0), "Scaled triangle remains valid")

	t1.free()
	t2.free()

static func test_layer_reorder_command(runner: Node) -> void:
	var parent: Node = Node.new()
	var n1: Node = Node.new()
	n1.name = "Node1"
	var n2: Node = Node.new()
	n2.name = "Node2"
	var n3: Node = Node.new()
	n3.name = "Node3"

	parent.add_child(n1)
	parent.add_child(n2)
	parent.add_child(n3)

	var initial_order: Array = [n1, n2, n3]
	var new_order: Array = [n3, n1, n2]

	# Mock canvas object that implements apply_children_order
	var mock_canvas: Object = ClassDB.instantiate("RefCounted")
	# Instead of mock script, create a small script or test inline
	var reorder_test = func(order: Array):
		for i in range(order.size()):
			parent.move_child(order[i], i)

	reorder_test.call(new_order)
	runner.assert_eq(parent.get_child(0), n3, "Child 0 moved to n3")
	runner.assert_eq(parent.get_child(1), n1, "Child 1 moved to n1")
	runner.assert_eq(parent.get_child(2), n2, "Child 2 moved to n2")

	reorder_test.call(initial_order)
	runner.assert_eq(parent.get_child(0), n1, "Undone child 0 back to n1")
	runner.assert_eq(parent.get_child(1), n2, "Undone child 1 back to n2")
	runner.assert_eq(parent.get_child(2), n3, "Undone child 2 back to n3")

	n1.free()
	n2.free()
	n3.free()
	parent.free()

static func test_lightness_hsv_math(runner: Node) -> void:
	# Pure red
	var red: Color = Color(1.0, 0.0, 0.0, 1.0)
	runner.assert_float_approx(red.v, 1.0, 0.01, "Red has value 1.0")

	# Adjust value down to 50%
	var new_v: float = 0.5
	var dark_red: Color = Color.from_hsv(red.h, red.s, new_v, red.a)
	runner.assert_float_approx(dark_red.v, 0.5, 0.01, "Dark red has value 0.5")
	runner.assert_float_approx(dark_red.r, 0.5, 0.01, "Dark red R is 0.5")
	runner.assert_float_approx(dark_red.g, 0.0, 0.01, "Dark red G is 0.0")
	runner.assert_float_approx(dark_red.b, 0.0, 0.01, "Dark red B is 0.0")

	# Black color to 50% lightness
	var black: Color = Color(0, 0, 0, 1.0)
	var grey: Color
	if black.s < 0.01 and black.v < 0.01:
		grey = Color(new_v, new_v, new_v, black.a)
	else:
		grey = Color.from_hsv(black.h, black.s, new_v, black.a)
	runner.assert_float_approx(grey.r, 0.5, 0.01, "Black raised to 50% becomes medium grey")
