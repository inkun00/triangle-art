class_name MainGame
extends Control

const CommandManager = preload("res://scripts/core/command_manager.gd")
const PngExporter = preload("res://scripts/export/png_exporter.gd")
const TriangleNode = preload("res://scenes/triangle/triangle_node.gd")
const TopToolbar = preload("res://scenes/ui/toolbar.gd")
const DrawingCanvas = preload("res://scenes/canvas/drawing_canvas.gd")
const TriangleColorPalette = preload("res://scenes/ui/color_palette.gd")
const SoundManager = preload("res://scripts/core/sound_manager.gd")
const PuzzleEvaluator = preload("res://scripts/core/puzzle_evaluator.gd")
const TriangleTemplates = preload("res://scripts/core/triangle_templates.gd")
const ChallengeHUD = preload("res://scenes/ui/challenge_hud.gd")
const ConfettiParticles = preload("res://scenes/effects/confetti_particles.gd")

## Main Game Controller uniting Canvas, Toolbar, Color Palette, SoundManager, and Puzzle Challenge.

@onready var toolbar: TopToolbar = %Toolbar
@onready var canvas: DrawingCanvas = %DrawingCanvas
@onready var palette: TriangleColorPalette = %ColorPalette
@onready var toast_label: Label = %ToastLabel
@onready var challenge_hud: ChallengeHUD = %ChallengeHUD
@onready var confetti_particles: ConfettiParticles = %ConfettiParticles

var sound_manager: SoundManager = null
var command_manager: CommandManager = CommandManager.new()
var is_transparent_bg: bool = false
var _color_drag_saved_colors: Dictionary = {}

var challenge_mode_active: bool = false
var current_challenge_name: String = "나비 (Butterfly)"
var challenge_completed_this_round: bool = false

