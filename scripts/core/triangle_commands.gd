class_name TriangleCommands
extends RefCounted

## Command definitions for Triangle Art Undo/Redo

class CreateCommand extends RefCounted:
	var canvas: Node
	var triangle: Node
	func _init(p_canvas: Node, p_triangle: Node) -> void:
		canvas = p_canvas
		triangle = p_triangle
	func execute() -> void:
		if not triangle.get_parent():
			canvas.add_triangle_node(triangle)
		triangle.set_selected(true)
	func undo() -> void:
		if triangle.get_parent():
			canvas.remove_triangle_node(triangle)

class DeleteCommand extends RefCounted:
	var canvas: Node
	var triangle: Node
	var old_index: int
	func _init(p_canvas: Node, p_triangle: Node) -> void:
		canvas = p_canvas
		triangle = p_triangle
		old_index = canvas.get_triangle_index(triangle)
	func execute() -> void:
		if triangle.get_parent():
			canvas.remove_triangle_node(triangle)
	func undo() -> void:
		if not triangle.get_parent():
			canvas.add_triangle_node(triangle)
			canvas.set_triangle_index(triangle, old_index)
		triangle.set_selected(true)

class MoveCommand extends RefCounted:
	var triangle: Node
	var old_pos: Vector2
	var new_pos: Vector2
	func _init(p_triangle: Node, p_old_pos: Vector2, p_new_pos: Vector2) -> void:
		triangle = p_triangle
		old_pos = p_old_pos
		new_pos = p_new_pos
	func execute() -> void:
		triangle.position = new_pos
		triangle.queue_redraw()
	func undo() -> void:
		triangle.position = old_pos
		triangle.queue_redraw()

class VertexMoveCommand extends RefCounted:
	var triangle: Node
	var vertex_idx: int
	var old_local_pos: Vector2
	var new_local_pos: Vector2
	func _init(p_triangle: Node, p_vertex_idx: int, p_old_pos: Vector2, p_new_pos: Vector2) -> void:
		triangle = p_triangle
		vertex_idx = p_vertex_idx
		old_local_pos = p_old_pos
		new_local_pos = p_new_pos
	func execute() -> void:
		triangle.set_vertex_position(vertex_idx, new_local_pos)
	func undo() -> void:
		triangle.set_vertex_position(vertex_idx, old_local_pos)

class ColorCommand extends RefCounted:
	var triangle: Node
	var old_color: Color
	var new_color: Color
	func _init(p_triangle: Node, p_old_color: Color, p_new_color: Color) -> void:
		triangle = p_triangle
		old_color = p_old_color
		new_color = p_new_color
	func execute() -> void:
		triangle.fill_color = new_color
		triangle.queue_redraw()
	func undo() -> void:
		triangle.fill_color = old_color
		triangle.queue_redraw()

class LayerCommand extends RefCounted:
	var canvas: Node
	var triangle: Node
	var old_idx: int
	var new_idx: int
	func _init(p_canvas: Node, p_triangle: Node, p_old_idx: int, p_new_idx: int) -> void:
		canvas = p_canvas
		triangle = p_triangle
		old_idx = p_old_idx
		new_idx = p_new_idx
	func execute() -> void:
		canvas.set_triangle_index(triangle, new_idx)
	func undo() -> void:
		canvas.set_triangle_index(triangle, old_idx)

class ReorderChildrenCommand extends RefCounted:
	var canvas: Node
	var old_order: Array
	var new_order: Array
	func _init(p_canvas: Node, p_old_order: Array, p_new_order: Array) -> void:
		canvas = p_canvas
		old_order = p_old_order.duplicate()
		new_order = p_new_order.duplicate()
	func execute() -> void:
		canvas.apply_children_order(new_order)
	func undo() -> void:
		canvas.apply_children_order(old_order)

class BatchCreateCommand extends RefCounted:
	var canvas: Node
	var triangles: Array
	func _init(p_canvas: Node, p_triangles: Array) -> void:
		canvas = p_canvas
		triangles = p_triangles
	func execute() -> void:
		for t in triangles:
			if not t.get_parent():
				canvas.add_triangle_node(t)
	func undo() -> void:
		for t in triangles:
			if t.get_parent():
				canvas.remove_triangle_node(t)

