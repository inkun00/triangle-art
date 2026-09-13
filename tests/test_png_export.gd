class_name TestPngExport
extends RefCounted

## Test PNG export functionality

const PngExporter = preload("res://scripts/export/png_exporter.gd")
const TriangleNode = preload("res://scenes/triangle/triangle_node.gd")

static func run(runner) -> void:
	await test_export(runner)

static func test_export(runner) -> void:
	var t: TriangleNode = TriangleNode.new()
	t.vertex_a = Vector2(0, -40)
	t.vertex_b = Vector2(-40, 30)
	t.vertex_c = Vector2(40, 30)
	t.fill_color = Color.RED
	t.position = Vector2(200, 200)

	var test_path: String = "user://test_export_output.png"
	var triangles: Array[TriangleNode] = [t]

	# Synchronous test call or frame check
	var out_path = await PngExporter.export_canvas(runner.get_tree(), triangles, Vector2(600, 400), false, test_path)
	runner.assert_true(FileAccess.file_exists(test_path), "Exported PNG file must exist on disk")

	# Clean up test output
	if FileAccess.file_exists(test_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))

	t.free()
