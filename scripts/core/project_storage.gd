class_name ProjectStorage
extends RefCounted

## Serializes and deserializes Triangle Art projects to/from JSON.

static func serialize_project(triangles: Array, canvas_size: Vector2 = Vector2(1200, 800)) -> String:
	var list: Array[Dictionary] = []
	for t in triangles:
		if not is_instance_valid(t):
			continue
		var d: Dictionary = {
			"pos_x": t.position.x,
			"pos_y": t.position.y,
			"ax": t.vertex_a.x,
			"ay": t.vertex_a.y,
			"bx": t.vertex_b.x,
			"by": t.vertex_b.y,
			"cx": t.vertex_c.x,
			"cy": t.vertex_c.y,
			"color": t.fill_color.to_html(true),
			"outline_color": t.outline_color.to_html(true),
			"outline_width": t.outline_width,
			"group_id": t.group_id
		}
		list.append(d)

	var project_dict: Dictionary = {
		"version": 2,
		"format": "triangle_art_project",
		"timestamp": Time.get_datetime_string_from_system(),
		"canvas_size": {
			"width": canvas_size.x,
			"height": canvas_size.y
		},
		"triangles": list
	}

	return JSON.stringify(project_dict, "  ")

static func deserialize_project_full(json_string: String) -> Dictionary:
	var default_res: Dictionary = {
		"canvas_size": Vector2(1200, 800),
		"triangles": [] as Array[Dictionary]
	}

	var json: JSON = JSON.new()
	var error: Error = json.parse(json_string)
	if error != OK:
		push_error("Failed to parse project JSON: " + json.get_error_message())
		return default_res

	var data = json.get_data()
	if not (data is Dictionary and data.has("triangles")):
		return default_res

	# Parse canvas_size if present
	if data.has("canvas_size") and data["canvas_size"] is Dictionary:
		var c_dict = data["canvas_size"]
		var cw: float = float(c_dict.get("width", 1200.0))
		var ch: float = float(c_dict.get("height", 800.0))
		default_res["canvas_size"] = Vector2(cw, ch)

	var t_list = data["triangles"]
	if not (t_list is Array):
		return default_res

	var parsed_triangles: Array[Dictionary] = []
	for item in t_list:
		if not (item is Dictionary):
			continue
		var pos: Vector2 = Vector2(float(item.get("pos_x", 0)), float(item.get("pos_y", 0)))
		var a: Vector2 = Vector2(float(item.get("ax", 0)), float(item.get("ay", -50)))
		var b: Vector2 = Vector2(float(item.get("bx", -50)), float(item.get("by", 40)))
		var c: Vector2 = Vector2(float(item.get("cx", 50)), float(item.get("cy", 40)))
		var col: Color = Color.from_string(str(item.get("color", "#3B82F6")), Color.BLUE)

		var out_str: String = str(item.get("outline_color", "00000000"))
		var out_col: Color = Color.from_string(out_str, Color.TRANSPARENT)
		var out_w: float = float(item.get("outline_width", 2.0))
		var grp: String = str(item.get("group_id", ""))

		parsed_triangles.append({
			"pos": pos,
			"a": a,
			"b": b,
			"c": c,
			"color": col,
			"outline_color": out_col,
			"outline_width": out_w,
			"group_id": grp
		})

	default_res["triangles"] = parsed_triangles
	return default_res

static func deserialize_project(json_string: String) -> Array[Dictionary]:
	var full = deserialize_project_full(json_string)
	return full.get("triangles", [] as Array[Dictionary])
