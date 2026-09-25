extends "res://scenes/canvas/drawing_canvas_core.gd"

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event
		if st.pressed:
			touch_points[st.index] = st.position
			if touch_points.size() == 2:
				var keys = touch_points.keys()
				var p0: Vector2 = touch_points[keys[0]]
				var p1: Vector2 = touch_points[keys[1]]
				touch_start_dist = maxf(p0.distance_to(p1), 10.0)
				touch_start_zoom = zoom_level
				touch_start_mid = (p0 + p1) / 2.0
				touch_start_pan = pan_offset
			elif touch_points.size() == 1 and st.index == 0:
				var local_pos: Vector2 = st.position
				var world_pos: Vector2 = canvas_to_world(local_pos)
				var now: int = Time.get_ticks_msec()
				var is_double: bool = st.double_tap
				if not is_double and last_touch_down_time_msec > 0:
					var time_diff: int = now - last_touch_down_time_msec
					var dist: float = local_pos.distance_to(last_touch_down_local_pos)
					if time_diff <= DOUBLE_TAP_MAX_TIME_MSEC and dist <= DOUBLE_TAP_MAX_DIST:
						is_double = true

				if is_double:
					var screen_pos: Vector2 = get_screen_transform() * local_pos
					if _handle_triangle_double_action(world_pos, screen_pos):
						last_touch_down_time_msec = 0
						last_popup_trigger_time_msec = now
						accept_event()
						return

				last_touch_down_time_msec = now
				last_touch_down_local_pos = local_pos
		else:
			touch_points.erase(st.index)
			if touch_points.size() < 2:
				touch_start_dist = 0.0

	elif event is InputEventScreenDrag:
		var sd: InputEventScreenDrag = event
		touch_points[sd.index] = sd.position
		if touch_points.size() >= 2:
			var keys = touch_points.keys()
			var p0: Vector2 = touch_points[keys[0]]
			var p1: Vector2 = touch_points[keys[1]]
			var cur_dist: float = maxf(p0.distance_to(p1), 10.0)
			var cur_mid: Vector2 = (p0 + p1) / 2.0
			pan_offset = touch_start_pan + (cur_mid - touch_start_mid)
			if touch_start_dist > 0.0:
				var ratio: float = cur_dist / touch_start_dist
				set_zoom(touch_start_zoom * ratio, cur_mid)
			else:
				_apply_zoom_and_pan()
			accept_event()
			return
		elif touch_points.size() == 1:
			if sd.position.distance_to(last_touch_down_local_pos) > DOUBLE_TAP_MAX_DIST:
				last_touch_down_time_msec = 0

	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		var local_pos: Vector2 = mb.position
		var is_shift: bool = mb.shift_pressed or mb.ctrl_pressed

		# 1. Mouse wheel zoom centered at cursor
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			set_zoom(zoom_level * 1.15, local_pos)
			accept_event()
			return
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			set_zoom(zoom_level / 1.15, local_pos)
			accept_event()
			return

		# 2. Middle mouse button panning
		if mb.button_index == MOUSE_BUTTON_MIDDLE:
			if mb.pressed:
				is_panning = true
				pan_start_mouse = local_pos
				pan_start_offset = pan_offset
			else:
				is_panning = false
			accept_event()
			return

		var world_pos: Vector2 = canvas_to_world(local_pos)

		if mb.button_index == MOUSE_BUTTON_LEFT:
			# Space + Left Click Pan
			if Input.is_key_pressed(KEY_SPACE):
				if mb.pressed:
					is_panning = true
					pan_start_mouse = local_pos
					pan_start_offset = pan_offset
				else:
					is_panning = false
				accept_event()
				return

			if mb.pressed:
				var now: int = Time.get_ticks_msec()
				# Debounce check to avoid duplicate trigger when touch emulation emits both touch and mouse
				if now - last_popup_trigger_time_msec < 250:
					accept_event()
					return

				var is_double: bool = mb.double_click
				if not is_double and last_mouse_click_time_msec > 0:
					var time_diff: int = now - last_mouse_click_time_msec
					var dist: float = local_pos.distance_to(last_mouse_click_local_pos)
					if time_diff <= DOUBLE_CLICK_MAX_TIME_MSEC and dist <= DOUBLE_CLICK_MAX_DIST:
						is_double = true

				if is_double:
					if _handle_triangle_double_action(world_pos, mb.global_position):
						last_mouse_click_time_msec = 0
						last_popup_trigger_time_msec = now
						accept_event()
						return

				last_mouse_click_time_msec = now
				last_mouse_click_local_pos = local_pos

				_handle_mouse_press(world_pos, is_shift, local_pos)
			else:
				_handle_mouse_release(world_pos, local_pos)
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			_handle_right_click(world_pos, mb.global_position)
			accept_event()

	elif event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event
		var local_pos: Vector2 = mm.position
		if local_pos.distance_to(last_mouse_click_local_pos) > DOUBLE_CLICK_MAX_DIST:
			last_mouse_click_time_msec = 0

		if is_panning:
			pan_offset = pan_start_offset + (local_pos - pan_start_mouse)
			_apply_zoom_and_pan()
			accept_event()
			return

		var world_mouse: Vector2 = canvas_to_world(local_pos)

		if is_marquee_selecting:
			marquee_current = local_pos
			queue_redraw()
			accept_event()
		elif is_dragging_group_rotation:
			var cur_angle: float = (world_mouse - drag_multi_group_center).angle()
			var delta_rad: float = cur_angle - drag_multi_start_angle
			if snap_enabled:
				var deg: float = rad_to_deg(delta_rad)
				deg = roundf(deg / 15.0) * 15.0
				delta_rad = deg_to_rad(deg)
			var prev_rot: float = current_group_rotation_deg
			current_group_rotation_deg = roundf(rad_to_deg(delta_rad))
			if prev_rot != current_group_rotation_deg and SoundManager.instance:
				SoundManager.instance.play_rotate_tick()

			for t in selected_triangles:
				if is_instance_valid(t) and drag_multi_start_positions.has(t):
					var start_pos: Vector2 = drag_multi_start_positions[t]
					var raw_verts: Array = drag_multi_start_verts[t]
					var start_verts: Array[Vector2] = [raw_verts[0], raw_verts[1], raw_verts[2]]
					var local_c: Vector2 = drag_multi_start_centroids[t]
					var world_c_0: Vector2 = start_pos + local_c
					var new_world_c: Vector2 = drag_multi_group_center + (world_c_0 - drag_multi_group_center).rotated(delta_rad)
					t.position = new_world_c - local_c

					var new_verts: Array[Vector2] = TriangleMath.rotate_vertices(start_verts, delta_rad, local_c)
					t.vertex_a = new_verts[0]
					t.vertex_b = new_verts[1]
					t.vertex_c = new_verts[2]

					t.geometry_changed.emit(t)
					t.queue_redraw()

			queue_redraw()
			accept_event()
		elif is_dragging_group_scale:
			var cur_dist: float = world_mouse.distance_to(drag_group_scale_center)
			var raw_factor: float = cur_dist / maxf(drag_group_scale_start_dist, 1.0)
			var factor: float = clampf(raw_factor, 0.15, 8.0)
			if snap_enabled:
				factor = roundf(factor * 10.0) / 10.0
			current_group_scale_factor = factor

			for t in selected_triangles:
				if is_instance_valid(t) and drag_group_scale_start_positions.has(t) and drag_group_scale_start_verts.has(t):
					var s_pos: Vector2 = drag_group_scale_start_positions[t]
					var s_verts: Array = drag_group_scale_start_verts[t]
					var new_pos: Vector2 = drag_group_scale_center + (s_pos - drag_group_scale_center) * factor
					var new_a: Vector2 = s_verts[0] * factor
					var new_b: Vector2 = s_verts[1] * factor
					var new_c: Vector2 = s_verts[2] * factor

					if TriangleMath.is_valid_triangle(new_a, new_b, new_c, 5.0):
						t.position = new_pos
						t.vertex_a = new_a
						t.vertex_b = new_b
						t.vertex_c = new_c
						t.geometry_changed.emit(t)
						t.queue_redraw()

			queue_redraw()
			accept_event()
		elif active_interacting_triangle and is_instance_valid(active_interacting_triangle):
			if active_interacting_triangle.current_drag == TriangleNode.DragMode.BODY and selected_triangles.size() > 1:
				var delta: Vector2 = world_mouse - active_interacting_triangle.drag_start_mouse
				for st in selected_triangles:
					if is_instance_valid(st) and drag_multi_start_positions.has(st):
						var raw_pos: Vector2 = drag_multi_start_positions[st] + delta
						st.position = TriangleMath.snap_point(raw_pos, grid_step) if snap_enabled else raw_pos

				var other_candidates: Array[TriangleNode] = []
				for t in triangles:
					if not selected_triangles.has(t) and is_instance_valid(t):
						other_candidates.append(t)
				var snap_res = TriangleMath.find_inter_triangle_snap(active_interacting_triangle, other_candidates, 14.0 / zoom_level)
				if snap_res["snapped"]:
					var s_offset: Vector2 = snap_res["offset"]
					for st in selected_triangles:
						if is_instance_valid(st):
							st.position += s_offset
					active_snap_indicators = snap_res["snap_points"]
					if not _was_snapped:
						if SoundManager.instance:
							SoundManager.instance.play_snap()
						_was_snapped = true
				else:
					active_snap_indicators.clear()
					_was_snapped = false

				for st in selected_triangles:
					if is_instance_valid(st):
						st.geometry_changed.emit(st)
						st.queue_redraw()
			elif active_interacting_triangle.current_drag == TriangleNode.DragMode.BODY:
				active_interacting_triangle.handle_input_drag(world_mouse)
				var snap_res = TriangleMath.find_inter_triangle_snap(active_interacting_triangle, triangles, 14.0 / zoom_level)
				if snap_res["snapped"]:
					active_interacting_triangle.position += snap_res["offset"]
					active_snap_indicators = snap_res["snap_points"]
					active_interacting_triangle.geometry_changed.emit(active_interacting_triangle)
					active_interacting_triangle.queue_redraw()
					if not _was_snapped:
						if SoundManager.instance:
							SoundManager.instance.play_snap()
						_was_snapped = true
				else:
					active_snap_indicators.clear()
					_was_snapped = false
			elif active_interacting_triangle.current_drag in [TriangleNode.DragMode.VERTEX_A, TriangleNode.DragMode.VERTEX_B, TriangleNode.DragMode.VERTEX_C]:
				var lock_scale: bool = is_scale_locked or active_interacting_triangle.is_scale_locked or Input.is_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_ALT)
				if not lock_scale:
					var v_snap = TriangleMath.find_vertex_snap(world_mouse, active_interacting_triangle, triangles, 14.0 / zoom_level)
					if v_snap["snapped"]:
						active_interacting_triangle.handle_input_drag(v_snap["snapped_pos"])
						active_snap_indicators = v_snap["snap_points"]
						if not _was_snapped:
							if SoundManager.instance:
								SoundManager.instance.play_snap()
							_was_snapped = true
					else:
						active_interacting_triangle.handle_input_drag(world_mouse)
						active_snap_indicators.clear()
						_was_snapped = false
				else:
					active_interacting_triangle.handle_input_drag(world_mouse)
					active_snap_indicators.clear()
					_was_snapped = false
			else:
				active_interacting_triangle.handle_input_drag(world_mouse)
				active_snap_indicators.clear()

			queue_redraw()
			accept_event()
		else:
			_update_hover_cursor(world_mouse)

