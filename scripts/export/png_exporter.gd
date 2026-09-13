class_name PngExporter
extends Node

const TriangleNode = preload("res://scenes/triangle/triangle_node.gd")

## Clean artwork PNG exporter without grid, handles, measurements, or UI.

static func export_canvas(tree: SceneTree, triangles: Array[TriangleNode], canvas_size: Vector2, is_transparent: bool = false, custom_save_path: String = "") -> String:
	if triangles.is_empty():
		return ""

	var vp: SubViewport = SubViewport.new()
	var vp_size: Vector2i = Vector2i(maxi(int(canvas_size.x), 100), maxi(int(canvas_size.y), 100))
	vp.size = vp_size
	vp.transparent_bg = is_transparent
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	# White background if not transparent
	if not is_transparent:
		var bg: ColorRect = ColorRect.new()
		bg.size = Vector2(vp_size)
		bg.color = Color.WHITE
		vp.add_child(bg)

	# Container for pure artwork elements
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

	# Add to tree temporarily to render
	tree.root.call_deferred("add_child", vp)
	await tree.process_frame
	await tree.process_frame

	# Force viewport render
	RenderingServer.frame_post_draw
	await tree.process_frame


	var texture: ViewportTexture = vp.get_texture()
	var img: Image = null
	if DisplayServer.get_name() != "headless" and texture:
		img = texture.get_image()
	if not img:
		img = Image.create(vp_size.x, vp_size.y, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE if not is_transparent else Color.TRANSPARENT)

	# Save path & Web download trigger
	var time_dict: Dictionary = Time.get_datetime_dict_from_system()
	var file_name: String = "triangle_art_%04d%02d%02d_%02d%02d%02d.png" % [
		time_dict["year"], time_dict["month"], time_dict["day"],
		time_dict["hour"], time_dict["minute"], time_dict["second"]
	]

	if OS.has_feature("web") and ClassDB.class_exists("JavaScriptBridge"):
		var png_buf: PackedByteArray = img.save_png_to_buffer()
		JavaScriptBridge.download_buffer(png_buf, file_name, "image/png")
		vp.queue_free()
		print("Artwork downloaded via browser: ", file_name)
		return file_name

	var save_path: String = custom_save_path
	if save_path.is_empty():
		save_path = "user://" + file_name

	var global_path: String = ProjectSettings.globalize_path(save_path)
	var err: Error = img.save_png(global_path)

	# Clean up viewport
	vp.queue_free()

	if err == OK:
		print("Artwork exported successfully to: ", global_path)
		return global_path
	else:
		push_error("Failed to export PNG: error code " + str(err))
		return ""