func _ready() -> void:
	# 0. Initialize Procedural Sound Manager
	sound_manager = SoundManager.new()
	sound_manager.name = "SoundManager"
	add_child(sound_manager)

	# 1. Setup Command Manager
	command_manager.state_changed.connect(_on_command_state_changed)

	# 2. Connect Canvas signals
	canvas.action_performed.connect(_on_canvas_action_performed)
	canvas.selection_changed.connect(_on_canvas_selection_changed)
	canvas.multi_selection_changed.connect(_on_canvas_multi_selection_changed)
	canvas.triangle_geometry_updated.connect(_on_canvas_geometry_updated)
	canvas.undo_requested.connect(_on_undo)
	canvas.redo_requested.connect(_on_redo)
	canvas.toast_requested.connect(_show_toast)
	canvas.zoom_changed.connect(_on_canvas_zoom_changed)
	canvas.scale_lock_toggled.connect(_on_canvas_scale_lock_toggled)
	canvas.canvas_size_changed.connect(_on_canvas_size_changed)

	# 3. Connect Toolbar signals
	toolbar.new_triangle_requested.connect(_on_new_triangle)
	toolbar.duplicate_requested.connect(_on_duplicate)
	toolbar.delete_requested.connect(_on_delete)
	toolbar.rotate_requested.connect(_on_rotate_requested)
	toolbar.flip_h_requested.connect(_on_flip_h_requested)
	toolbar.flip_v_requested.connect(_on_flip_v_requested)
	toolbar.equilateral_requested.connect(_on_equilateral_requested)
	toolbar.layer_up_requested.connect(_on_layer_up)
	toolbar.layer_down_requested.connect(_on_layer_down)
	toolbar.group_requested.connect(_on_group_requested)
	toolbar.ungroup_requested.connect(_on_ungroup_requested)
	toolbar.undo_requested.connect(_on_undo)
	toolbar.redo_requested.connect(_on_redo)
	toolbar.clear_requested.connect(_on_clear_requested)
	toolbar.grid_step_changed.connect(_on_grid_step_changed)
	toolbar.snap_toggled.connect(_on_snap_toggled)
	toolbar.scale_lock_toggled.connect(_on_toolbar_scale_lock_toggled)
	toolbar.zoom_reset_requested.connect(_on_zoom_reset_requested)
	toolbar.guide_toggled.connect(_on_guide_toggled)
	toolbar.bg_mode_toggled.connect(_on_bg_mode_toggled)
	toolbar.canvas_size_requested.connect(_on_canvas_size_requested)
	toolbar.template_selected.connect(_on_template_selected)
	toolbar.save_project_requested.connect(_on_save_project)
	toolbar.load_project_requested.connect(_on_load_project)
	toolbar.export_requested.connect(_on_export)
	toolbar.exhibit_requested.connect(func(): _show_toast("비바샘 삼보드 전시관으로 이동합니다..."))
	toolbar.sound_toggled.connect(func(enabled: bool):
		if sound_manager:
			sound_manager.sound_enabled = enabled
	)
	toolbar.challenge_toggled.connect(_on_challenge_toggled)
	toolbar.set_canvas_size(canvas.canvas_size)

	# 4. Connect Palette signals
	palette.color_selected.connect(_on_color_selected)
	palette.color_preview.connect(_on_color_preview)
	palette.outline_remove_requested.connect(_on_outline_remove_requested)

	# 5. Connect Challenge HUD signals
	challenge_hud.challenge_closed.connect(_on_challenge_closed)
	challenge_hud.next_challenge_requested.connect(_on_next_challenge_requested)

	# 6. Initialize with one initial triangle in the center!
	await get_tree().process_frame
	canvas.add_new_equilateral_triangle()

	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.triangleArtReady && window.triangleArtReady();")

	_show_toast("Triangle Art에 오신 것을 환영합니다! 자유롭게 삼각형으로 그림을 그려보세요.")

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed():
		return

	if event is InputEventKey:
		var k: InputEventKey = event
		# Ctrl + Z (Undo)
		if k.ctrl_pressed and not k.shift_pressed and k.keycode == KEY_Z:
			_on_undo()
			get_viewport().set_input_as_handled()
		# Ctrl + Y or Ctrl + Shift + Z (Redo)
		elif (k.ctrl_pressed and k.keycode == KEY_Y) or (k.ctrl_pressed and k.shift_pressed and k.keycode == KEY_Z):
			_on_redo()
			get_viewport().set_input_as_handled()
		# Ctrl + Shift + G (Ungroup)
		elif k.ctrl_pressed and k.shift_pressed and k.keycode == KEY_G:
			_on_ungroup_requested()
			get_viewport().set_input_as_handled()
		# Ctrl + G (Group)
		elif k.ctrl_pressed and not k.shift_pressed and k.keycode == KEY_G:
			_on_group_requested()
			get_viewport().set_input_as_handled()
		# Ctrl + D (Duplicate)
		elif k.ctrl_pressed and k.keycode == KEY_D:
			_on_duplicate()
			get_viewport().set_input_as_handled()
		# Ctrl + S (Save Project)
		elif k.ctrl_pressed and not k.shift_pressed and k.keycode == KEY_S:
			_on_save_project()
			get_viewport().set_input_as_handled()
		# Ctrl + O (Open Project)
		elif k.ctrl_pressed and not k.shift_pressed and k.keycode == KEY_O:
			toolbar._show_load_project_dialog()
			get_viewport().set_input_as_handled()
		# Delete / Backspace
		elif k.keycode == KEY_DELETE or k.keycode == KEY_BACKSPACE:
			_on_delete()
			get_viewport().set_input_as_handled()
		# R (Rotate 45°) / Shift + R (Rotate -45°)
		elif not k.ctrl_pressed and not k.alt_pressed and k.keycode == KEY_R:
			var rot_angle: float = -45.0 if k.shift_pressed else 45.0
			_on_rotate_requested(rot_angle)
			get_viewport().set_input_as_handled()

func _on_command_state_changed() -> void:
	toolbar.update_undo_redo_states(command_manager.can_undo(), command_manager.can_redo())