func _update_hover_cursor(world_mouse: Vector2) -> void:
	if is_dragging_group_rotation or (active_interacting_triangle and active_interacting_triangle.current_drag == TriangleNode.DragMode.ROTATION):
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		return
	if is_dragging_group_scale:
		mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
		return
	if active_interacting_triangle and active_interacting_triangle.current_drag == TriangleNode.DragMode.BODY:
		mouse_default_cursor_shape = Control.CURSOR_MOVE
		return
	if active_interacting_triangle and active_interacting_triangle.current_drag in [TriangleNode.DragMode.VERTEX_A, TriangleNode.DragMode.VERTEX_B, TriangleNode.DragMode.VERTEX_C]:
		mouse_default_cursor_shape = Control.CURSOR_CROSS
		return

	if selected_triangles.size() > 1 and hit_test_group_scale_handle(world_mouse) != -1:
		mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
		return
	if selected_triangles.size() > 1 and hit_test_group_rotation_handle(world_mouse):
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		return
	if selected_triangle and is_instance_valid(selected_triangle):
		if selected_triangle.hit_test_rotation_handle(world_mouse):
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			return
		if selected_triangle.hit_test_handle(world_mouse) != -1:
			mouse_default_cursor_shape = Control.CURSOR_CROSS
			return
		if selected_triangle.hit_test_body(world_mouse):
			mouse_default_cursor_shape = Control.CURSOR_MOVE
			return
	for st in selected_triangles:
		if is_instance_valid(st) and st.hit_test_body(world_mouse):
			mouse_default_cursor_shape = Control.CURSOR_MOVE
			return
	mouse_default_cursor_shape = Control.CURSOR_ARROW