class ClearAllCommand extends RefCounted:
	var canvas: Node
	var saved_triangles: Array
	func _init(p_canvas: Node, p_triangles: Array) -> void:
		canvas = p_canvas
		saved_triangles = p_triangles.duplicate()
	func execute() -> void:
		for t in saved_triangles:
			if t.get_parent():
				canvas.remove_triangle_node(t)
	func undo() -> void:
		for t in saved_triangles:
			if not t.get_parent():
				canvas.add_triangle_node(t)

class BatchDeleteCommand extends RefCounted:
	var canvas: Node
	var deleted_triangles: Array
	var old_indices: Dictionary
	func _init(p_canvas: Node, p_triangles: Array) -> void:
		canvas = p_canvas
		deleted_triangles = p_triangles.duplicate()
		old_indices = {}
		for t in deleted_triangles:
			old_indices[t] = canvas.get_triangle_index(t)
	func execute() -> void:
		for t in deleted_triangles:
			if t.get_parent():
				canvas.remove_triangle_node(t)
	func undo() -> void:
		var ordered: Array = deleted_triangles.duplicate()
		ordered.sort_custom(func(a: Node, b: Node) -> bool: return old_indices[a] < old_indices[b])
		for t in ordered:
			if not t.get_parent():
				canvas.add_triangle_node(t)
				canvas.set_triangle_index(t, old_indices[t])

class ReplaceProjectCommand extends RefCounted:
	var canvas: Node
	var old_triangles: Array
	var new_triangles: Array
	var old_canvas_size: Vector2
	var new_canvas_size: Vector2
	var old_selection: Array

	func _init(p_canvas: Node, p_new_triangles: Array, p_new_canvas_size: Vector2) -> void:
		canvas = p_canvas
		old_triangles = canvas.triangles.duplicate()
		new_triangles = p_new_triangles.duplicate()
		old_canvas_size = canvas.canvas_size
		new_canvas_size = p_new_canvas_size
		old_selection = canvas.selected_triangles.duplicate()

	func execute() -> void:
		canvas.select_triangle(null)
		for t in old_triangles:
			if t.get_parent():
				canvas.remove_triangle_node(t)
		canvas.set_canvas_size(new_canvas_size)
		for t in new_triangles:
			if not t.get_parent():
				canvas.add_triangle_node(t)
		canvas.select_triangle(null)

	func undo() -> void:
		canvas.select_triangle(null)
		for t in new_triangles:
			if t.get_parent():
				canvas.remove_triangle_node(t)
		canvas.set_canvas_size(old_canvas_size)
		for t in old_triangles:
			if not t.get_parent():
				canvas.add_triangle_node(t)
		canvas.select_triangles(old_selection)

class MultiColorCommand extends RefCounted:
	var triangles: Array
	var old_colors: Dictionary
	var new_color: Color
	func _init(p_triangles: Array, p_new_color: Color, p_old_colors: Dictionary = {}) -> void:
		triangles = p_triangles.duplicate()
		new_color = p_new_color
		if not p_old_colors.is_empty():
			old_colors = p_old_colors.duplicate()
		else:
			old_colors = {}
			for t in triangles:
				old_colors[t] = t.fill_color
	func execute() -> void:
		for t in triangles:
			t.fill_color = new_color
			t.queue_redraw()
	func undo() -> void:
		for t in triangles:
			if old_colors.has(t):
				t.fill_color = old_colors[t]
				t.queue_redraw()

class MultiOutlineColorCommand extends RefCounted:
	var triangles: Array
	var old_colors: Dictionary
	var new_color: Color

	func _init(p_triangles: Array, p_new_color: Color, p_old_colors: Dictionary = {}) -> void:
		triangles = p_triangles.duplicate()
		new_color = p_new_color
		if not p_old_colors.is_empty():
			old_colors = p_old_colors.duplicate()
		else:
			old_colors = {}
			for t in triangles:
				old_colors[t] = t.outline_color

	func execute() -> void:
		for t in triangles:
			t.outline_color = new_color
			t.queue_redraw()

	func undo() -> void:
		for t in triangles:
			if old_colors.has(t):
				t.outline_color = old_colors[t]
				t.queue_redraw()