func _on_canvas_action_performed(cmd: Variant) -> void:
	command_manager.push_and_execute(cmd)
	_update_challenge_evaluation()

func _on_canvas_selection_changed(node: TriangleNode) -> void:
	toolbar.update_selection_state(node)
	if node and is_instance_valid(node):
		palette.sync_triangle_colors(node.fill_color, node.outline_color)

func _on_canvas_geometry_updated(node: TriangleNode) -> void:
	toolbar.update_selection_state(node)
	_update_challenge_evaluation()

func _on_new_triangle() -> void:
	canvas.add_new_equilateral_triangle()
	_show_toast("새 정삼각형이 생성되었습니다.")
	_update_challenge_evaluation()

func _on_duplicate() -> void:
	var copy = canvas.duplicate_selected()
	if copy:
		_show_toast("삼각형이 복제되었습니다.")
		_update_challenge_evaluation()

func _on_delete() -> void:
	canvas.delete_selected()
	_show_toast("삼각형이 삭제되었습니다.")
	_update_challenge_evaluation()

func _on_rotate_requested(angle_deg: float) -> void:
	canvas.rotate_selected(angle_deg)
	_show_toast("삼각형을 %d° 회전했습니다." % int(angle_deg))
	_update_challenge_evaluation()

func _on_flip_h_requested() -> void:
	canvas.flip_selected_h()
	_show_toast("삼각형을 좌우 반전했습니다.")
	_update_challenge_evaluation()

func _on_flip_v_requested() -> void:
	canvas.flip_selected_v()
	_show_toast("삼각형을 상하 반전했습니다.")
	_update_challenge_evaluation()

func _on_guide_toggled(enabled: bool) -> void:
	canvas.set_guide_state(enabled)
	_show_toast("따라 그리기 가이드: " + ("켜짐" if enabled else "꺼짐"))

func _on_layer_up() -> void:
	canvas.bring_forward()
	_show_toast("삼각형을 한 단계 앞으로 가져왔습니다.")

func _on_layer_down() -> void:
	canvas.send_backward()
	_show_toast("삼각형을 한 단계 뒤로 보냈습니다.")

func _on_clear_requested() -> void:
	canvas.clear_all_triangles()
	_show_toast("캔버스를 모두 비웠습니다.")
	_update_challenge_evaluation()

func _on_template_selected(t_name: String) -> void:
	canvas.load_template_triangles(t_name)
	_show_toast("도안 불러오기 완료: " + t_name)
	if challenge_mode_active:
		current_challenge_name = t_name
		challenge_hud.set_challenge(current_challenge_name)
		canvas.set_guide_state(true, current_challenge_name)
		_update_challenge_evaluation()

func _on_undo() -> void:
	if command_manager.can_undo():
		command_manager.undo()
		_show_toast("실행 취소 (Undo)")
		if canvas.selected_triangle and is_instance_valid(canvas.selected_triangle):
			palette.sync_triangle_colors(canvas.selected_triangle.fill_color, canvas.selected_triangle.outline_color)
		_update_challenge_evaluation()

func _on_redo() -> void:
	if command_manager.can_redo():
		command_manager.redo()
		_show_toast("다시 실행 (Redo)")
		if canvas.selected_triangle and is_instance_valid(canvas.selected_triangle):
			palette.sync_triangle_colors(canvas.selected_triangle.fill_color, canvas.selected_triangle.outline_color)
		_update_challenge_evaluation()

func _on_snap_toggled(enabled: bool) -> void:
	canvas.snap_enabled = enabled
	_show_toast("그리드 스냅: " + ("켜짐" if enabled else "꺼짐"))

func _on_bg_mode_toggled(transparent: bool) -> void:
	is_transparent_bg = transparent
	_show_toast("내보내기 배경: " + ("투명" if transparent else "흰색"))

func _on_canvas_zoom_changed(zoom: float) -> void:
	toolbar.update_zoom_display(zoom)