func _setup_context_menu() -> void:
	context_menu = PopupMenu.new()
	context_menu.name = "CanvasContextMenu"
	context_menu.id_pressed.connect(_on_context_menu_id_pressed)
	context_menu.add_theme_constant_override("v_separation", 6)
	context_menu.add_theme_font_size_override("font_size", 14)
	add_child(context_menu)

func get_triangle_at_point(world_pos: Vector2) -> TriangleNode:
	# 1. Check selected triangles first (they are highlighted and have handles)
	for st in selected_triangles:
		if is_instance_valid(st) and (st.hit_test_body(world_pos) or st.hit_test_handle(world_pos) != -1 or st.hit_test_rotation_handle(world_pos)):
			return st
	# 2. Check all triangles from top (last drawn) to bottom (first drawn)
	for i in range(triangles.size() - 1, -1, -1):
		var t: TriangleNode = triangles[i]
		if is_instance_valid(t) and (t.hit_test_body(world_pos) or t.hit_test_handle(world_pos) != -1):
			return t
	return null

func _handle_triangle_double_action(world_pos: Vector2, global_pos: Vector2) -> bool:
	var target_tri: TriangleNode = get_triangle_at_point(world_pos)
	if not target_tri:
		return false

	# 1. Update selection:
	# If target is already part of the current selection, maintain it; otherwise, select it exclusively.
	if not selected_triangles.has(target_tri):
		select_triangle(target_tri)

	# 2. Cancel and reset any drag that might have been started by the click/tap
	if active_interacting_triangle and is_instance_valid(active_interacting_triangle):
		if active_interacting_triangle.current_drag == TriangleNode.DragMode.BODY:
			active_interacting_triangle.position = active_interacting_triangle.drag_start_pos
			active_interacting_triangle.geometry_changed.emit(active_interacting_triangle)
			active_interacting_triangle.queue_redraw()
		active_interacting_triangle.current_drag = TriangleNode.DragMode.NONE
		active_interacting_triangle = null

	is_marquee_selecting = false
	is_dragging_group_rotation = false
	is_dragging_group_scale = false
	drag_multi_start_positions.clear()

	last_right_click_pos = world_pos

	# 3. Audio feedback
	if SoundManager.instance:
		SoundManager.instance.play_click()

	# 4. Display popup menu at touch/click position
	_show_context_menu(global_pos)
	context_menu_opened.emit(target_tri, global_pos)
	return true

