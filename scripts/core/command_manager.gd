class_name CommandManager
extends RefCounted

## Undo/Redo command manager for Triangle Art actions.

const TriangleNode = preload("res://scenes/triangle/triangle_node.gd")

signal state_changed

var undo_stack: Array[Variant] = []
var redo_stack: Array[Variant] = []
var max_history: int = 60
var _tracked_triangles: Dictionary = {}

func can_undo() -> bool:
	return undo_stack.size() > 0

func can_redo() -> bool:
	return redo_stack.size() > 0

func push_and_execute(command: Variant) -> void:
	command.execute()
	_remember_command_nodes(command)
	undo_stack.append(command)
	if undo_stack.size() > max_history:
		undo_stack.pop_front()
	redo_stack.clear()
	_cleanup_detached_triangles()
	state_changed.emit()

func undo() -> void:
	if undo_stack.is_empty():
		return
	var cmd: Variant = undo_stack.pop_back()
	cmd.undo()
	redo_stack.append(cmd)
	state_changed.emit()

func redo() -> void:
	if redo_stack.is_empty():
		return
	var cmd: Variant = redo_stack.pop_back()
	cmd.execute()
	undo_stack.append(cmd)
	state_changed.emit()

func clear() -> void:
	undo_stack.clear()
	redo_stack.clear()
	_cleanup_detached_triangles()
	state_changed.emit()

func _remember_command_nodes(command: Variant) -> void:
	for property in command.get_property_list():
		if (int(property["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0:
			_collect_triangles(command.get(property["name"]), _tracked_triangles)

func _collect_triangles(value: Variant, result: Dictionary) -> void:
	if value is TriangleNode:
		if is_instance_valid(value):
			result[value] = true
	elif value is Array:
		for item in value:
			_collect_triangles(item, result)
	elif value is Dictionary:
		for key in value:
			_collect_triangles(key, result)
			_collect_triangles(value[key], result)

func _cleanup_detached_triangles() -> void:
	var referenced: Dictionary = {}
	for command in undo_stack:
		for property in command.get_property_list():
			if (int(property["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0:
				_collect_triangles(command.get(property["name"]), referenced)
	for command in redo_stack:
		for property in command.get_property_list():
			if (int(property["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0:
				_collect_triangles(command.get(property["name"]), referenced)
	for triangle in _tracked_triangles.keys():
		if not is_instance_valid(triangle):
			_tracked_triangles.erase(triangle)
		elif triangle.get_parent() == null and not referenced.has(triangle):
			triangle.free()
			_tracked_triangles.erase(triangle)
