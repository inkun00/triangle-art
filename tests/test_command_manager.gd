class_name TestCommandManager
extends RefCounted

## Unit tests for CommandManager Undo/Redo

const CommandManager = preload("res://scripts/core/command_manager.gd")
const TriangleNode = preload("res://scenes/triangle/triangle_node.gd")

class DummyCommand extends RefCounted:
	var target_val: Array
	var add_val: int
	func _init(arr: Array, val: int) -> void:
		target_val = arr
		add_val = val
	func execute() -> void:
		target_val.append(add_val)
	func undo() -> void:
		target_val.erase(add_val)

static func run(runner) -> void:
	test_undo_redo_flow(runner)
	test_multi_color_command_undo_redo(runner)
	test_multi_outline_color_command_undo_redo(runner)
	test_delete_restores_layer_and_releases_history(runner)
	test_batch_delete_restores_sparse_layers(runner)

static func test_batch_delete_restores_sparse_layers(runner) -> void:
	var canvas = load("res://scenes/canvas/drawing_canvas.tscn").instantiate()
	runner.add_child(canvas)
	var mgr = CommandManager.new()
	canvas.action_performed.connect(func(cmd): mgr.push_and_execute(cmd))
	var a = TriangleNode.new()
	var b = TriangleNode.new()
	var c = TriangleNode.new()
	var d = TriangleNode.new()
	for triangle in [a, b, c, d]:
		canvas.add_triangle_node(triangle)
	var selected: Array[TriangleNode] = [a, c]
	canvas.select_triangles(selected)
	canvas.delete_selected()
	runner.assert_eq(canvas.triangles, [b, d], "Batch delete preserves remaining layers")
	mgr.undo()
	runner.assert_eq(canvas.triangles, [a, b, c, d], "Batch undo restores nonadjacent layers")
	mgr.clear()
	runner.remove_child(canvas)
	canvas.free()

static func test_delete_restores_layer_and_releases_history(runner) -> void:
	var canvas = load("res://scenes/canvas/drawing_canvas.tscn").instantiate()
	runner.add_child(canvas)
	var mgr = CommandManager.new()
	canvas.action_performed.connect(func(cmd): mgr.push_and_execute(cmd))
	var first = TriangleNode.new()
	var middle = TriangleNode.new()
	var last = TriangleNode.new()
	canvas.add_triangle_node(first)
	canvas.add_triangle_node(middle)
	canvas.add_triangle_node(last)
	canvas.select_triangle(middle)
	canvas.delete_selected()
	runner.assert_eq(canvas.triangles, [first, last], "Deleting middle triangle preserves remaining layer order")
	mgr.undo()
	runner.assert_eq(canvas.triangles, [first, middle, last], "Undo restores the original layer order")
	mgr.redo()
	runner.assert_eq(canvas.triangles, [first, last], "Redo removes the same triangle")
	mgr.clear()
	runner.assert_false(is_instance_valid(middle), "Clearing history frees a detached deleted triangle")
	var created = canvas.add_new_equilateral_triangle()
	mgr.undo()
	runner.assert_true(is_instance_valid(created), "Undone creation remains available for redo")
	mgr.clear()
	runner.assert_false(is_instance_valid(created), "Clearing redo history frees an undone creation")
	var pruned = canvas.add_new_equilateral_triangle()
	mgr.max_history = 1
	canvas.delete_selected()
	runner.assert_true(is_instance_valid(pruned), "Pruning create history keeps a node referenced by delete")
	var arr: Array = []
	mgr.push_and_execute(DummyCommand.new(arr, 1))
	runner.assert_false(is_instance_valid(pruned), "Pruning final delete reference frees detached node")
	mgr.clear()
	runner.remove_child(canvas)
	canvas.free()