func _handle_right_click(world_pos: Vector2, global_pos: Vector2) -> void:
	last_right_click_pos = world_pos

	# 1. Check if clicked inside an already selected triangle
	var clicked_selected: bool = false
	for st in selected_triangles:
		if is_instance_valid(st) and st.hit_test_body(world_pos):
			clicked_selected = true
			break

	if not clicked_selected:
		# Check other triangles (top to bottom)
		var hit_triangle: TriangleNode = null
		for i in range(triangles.size() - 1, -1, -1):
			var t: TriangleNode = triangles[i]
			if is_instance_valid(t) and t.hit_test_body(world_pos):
				hit_triangle = t
				break
		if hit_triangle:
			select_triangle(hit_triangle)
		else:
			select_triangle(null)

	_show_context_menu(global_pos)

func _show_context_menu(global_pos: Vector2) -> void:
	if not context_menu:
		return
	context_menu.clear()

	var has_sel: bool = not selected_triangles.is_empty()

	if has_sel:
		context_menu.add_item("복제 (Ctrl+D)", MenuAction.DUPLICATE)
		context_menu.add_item("삭제 (Delete)", MenuAction.DELETE)
		context_menu.add_item("정삼각형화", MenuAction.EQUILATERAL)
		context_menu.add_separator()

		var can_group: bool = selected_triangles.size() >= 2
		var can_ungroup: bool = has_group_in_selection()

		context_menu.add_item("그룹화 (Ctrl+G)", MenuAction.GROUP)
		context_menu.set_item_disabled(context_menu.get_item_count() - 1, not can_group)

		context_menu.add_item("그룹 해제 (Ctrl+Shift+G)", MenuAction.UNGROUP)
		context_menu.set_item_disabled(context_menu.get_item_count() - 1, not can_ungroup)
		context_menu.add_separator()

		context_menu.add_item("회전 45°", MenuAction.ROTATE)
		context_menu.add_item("좌우 반전", MenuAction.FLIP_H)
		context_menu.add_item("상하 반전", MenuAction.FLIP_V)
		context_menu.add_separator()

		context_menu.add_item("맨 앞으로 가져오기 (Ctrl+Shift+])", MenuAction.LAYER_FRONT)
		context_menu.add_item("앞으로 가져오기 (Ctrl+])", MenuAction.LAYER_UP)
		context_menu.add_item("뒤로 보내기 (Ctrl+[)", MenuAction.LAYER_DOWN)
		context_menu.add_item("맨 뒤로 보내기 (Ctrl+Shift+[)", MenuAction.LAYER_BACK)
		context_menu.add_separator()

		context_menu.add_item("크기 확대 (+20%)", MenuAction.SCALE_UP)
		context_menu.add_item("크기 축소 (-20%)", MenuAction.SCALE_DOWN)
		context_menu.add_item("비율 고정: " + ("켜짐" if is_scale_locked else "꺼짐"), MenuAction.TOGGLE_SCALE_LOCK)
		context_menu.add_separator()
		context_menu.add_item("× 테두리선 삭제 (외곽선 없음)", MenuAction.REMOVE_OUTLINE)
	else:
		context_menu.add_item("+ 새 정삼각형 생성", MenuAction.NEW_TRIANGLE)
		context_menu.add_separator()
		context_menu.add_item("실행 취소 (Ctrl+Z)", MenuAction.UNDO)
		context_menu.add_item("다시 실행 (Ctrl+Y)", MenuAction.REDO)
		context_menu.add_separator()
		context_menu.add_item("비율 고정: " + ("켜짐" if is_scale_locked else "꺼짐"), MenuAction.TOGGLE_SCALE_LOCK)
		context_menu.add_separator()
		context_menu.add_item("캔버스 전체 삭제", MenuAction.CLEAR_ALL)

	context_menu.reset_size()
	var menu_size: Vector2 = context_menu.size
	var vp_rect: Rect2 = get_viewport_rect()
	var pos: Vector2 = global_pos
	if vp_rect.size.x > 50 and vp_rect.size.y > 50:
		if pos.x + menu_size.x > vp_rect.size.x:
			pos.x = maxf(10.0, vp_rect.size.x - menu_size.x - 10.0)
		if pos.y + menu_size.y > vp_rect.size.y:
			pos.y = maxf(10.0, vp_rect.size.y - menu_size.y - 10.0)
	context_menu.popup(Rect2i(Vector2i(pos), Vector2i.ZERO))