func _on_canvas_scale_lock_toggled(locked: bool) -> void:
	toolbar.update_scale_lock_display(locked)

func _on_zoom_reset_requested() -> void:
	canvas.reset_zoom()
	_show_toast("화면 줌이 100%로 리셋되었습니다.")

func _on_toolbar_scale_lock_toggled(locked: bool) -> void:
	canvas.set_scale_locked(locked)
	_show_toast("삼각형 비율 고정: " + ("켜짐" if locked else "꺼짐"))

func _on_canvas_size_requested(new_size: Vector2) -> void:
	canvas.set_canvas_size(new_size)

func _on_canvas_size_changed(new_size: Vector2) -> void:
	toolbar.set_canvas_size(new_size)
	_show_toast("캔버스 크기가 %d × %d px로 설정되었습니다." % [int(new_size.x), int(new_size.y)])
	_update_challenge_evaluation()

func _on_color_preview(col: Color, is_outline: bool) -> void:
	if is_outline:
		if _color_drag_saved_colors.is_empty() and not canvas.selected_triangles.is_empty():
			for t in canvas.selected_triangles:
				if is_instance_valid(t):
					_color_drag_saved_colors[t] = t.outline_color
		canvas.preview_selected_outline_color(col)
	else:
		if _color_drag_saved_colors.is_empty() and not canvas.selected_triangles.is_empty():
			for t in canvas.selected_triangles:
				if is_instance_valid(t):
					_color_drag_saved_colors[t] = t.fill_color
		canvas.preview_selected_color(col)

func _on_color_selected(col: Color, is_outline: bool) -> void:
	if is_outline:
		canvas.set_selected_outline_color(col, _color_drag_saved_colors)
		_show_toast("테두리 색상이 변경되었습니다.")
	else:
		canvas.set_selected_color(col, _color_drag_saved_colors)
	_color_drag_saved_colors.clear()

func _on_outline_remove_requested() -> void:
	canvas.remove_selected_outline()
	_show_toast("테두리가 삭제되었습니다 (테두리 없음).")

func _on_grid_step_changed(step: float) -> void:
	canvas.set_grid_step(step)
	_show_toast("그리드 격자 단위: %dpx" % int(step))

func _on_group_requested() -> void:
	canvas.group_selected()
	_show_toast("선택한 삼각형들이 그룹화되었습니다 (단축키: Ctrl+G).")

func _on_ungroup_requested() -> void:
	canvas.ungroup_selected()
	_show_toast("삼각형 그룹이 해제되었습니다 (단축키: Ctrl+Shift+G).")

func _on_equilateral_requested() -> void:
	canvas.make_selected_equilateral()
	_show_toast("정삼각형으로 변환되었습니다.")
	_update_challenge_evaluation()

func _on_canvas_multi_selection_changed(nodes: Array[TriangleNode]) -> void:
	toolbar.update_multi_selection_state(nodes, canvas.has_group_in_selection())
	if not nodes.is_empty() and is_instance_valid(nodes[-1]):
		palette.sync_triangle_colors(nodes[-1].fill_color, nodes[-1].outline_color)

func _on_export() -> void:
	if canvas.triangles.is_empty():
		_show_toast("저장할 삼각형이 없습니다. 먼저 삼각형을 추가하세요.")
		return

	_show_toast("PNG 내보내기 진행 중...")
	var saved_path: String = await PngExporter.export_canvas(get_tree(), canvas.triangles, canvas.canvas_size, is_transparent_bg)
	if not saved_path.is_empty():
		_show_toast("작품이 PNG로 저장되었습니다: " + saved_path.get_file())

