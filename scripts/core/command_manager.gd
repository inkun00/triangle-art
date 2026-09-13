class_name CommandManager
extends RefCounted

## Undo/Redo command manager for Triangle Art actions.

signal state_changed

var undo_stack: Array[Variant] = []
var redo_stack: Array[Variant] = []
var max_history: int = 60

func can_undo() -> bool:
	return undo_stack.size() > 0

func can_redo() -> bool:
	return redo_stack.size() > 0

func push_and_execute(command: Variant) -> void:
	command.execute()
	undo_stack.append(command)
	if undo_stack.size() > max_history:
		undo_stack.pop_front()
	redo_stack.clear()
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
	state_changed.emit()