func _on_context_menu_id_pressed(id: int) -> void:
	match id:
		MenuAction.DUPLICATE:
			duplicate_selected()
			toast_requested.emit("삼각형이 복제되었습니다 (복제).")
		MenuAction.DELETE:
			delete_selected()
			toast_requested.emit("삼각형이 삭제되었습니다 (삭제).")
		MenuAction.EQUILATERAL:
			make_selected_equilateral()
			toast_requested.emit("정삼각형으로 변환되었습니다.")
		MenuAction.GROUP:
			group_selected()
			toast_requested.emit("선택한 삼각형들이 그룹화되었습니다 (그룹화).")
		MenuAction.UNGROUP:
			ungroup_selected()
			toast_requested.emit("삼각형 그룹이 해제되었습니다 (그룹 해제).")
		MenuAction.ROTATE:
			rotate_selected(45.0)
			toast_requested.emit("삼각형을 45° 회전했습니다.")
		MenuAction.FLIP_H:
			flip_selected_h()
			toast_requested.emit("삼각형을 좌우 반전했습니다.")
		MenuAction.FLIP_V:
			flip_selected_v()
			toast_requested.emit("삼각형을 상하 반전했습니다.")
		MenuAction.LAYER_FRONT:
			bring_to_front()
			toast_requested.emit("맨 앞으로 가져왔습니다.")
		MenuAction.LAYER_UP:
			bring_forward()
			toast_requested.emit("한 단계 앞으로 가져왔습니다.")
		MenuAction.LAYER_DOWN:
			send_backward()
			toast_requested.emit("한 단계 뒤로 보냈습니다.")
		MenuAction.LAYER_BACK:
			send_to_back()
			toast_requested.emit("맨 뒤로 보냈습니다.")
		MenuAction.SCALE_UP:
			scale_selected(1.2)
			toast_requested.emit("삼각형 크기를 20% 확대했습니다.")
		MenuAction.SCALE_DOWN:
			scale_selected(0.8)
			toast_requested.emit("삼각형 크기를 20% 축소했습니다.")
		MenuAction.TOGGLE_SCALE_LOCK:
			set_scale_locked(!is_scale_locked)
			toast_requested.emit("삼각형 비율 고정: " + ("켜짐" if is_scale_locked else "꺼짐"))
		MenuAction.REMOVE_OUTLINE:
			remove_selected_outline()
			toast_requested.emit("테두리가 삭제되었습니다 (테두리 없음).")
		MenuAction.NEW_TRIANGLE:
			var target_pos: Vector2 = last_right_click_pos
			if snap_enabled:
				target_pos = TriangleMath.snap_point(target_pos, grid_step)
			add_new_equilateral_triangle(target_pos)
			toast_requested.emit("클릭한 위치에 새 정삼각형이 생성되었습니다.")
		MenuAction.UNDO:
			undo_requested.emit()
		MenuAction.REDO:
			redo_requested.emit()
		MenuAction.CLEAR_ALL:
			clear_all_triangles()
			toast_requested.emit("캔버스를 모두 비웠습니다.")