class TransformVerticesCommand extends RefCounted:
	var triangle: Node
	var old_verts: Array
	var new_verts: Array
	func _init(p_triangle: Node, p_old_verts: Array, p_new_verts: Array) -> void:
		triangle = p_triangle
		old_verts = p_old_verts
		new_verts = p_new_verts
	func execute() -> void:
		triangle.vertex_a = new_verts[0]
		triangle.vertex_b = new_verts[1]
		triangle.vertex_c = new_verts[2]
		triangle.geometry_changed.emit(triangle)
		triangle.queue_redraw()
	func undo() -> void:
		triangle.vertex_a = old_verts[0]
		triangle.vertex_b = old_verts[1]
		triangle.vertex_c = old_verts[2]
		triangle.geometry_changed.emit(triangle)
		triangle.queue_redraw()

class GroupCommand extends RefCounted:
	var canvas: Node
	var triangles: Array
	var new_group_id: String
	var old_group_ids: Dictionary
	func _init(p_canvas: Node, p_triangles: Array, p_new_group_id: String) -> void:
		canvas = p_canvas
		triangles = p_triangles.duplicate()
		new_group_id = p_new_group_id
		old_group_ids = {}
		for t in triangles:
			old_group_ids[t] = t.group_id
	func execute() -> void:
		for t in triangles:
			t.group_id = new_group_id
			t.queue_redraw()
		if canvas and canvas.has_method("queue_redraw"):
			canvas.queue_redraw()
	func undo() -> void:
		for t in triangles:
			t.group_id = old_group_ids.get(t, "")
			t.queue_redraw()
		if canvas and canvas.has_method("queue_redraw"):
			canvas.queue_redraw()

class UngroupCommand extends RefCounted:
	var canvas: Node
	var triangles: Array
	var old_group_ids: Dictionary
	func _init(p_canvas: Node, p_triangles: Array) -> void:
		canvas = p_canvas
		triangles = p_triangles.duplicate()
		old_group_ids = {}
		for t in triangles:
			old_group_ids[t] = t.group_id
	func execute() -> void:
		for t in triangles:
			t.group_id = ""
			t.queue_redraw()
		if canvas and canvas.has_method("queue_redraw"):
			canvas.queue_redraw()
	func undo() -> void:
		for t in triangles:
			t.group_id = old_group_ids.get(t, "")
			t.queue_redraw()
		if canvas and canvas.has_method("queue_redraw"):
			canvas.queue_redraw()

class MultiMoveCommand extends RefCounted:
	var triangles: Array
	var start_positions: Dictionary
	var end_positions: Dictionary
	func _init(p_triangles: Array, p_starts: Dictionary, p_ends: Dictionary) -> void:
		triangles = p_triangles.duplicate()
		start_positions = p_starts.duplicate()
		end_positions = p_ends.duplicate()
	func execute() -> void:
		for t in triangles:
			if end_positions.has(t):
				t.position = end_positions[t]
				t.geometry_changed.emit(t)
				t.queue_redraw()
	func undo() -> void:
		for t in triangles:
			if start_positions.has(t):
				t.position = start_positions[t]
				t.geometry_changed.emit(t)
				t.queue_redraw()

class MultiTransformVerticesCommand extends RefCounted:
	var triangles: Array
	var start_verts: Dictionary
	var end_verts: Dictionary
	var start_positions: Dictionary
	var end_positions: Dictionary

	func _init(p_triangles: Array, p_starts: Dictionary, p_ends: Dictionary, p_pos_starts: Dictionary = {}, p_pos_ends: Dictionary = {}) -> void:
		triangles = p_triangles.duplicate()
		start_verts = p_starts.duplicate()
		end_verts = p_ends.duplicate()
		start_positions = p_pos_starts.duplicate()
		end_positions = p_pos_ends.duplicate()

	func execute() -> void:
		for t in triangles:
			if end_positions.has(t):
				t.position = end_positions[t]
			if end_verts.has(t):
				var verts: Array = end_verts[t]
				t.vertex_a = verts[0]
				t.vertex_b = verts[1]
				t.vertex_c = verts[2]
				t.geometry_changed.emit(t)
				t.queue_redraw()

	func undo() -> void:
		for t in triangles:
			if start_positions.has(t):
				t.position = start_positions[t]
			if start_verts.has(t):
				var verts: Array = start_verts[t]
				t.vertex_a = verts[0]
				t.vertex_b = verts[1]
				t.vertex_c = verts[2]
				t.geometry_changed.emit(t)
				t.queue_redraw()

