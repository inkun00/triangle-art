class_name TestPuzzleEvaluator
extends RefCounted

## Unit tests for PuzzleEvaluator gamification accuracy engine.

const PuzzleEvaluator = preload("res://scripts/core/puzzle_evaluator.gd")
const TriangleTemplates = preload("res://scripts/core/triangle_templates.gd")
const TriangleNode = preload("res://scenes/triangle/triangle_node.gd")

static func run(runner) -> void:
	test_empty_canvas(runner)
	test_perfect_match(runner)
	test_partial_match(runner)
	test_both_input_formats(runner)

static func test_empty_canvas(runner) -> void:
	var template_data: Array = TriangleTemplates.get_template_data("나비 (Butterfly)", Vector2(600, 400))
	var result: Dictionary = PuzzleEvaluator.evaluate_accuracy([], template_data)

	runner.assert_eq(result["accuracy"], 0.0, "Empty canvas accuracy should be 0.0")
	runner.assert_eq(result["percentage"], 0, "Empty canvas percentage should be 0%")
	runner.assert_eq(result["stars"], 0, "Empty canvas stars should be 0")
	runner.assert_false(result["passed"], "Empty canvas should not pass")
	runner.assert_gt(result["template_count"], 0, "Template should have triangles")

static func test_perfect_match(runner) -> void:
	var center: Vector2 = Vector2(600, 400)
	var template_data: Array = TriangleTemplates.get_template_data("물고기 (Fish)", center)

	# Build TriangleNodes directly matching template
	var nodes: Array[TriangleNode] = []
	for item in template_data:
		var t: TriangleNode = TriangleNode.new()
		t.position = item["pos"]
		t.vertex_a = item["a"]
		t.vertex_b = item["b"]
		t.vertex_c = item["c"]
		t.fill_color = item["color"]
		nodes.append(t)

	var result: Dictionary = PuzzleEvaluator.evaluate_accuracy(nodes, template_data)

	runner.assert_ge(result["accuracy"], 0.90, "Identical triangles should have >= 90% accuracy")
	runner.assert_true(result["passed"], "Identical triangles should pass challenge")
	runner.assert_ge(result["stars"], 2, "Identical triangles should earn at least 2 or 3 stars")
	runner.assert_eq(result["user_count"], template_data.size(), "User count should match template count")

	for node in nodes:
		node.queue_free()

static func test_partial_match(runner) -> void:
	var center: Vector2 = Vector2(600, 400)
	var template_data: Array = TriangleTemplates.get_template_data("나비 (Butterfly)", center)

	# Build only 1 triangle instead of full butterfly
	var nodes: Array[TriangleNode] = []
	var item: Dictionary = template_data[0]
	var t: TriangleNode = TriangleNode.new()
	t.position = item["pos"]
	t.vertex_a = item["a"]
	t.vertex_b = item["b"]
	t.vertex_c = item["c"]
	nodes.append(t)

	var result: Dictionary = PuzzleEvaluator.evaluate_accuracy(nodes, template_data)

	runner.assert_lt(result["accuracy"], 0.50, "Only 1 of 8 triangles should have low accuracy")
	runner.assert_false(result["passed"], "Partial match should not pass")
	runner.assert_le(result["stars"], 1, "Partial match should have at most 1 star")

	for node in nodes:
		node.queue_free()

static func test_both_input_formats(runner) -> void:
	var center: Vector2 = Vector2(600, 400)
	var raw_array: Array = TriangleTemplates.get_template_data("요트 (Sailboat)", center)
	var dict_format: Dictionary = {"triangles": raw_array}

	var res1 = PuzzleEvaluator.evaluate_accuracy([], raw_array)
	var res2 = PuzzleEvaluator.evaluate_accuracy([], dict_format)

	runner.assert_eq(res1["template_count"], res2["template_count"], "Both array and dict format should evaluate equal counts")
	runner.assert_eq(res1["accuracy"], res2["accuracy"], "Both formats should yield identical accuracy")