func _handle_mouse_press(world_pos: Vector2, is_shift: bool = false, local_pos: Vector2 = Vector2.ZERO) -> void:
	drag_multi_start_positions.clear()
	active_snap_indicators.clear()

	# 0. Check group handles first if multi-selected
	if selected_triangles.size() > 1:
		var corner_idx: int = hit_test_group_scale_handle(world_pos)
		if corner_idx != -1:
			_start_group_scale_drag(world_pos, corner_idx)
			queue_redraw()
			return
		if hit_test_group_rotation_handle(world_pos):
			_start_group_rotation_drag(world_pos)
			queue_redraw()
			return

	# 1. First check if any already selected triangle handle or body was clicked
	for st in selected_triangles:
		if is_instance_valid(st) and st.handle_input_press(world_pos):
			active_interacting_triangle = st
			selected_triangle = st
			if selected_triangles.size() > 1:
				if st.current_drag == TriangleNode.DragMode.ROTATION:
					st.current_drag = TriangleNode.DragMode.NONE
					_start_group_rotation_drag(world_pos)
					queue_redraw()
					return
				elif st.current_drag == TriangleNode.DragMode.BODY:
					for t in selected_triangles:
						drag_multi_start_positions[t] = t.position
			queue_redraw()
			return

	# 2. Iterate from top to bottom through other triangles
	for i in range(triangles.size() - 1, -1, -1):
		var t: TriangleNode = triangles[i]
		if not selected_triangles.has(t) and is_instance_valid(t):
			if t.handle_input_press(world_pos):
				select_triangle(t, is_shift)
				active_interacting_triangle = t
				if selected_triangles.size() > 1:
					if t.current_drag == TriangleNode.DragMode.ROTATION:
						t.current_drag = TriangleNode.DragMode.NONE
						_start_group_rotation_drag(world_pos)
						queue_redraw()
						return
					elif t.current_drag == TriangleNode.DragMode.BODY:
						for st in selected_triangles:
							drag_multi_start_positions[st] = st.position
				queue_redraw()
				return

	# 3. Clicked on blank canvas -> deselect unless shift
	if not is_shift:
		select_triangle(null)

	is_marquee_selecting = true
	marquee_start = local_pos
	marquee_current = local_pos
	active_interacting_triangle = null
	queue_redraw()

