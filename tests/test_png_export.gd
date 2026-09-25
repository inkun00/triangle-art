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
	var image: Image = Image.load_from_file(test_path)
	runner.assert_eq(image.get_size(), Vector2i(600, 400), "Exported PNG has requested canvas size")
	var center: Color = image.get_pixel(200, 200)
	runner.assert_gt(center.r, 0.9, "Triangle interior is rendered red")
	runner.assert_lt(center.g, 0.1, "Triangle interior is not blank white")
	runner.assert_eq(image.get_pixel(10, 10).a, 1.0, "Opaque export has an opaque background")
	var transparent_path: String = "user://test_export_transparent.png"
	await PngExporter.export_canvas(runner.get_tree(), triangles, Vector2(600, 400), true, transparent_path)
	var transparent_image: Image = Image.load_from_file(transparent_path)
	runner.assert_eq(transparent_image.get_pixel(10, 10).a, 0.0, "Transparent export has a clear background")
	runner.assert_gt(transparent_image.get_pixel(200, 200).a, 0.9, "Transparent export retains the triangle")

	# Clean up test output
	if FileAccess.file_exists(test_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	if FileAccess.file_exists(transparent_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(transparent_path))

	t.free()