static func test_multi_color_command_undo_redo(runner) -> void:
	var TriangleCommands = preload("res://scripts/core/triangle_commands.gd")
	var TriangleNode = preload("res://scenes/triangle/triangle_node.gd")
	var mgr = CommandManager.new()

	var t1 = TriangleNode.new()
	t1.fill_color = Color(1, 0, 0)
	var t2 = TriangleNode.new()
	t2.fill_color = Color(0, 1, 0)

	# 1. Normal color command
	var cmd1 = TriangleCommands.MultiColorCommand.new([t1, t2], Color(0, 0, 1))
	mgr.push_and_execute(cmd1)
	runner.assert_eq(t1.fill_color, Color(0, 0, 1), "t1 should be blue after command")
	runner.assert_eq(t2.fill_color, Color(0, 0, 1), "t2 should be blue after command")

	mgr.undo()
	runner.assert_eq(t1.fill_color, Color(1, 0, 0), "t1 should be red after undo")
	runner.assert_eq(t2.fill_color, Color(0, 1, 0), "t2 should be green after undo")

	mgr.redo()
	runner.assert_eq(t1.fill_color, Color(0, 0, 1), "t1 should be blue after redo")
	runner.assert_eq(t2.fill_color, Color(0, 0, 1), "t2 should be blue after redo")

	# 2. Command with saved_old_colors (simulating slider drag preview where t.fill_color changed prior to commit)
	var original_colors = {t1: t1.fill_color, t2: t2.fill_color}
	t1.fill_color = Color(0.5, 0.5, 0.5)
	t2.fill_color = Color(0.5, 0.5, 0.5)

	var final_color = Color(1, 1, 0)
	var cmd2 = TriangleCommands.MultiColorCommand.new([t1, t2], final_color, original_colors)
	mgr.push_and_execute(cmd2)
	runner.assert_eq(t1.fill_color, final_color, "t1 should be yellow after cmd2 execute")

	mgr.undo()
	runner.assert_eq(t1.fill_color, Color(0, 0, 1), "t1 should restore to blue on undo")
	runner.assert_eq(t2.fill_color, Color(0, 0, 1), "t2 should restore to blue on undo")

	t1.free()
	t2.free()

static func test_multi_outline_color_command_undo_redo(runner) -> void:
	var TriangleCommands = preload("res://scripts/core/triangle_commands.gd")
	var TriangleNode = preload("res://scenes/triangle/triangle_node.gd")
	var mgr = CommandManager.new()

	var t1 = TriangleNode.new()
	t1.outline_color = Color(0.2, 0.2, 0.2)
	var t2 = TriangleNode.new()
	t2.outline_color = Color(0.4, 0.4, 0.4)

	# 1. Change outline color
	var new_border = Color(1, 0, 0, 1)
	var cmd1 = TriangleCommands.MultiOutlineColorCommand.new([t1, t2], new_border)
	mgr.push_and_execute(cmd1)
	runner.assert_eq(t1.outline_color, new_border, "t1 outline should be red")
	runner.assert_eq(t2.outline_color, new_border, "t2 outline should be red")

	# Undo restores initial outline colors
	mgr.undo()
	runner.assert_eq(t1.outline_color, Color(0.2, 0.2, 0.2), "t1 outline restored on undo")
	runner.assert_eq(t2.outline_color, Color(0.4, 0.4, 0.4), "t2 outline restored on undo")

	# Redo sets red again
	mgr.redo()
	runner.assert_eq(t1.outline_color, new_border, "t1 outline red again on redo")
	runner.assert_eq(t2.outline_color, new_border, "t2 outline red again on redo")

	# 2. Remove outline (transparent)
	var cmd_remove = TriangleCommands.MultiOutlineColorCommand.new([t1, t2], Color(0, 0, 0, 0))
	mgr.push_and_execute(cmd_remove)
	runner.assert_eq(t1.outline_color.a, 0.0, "t1 outline should be transparent (removed)")
	runner.assert_eq(t2.outline_color.a, 0.0, "t2 outline should be transparent (removed)")

	mgr.undo()
	runner.assert_eq(t1.outline_color, new_border, "t1 outline restored after remove outline")
	runner.assert_eq(t2.outline_color, new_border, "t2 outline restored after remove outline")

	t1.free()
	t2.free()

static func test_undo_redo_flow(runner) -> void:
	var mgr = CommandManager.new()
	var arr: Array = []

	runner.assert_false(mgr.can_undo(), "Initially cannot undo")
	runner.assert_false(mgr.can_redo(), "Initially cannot redo")

	var cmd1 = DummyCommand.new(arr, 10)
	mgr.push_and_execute(cmd1)

	runner.assert_eq(arr.size(), 1, "Array should have 1 element after execute")
	runner.assert_true(mgr.can_undo(), "Can undo after command")
	runner.assert_false(mgr.can_redo(), "Cannot redo after command")

	mgr.undo()
	runner.assert_eq(arr.size(), 0, "Array should be empty after undo")
	runner.assert_true(mgr.can_redo(), "Can redo after undo")

	mgr.redo()
	runner.assert_eq(arr.size(), 1, "Array should have 1 element after redo")
	runner.assert_eq(arr[0], 10, "Element should be 10")