func _handle_mouse_release(world_pos: Vector2, local_pos: Vector2 = Vector2.ZERO) -> void:
	active_snap_indicators.clear()

	if is_dragging_group_scale:
		is_dragging_group_scale = false
		if absf(current_group_scale_factor - 1.0) > 0.02:
			var starts: Dictionary = drag_group_scale_start_verts.duplicate()
			var pos_starts: Dictionary = drag_group_scale_start_positions.duplicate()
			var ends: Dictionary = {}
			var pos_ends: Dictionary = {}
			for t in selected_triangles:
				if is_instance_valid(t):
					ends[t] = [t.vertex_a, t.vertex_b, t.vertex_c]
					pos_ends[t] = t.position
			var cmd = TriangleCommands.MultiTransformVerticesCommand.new(selected_triangles, starts, ends, pos_starts, pos_ends)
			action_performed.emit(cmd)
		drag_group_scale_start_positions.clear()
		drag_group_scale_start_verts.clear()
		current_group_scale_factor = 1.0
		queue_redraw()
		return

	if is_dragging_group_rotation:
		is_dragging_group_rotation = false
		if absf(current_group_rotation_deg) > 0.05:
			var starts: Dictionary = drag_multi_start_verts.duplicate()
			var pos_starts: Dictionary = drag_multi_start_positions.duplicate()
			var ends: Dictionary = {}
			var pos_ends: Dictionary = {}
			for t in selected_triangles:
				if is_instance_valid(t):
					ends[t] = [t.vertex_a, t.vertex_b, t.vertex_c]
					pos_ends[t] = t.position
			var cmd = TriangleCommands.MultiTransformVerticesCommand.new(selected_triangles, starts, ends, pos_starts, pos_ends)
			action_performed.emit(cmd)
		drag_multi_start_positions.clear()
		drag_multi_start_verts.clear()
		drag_multi_start_centroids.clear()
		current_group_rotation_deg = 0.0
		queue_redraw()
		return

	if is_marquee_selecting:
		is_marquee_selecting = false
		var m_min: Vector2 = Vector2(minf(marquee_start.x, marquee_current.x), minf(marquee_start.y, marquee_current.y))
		var m_max: Vector2 = Vector2(maxf(marquee_start.x, marquee_current.x), maxf(marquee_start.y, marquee_current.y))
		var w_min: Vector2 = canvas_to_world(m_min)
		var w_max: Vector2 = canvas_to_world(m_max)
		var w_rect: Rect2 = Rect2(w_min, w_max - w_min)

		if w_rect.size.x > 5.0 and w_rect.size.y > 5.0:
			var newly_selected: Array[TriangleNode] = []
			for t in triangles:
				if is_instance_valid(t):
					var c: Vector2 = t.position + t.get_centroid()
					var va: Vector2 = t.position + t.vertex_a
					var vb: Vector2 = t.position + t.vertex_b
					var vc: Vector2 = t.position + t.vertex_c
					if w_rect.has_point(c) or w_rect.has_point(va) or w_rect.has_point(vb) or w_rect.has_point(vc):
						newly_selected.append(t)
			if not newly_selected.is_empty():
				select_triangles(newly_selected)
		queue_redraw()

	if active_interacting_triangle and is_instance_valid(active_interacting_triangle):
		if active_interacting_triangle.current_drag == TriangleNode.DragMode.BODY and selected_triangles.size() > 1 and not drag_multi_start_positions.is_empty():
			var has_moved: bool = false
			var end_positions: Dictionary = {}
			for st in selected_triangles:
				if is_instance_valid(st):
					end_positions[st] = st.position
					if drag_multi_start_positions.get(st, st.position) != st.position:
						has_moved = true
			if has_moved:
				var cmd = TriangleCommands.MultiMoveCommand.new(selected_triangles, drag_multi_start_positions, end_positions)
				action_performed.emit(cmd)
			active_interacting_triangle.current_drag = TriangleNode.DragMode.NONE
		else:
			active_interacting_triangle.handle_input_release(world_pos)

		active_interacting_triangle = null
		drag_multi_start_positions.clear()
		_was_snapped = false
		queue_redraw()

