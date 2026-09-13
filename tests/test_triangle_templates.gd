class_name TestTriangleTemplates
extends RefCounted

## Unit tests for TriangleTemplates: verifies all 30 templates and their geometric validity.

const TriangleMath = preload("res://scripts/core/triangle_math.gd")
const TriangleTemplates = preload("res://scripts/core/triangle_templates.gd")

static func run(runner) -> void:
	var all_meta: Array[Dictionary] = TriangleTemplates.get_all_template_metadata()
	runner.assert_eq(all_meta.size(), 30, "Total templates count must be exactly 30")

	var stage1: Array[Dictionary] = TriangleTemplates.get_templates_by_stage(1)
	var stage2: Array[Dictionary] = TriangleTemplates.get_templates_by_stage(2)
	var stage3: Array[Dictionary] = TriangleTemplates.get_templates_by_stage(3)

	runner.assert_eq(stage1.size(), 10, "Stage 1 must contain exactly 10 templates")
	runner.assert_eq(stage2.size(), 10, "Stage 2 must contain exactly 10 templates")
	runner.assert_eq(stage3.size(), 10, "Stage 3 must contain exactly 10 templates")

	var names: Array[String] = TriangleTemplates.get_template_names()
	runner.assert_eq(names.size(), 30, "get_template_names() must return 30 unique names")

	var center: Vector2 = Vector2(800, 450)

	for meta in all_meta:
		var t_name: String = meta["name"]
		var expected_pieces: int = int(meta["pieces"])
		var triangles: Array[Dictionary] = TriangleTemplates.get_template_data(t_name, center)

		runner.assert_eq(triangles.size(), expected_pieces, "%s piece count must match metadata" % t_name)

		for i in range(triangles.size()):
			var tri: Dictionary = triangles[i]
			runner.assert_true(tri.has("pos"), "%s triangle %d has pos" % [t_name, i])
			runner.assert_true(tri.has("a") and tri.has("b") and tri.has("c"), "%s triangle %d has vertices" % [t_name, i])
			runner.assert_true(tri.has("color"), "%s triangle %d has color" % [t_name, i])

			var a: Vector2 = tri["a"]
			var b: Vector2 = tri["b"]
			var c: Vector2 = tri["c"]
			var valid: bool = TriangleMath.is_valid_triangle(a, b, c, 5.0)
			runner.assert_true(valid, "%s triangle %d must be a valid non-collinear triangle" % [t_name, i])
			runner.assert_true(tri["color"].a > 0.1, "%s triangle %d color must be visible" % [t_name, i])