func _on_save_project() -> void:
	if canvas.triangles.is_empty():
		_show_toast("저장할 삼각형이 없습니다. 먼저 삼각형을 추가하세요.")
		return

	var json_data: String = canvas.export_project_json()
	var time_dict: Dictionary = Time.get_datetime_dict_from_system()
	var filename: String = "triangle_art_%04d%02d%02d_%02d%02d%02d.triart" % [
		time_dict["year"], time_dict["month"], time_dict["day"],
		time_dict["hour"], time_dict["minute"], time_dict["second"]
	]

	if OS.has_feature("web") and ClassDB.class_exists("JavaScriptBridge"):
		var buffer: PackedByteArray = json_data.to_utf8_buffer()
		JavaScriptBridge.download_buffer(buffer, filename, "application/json")
		_show_toast("프로젝트 파일이 다운로드되었습니다: " + filename)
	else:
		var dir: DirAccess = DirAccess.open("user://")
		if dir and not dir.dir_exists("projects"):
			dir.make_dir("projects")
		var save_path: String = "user://projects/" + filename
		var f: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
		if f:
			f.store_string(json_data)
			f.close()
			_show_toast("프로젝트가 저장되었습니다: " + filename)
		else:
			_show_toast("프로젝트 파일 저장 실패")

func _on_load_project(json_str: String) -> void:
	var success: bool = canvas.load_project_json(json_str)
	if success:
		_show_toast("프로젝트가 성공적으로 불러와졌습니다!")
		_update_challenge_evaluation()
	else:
		_show_toast("프로젝트 데이터를 읽을 수 없습니다. 올바른 포맷인지 확인해주세요.")

# -----------------------------------------------------------------------------
# Puzzle / Challenge Gamification Handlers
# -----------------------------------------------------------------------------

func _on_challenge_toggled(active: bool) -> void:
	challenge_mode_active = active
	if challenge_mode_active:
		challenge_completed_this_round = false
		if current_challenge_name.is_empty():
			current_challenge_name = "나비 (Butterfly)"
		canvas.set_guide_state(true, current_challenge_name)
		challenge_hud.set_challenge(current_challenge_name)
		challenge_hud.visible = true
		_update_challenge_evaluation()
		_show_toast("챌린지 모드 시작: " + current_challenge_name + "! 실루엣을 채워 별 3개를 획득하세요.")
	else:
		challenge_hud.visible = false
		canvas.set_guide_state(false)
		_show_toast("챌린지 모드가 종료되었습니다.")

func _on_challenge_closed() -> void:
	challenge_mode_active = false
	challenge_hud.visible = false
	toolbar.set_challenge_active(false)
	canvas.set_guide_state(false)
	_show_toast("챌린지 모드가 종료되었습니다.")

func _on_next_challenge_requested() -> void:
	var all_names: Array[String] = TriangleTemplates.get_template_names()
	var idx: int = all_names.find(current_challenge_name)
	if idx == -1:
		idx = 0
	current_challenge_name = all_names[(idx + 1) % all_names.size()]
	canvas.clear_all_triangles()
	canvas.set_guide_state(true, current_challenge_name)
	challenge_hud.set_challenge(current_challenge_name)
	challenge_completed_this_round = false
	_update_challenge_evaluation()
	_show_toast("다음 챌린지: " + current_challenge_name)

func _update_challenge_evaluation() -> void:
	if not challenge_mode_active or current_challenge_name.is_empty() or not challenge_hud:
		return
	var template_triangles: Array = TriangleTemplates.get_template_data(current_challenge_name, canvas.canvas_size / 2.0)
	var eval_res: Dictionary = PuzzleEvaluator.evaluate_accuracy(canvas.triangles, template_triangles)
	challenge_hud.update_progress(eval_res)
	if eval_res.get("passed", false) and not challenge_completed_this_round:
		challenge_completed_this_round = true
		if confetti_particles:
			confetti_particles.burst(canvas.size / 2.0, 120)

func _show_toast(msg: String) -> void:
	if not toast_label:
		return
	toast_label.text = msg
	toast_label.modulate.a = 1.0
	var tween: Tween = create_tween()
	tween.tween_interval(2.5)
	tween.tween_property(toast_label, "modulate:a", 0.0, 0.8)