func rotate_selected(angle_deg: float) -> void:
	if SoundManager.instance:
		SoundManager.instance.play_rotate_tick()
	if selected_triangles.size() > 1 or (selected_triangle and not selected_triangle.group_id.is_empty()):
		if selected_triangles.size() <= 1 and selected_triangle and not selected_triangle.group_id.is_empty():
			var expanded: Array[TriangleNode] = []
			for t in triangles:
				if is_instance_valid(t) and t.group_id == selected_triangle.group_id:
					expanded.append(t)
			if expanded.size() > 1:
				select_triangles(expanded)

		# Rotate all selected triangles around group centroid
		var group_center: Vector2 = get_group_center()

		var starts: Dictionary = {}
		var ends: Dictionary = {}
		var pos_starts: Dictionary = {}
		var pos_ends: Dictionary = {}
		var rad: float = deg_to_rad(angle_deg)

		for t in selected_triangles:
			var old_verts: Array[Vector2] = [t.vertex_a, t.vertex_b, t.vertex_c]
			var local_centroid: Vector2 = t.get_centroid()
			var world_centroid: Vector2 = t.position + local_centroid
			var new_world_centroid: Vector2 = group_center + (world_centroid - group_center).rotated(rad)
			var new_pos: Vector2 = new_world_centroid - local_centroid

			pos_starts[t] = t.position
			pos_ends[t] = new_pos
			t.position = new_pos

			var rotated_verts: Array[Vector2] = TriangleMath.rotate_vertices(old_verts, rad, local_centroid)
			starts[t] = old_verts
			ends[t] = rotated_verts
			t.vertex_a = rotated_verts[0]
			t.vertex_b = rotated_verts[1]
			t.vertex_c = rotated_verts[2]

			t.geometry_changed.emit(t)
			t.queue_redraw()

		var cmd = TriangleCommands.MultiTransformVerticesCommand.new(selected_triangles, starts, ends, pos_starts, pos_ends)
		action_performed.emit(cmd)
		queue_redraw()
	elif selected_triangle:
		selected_triangle.rotate_by_deg(angle_deg)
		queue_redraw()

func flip_selected_h() -> void:
	if selected_triangles.size() > 1:
		var group_center: Vector2 = Vector2.ZERO
		for t in selected_triangles:
			group_center += t.position + t.get_centroid()
		group_center /= float(selected_triangles.size())

		var starts: Dictionary = {}
		var ends: Dictionary = {}
		var pos_starts: Dictionary = {}
		var pos_ends: Dictionary = {}

		for t in selected_triangles:
			var old_verts: Array[Vector2] = [t.vertex_a, t.vertex_b, t.vertex_c]
			var local_centroid: Vector2 = t.get_centroid()
			var world_centroid: Vector2 = t.position + local_centroid
			var dx: float = world_centroid.x - group_center.x
			var new_world_centroid: Vector2 = Vector2(group_center.x - dx, world_centroid.y)
			var new_pos: Vector2 = new_world_centroid - local_centroid

			pos_starts[t] = t.position
			pos_ends[t] = new_pos
			t.position = new_pos

			var flipped_verts: Array[Vector2] = TriangleMath.flip_vertices_h(old_verts, local_centroid)
			starts[t] = old_verts
			ends[t] = flipped_verts
			t.vertex_a = flipped_verts[0]
			t.vertex_b = flipped_verts[1]
			t.vertex_c = flipped_verts[2]

			t.geometry_changed.emit(t)
			t.queue_redraw()

		var cmd = TriangleCommands.MultiTransformVerticesCommand.new(selected_triangles, starts, ends, pos_starts, pos_ends)
		action_performed.emit(cmd)
		queue_redraw()
	elif selected_triangle:
		selected_triangle.flip_h()
		queue_redraw()

func flip_selected_v() -> void:
	if selected_triangles.size() > 1:
		var group_center: Vector2 = Vector2.ZERO
		for t in selected_triangles:
			group_center += t.position + t.get_centroid()
		group_center /= float(selected_triangles.size())

		var starts: Dictionary = {}
		var ends: Dictionary = {}
		var pos_starts: Dictionary = {}
		var pos_ends: Dictionary = {}

		for t in selected_triangles:
			var old_verts: Array[Vector2] = [t.vertex_a, t.vertex_b, t.vertex_c]
			var local_centroid: Vector2 = t.get_centroid()
			var world_centroid: Vector2 = t.position + local_centroid
			var dy: float = world_centroid.y - group_center.y
			var new_world_centroid: Vector2 = Vector2(world_centroid.x, group_center.y - dy)
			var new_pos: Vector2 = new_world_centroid - local_centroid

			pos_starts[t] = t.position
			pos_ends[t] = new_pos
			t.position = new_pos

			var flipped_verts: Array[Vector2] = TriangleMath.flip_vertices_v(old_verts, local_centroid)
			starts[t] = old_verts
			ends[t] = flipped_verts
			t.vertex_a = flipped_verts[0]
			t.vertex_b = flipped_verts[1]
			t.vertex_c = flipped_verts[2]

			t.geometry_changed.emit(t)
			t.queue_redraw()

		var cmd = TriangleCommands.MultiTransformVerticesCommand.new(selected_triangles, starts, ends, pos_starts, pos_ends)
		action_performed.emit(cmd)
		queue_redraw()
	elif selected_triangle:
		selected_triangle.flip_v()
		queue_redraw()
