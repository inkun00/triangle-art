class_name PngExporter
extends Node

const TriangleNode = preload("res://scenes/triangle/triangle_node.gd")
const TriangleMath = preload("res://scripts/core/triangle_math.gd")

## Clean artwork PNG exporter without grid, handles, measurements, or UI.

static func export_canvas(tree: SceneTree, triangles: Array[TriangleNode], canvas_size: Vector2, is_transparent: bool = false, custom_save_path: String = "") -> String:
	if triangles.is_empty():
		return ""

	var vp_size: Vector2i = Vector2i(maxi(int(canvas_size.x), 100), maxi(int(canvas_size.y), 100))
	var img: Image = null
	if DisplayServer.get_name() == "headless":
		img = _rasterize_headless(triangles, vp_size, is_transparent)
	else:
		var vp: SubViewport = SubViewport.new()
		vp.size = vp_size
		vp.transparent_bg = is_transparent
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		if not is_transparent:
			var bg: ColorRect = ColorRect.new()
			bg.size = Vector2(vp_size)
			bg.color = Color.WHITE
			vp.add_child(bg)
		var art_container: Node2D = Node2D.new()
		vp.add_child(art_container)
		for t in triangles:
			if not is_instance_valid(t):
				continue
			var poly: Polygon2D = Polygon2D.new()
			poly.polygon = PackedVector2Array([
				t.position + t.vertex_a,
				t.position + t.vertex_b,
				t.position + t.vertex_c
			])
			poly.color = t.fill_color
			poly.antialiased = true
			art_container.add_child(poly)
			if t.outline_color.a > 0.001 and t.outline_width > 0.0:
				var outline: Line2D = Line2D.new()
				outline.points = PackedVector2Array([
					t.position + t.vertex_a,
					t.position + t.vertex_b,
					t.position + t.vertex_c,
					t.position + t.vertex_a
				])
				outline.default_color = t.outline_color
				outline.width = t.outline_width
				outline.antialiased = true
				outline.joint_mode = Line2D.LINE_JOINT_ROUND
				outline.begin_cap_mode = Line2D.LINE_CAP_ROUND
				outline.end_cap_mode = Line2D.LINE_CAP_ROUND
				art_container.add_child(outline)
		tree.root.add_child(vp)
		await RenderingServer.frame_post_draw
		var texture: ViewportTexture = vp.get_texture()
		if texture:
			img = texture.get_image()
		tree.root.remove_child(vp)
		vp.free()
	if not img:
		push_error("Could not render artwork PNG")
		return ""

	# Save path & Web download trigger
	var time_dict: Dictionary = Time.get_datetime_dict_from_system()
	var file_name: String = "triangle_art_%04d%02d%02d_%02d%02d%02d.png" % [
		time_dict["year"], time_dict["month"], time_dict["day"],
		time_dict["hour"], time_dict["minute"], time_dict["second"]
	]

	if OS.has_feature("web") and ClassDB.class_exists("JavaScriptBridge"):
		var png_buf: PackedByteArray = img.save_png_to_buffer()
		JavaScriptBridge.download_buffer(png_buf, file_name, "image/png")
		print("Artwork downloaded via browser: ", file_name)
		return file_name

	var save_path: String = custom_save_path
	if save_path.is_empty():
		save_path = "user://" + file_name

	var global_path: String = ProjectSettings.globalize_path(save_path)
	var err: Error = img.save_png(global_path)

	if err == OK:
		print("Artwork exported successfully to: ", global_path)
		return global_path
	else:
		push_error("Failed to export PNG: error code " + str(err))
		return ""

static func _rasterize_headless(triangles: Array[TriangleNode], size: Vector2i, transparent: bool) -> Image:
	var img: Image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT if transparent else Color.WHITE)
	for t in triangles:
		if not is_instance_valid(t):
			continue
		var a: Vector2 = t.position + t.vertex_a
		var b: Vector2 = t.position + t.vertex_b
		var c: Vector2 = t.position + t.vertex_c
		var pad: float = maxf(t.outline_width * 0.5, 1.0)
		var min_x: int = maxi(0, int(floorf(minf(a.x, minf(b.x, c.x)) - pad)))
		var max_x: int = mini(size.x - 1, int(ceilf(maxf(a.x, maxf(b.x, c.x)) + pad)))
		var min_y: int = maxi(0, int(floorf(minf(a.y, minf(b.y, c.y)) - pad)))
		var max_y: int = mini(size.y - 1, int(ceilf(maxf(a.y, maxf(b.y, c.y)) + pad)))
		for y in range(min_y, max_y + 1):
			for x in range(min_x, max_x + 1):
				var point: Vector2 = Vector2(x + 0.5, y + 0.5)
				var pixel: Color = img.get_pixel(x, y)
				if TriangleMath.is_point_in_triangle(point, a, b, c):
					pixel = _blend(pixel, t.fill_color)
				if t.outline_color.a > 0.001 and t.outline_width > 0.0:
					var radius: float = t.outline_width * 0.5
					if point.distance_to(TriangleMath.get_closest_point_on_segment(point, a, b)) <= radius or point.distance_to(TriangleMath.get_closest_point_on_segment(point, b, c)) <= radius or point.distance_to(TriangleMath.get_closest_point_on_segment(point, c, a)) <= radius:
						pixel = _blend(pixel, t.outline_color)
				img.set_pixel(x, y, pixel)
	return img

static func _blend(dst: Color, src: Color) -> Color:
	var alpha: float = src.a + dst.a * (1.0 - src.a)
	if alpha <= 0.0:
		return Color.TRANSPARENT
	return Color(
		(src.r * src.a + dst.r * dst.a * (1.0 - src.a)) / alpha,
		(src.g * src.a + dst.g * dst.a * (1.0 - src.a)) / alpha,
		(src.b * src.a + dst.b * dst.a * (1.0 - src.a)) / alpha,
		alpha
	)
