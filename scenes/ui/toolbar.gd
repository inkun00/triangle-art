class_name TopToolbar
extends PanelContainer

const TriangleMath = preload("res://scripts/core/triangle_math.gd")
const TriangleNode = preload("res://scenes/triangle/triangle_node.gd")
const TriangleTemplates = preload("res://scripts/core/triangle_templates.gd")
const SoundManager = preload("res://scripts/core/sound_manager.gd")

## Top toolbar containing creation, editing, undo/redo, and export controls.

signal new_triangle_requested
signal duplicate_requested
signal delete_requested
signal undo_requested
signal redo_requested
signal snap_toggled(enabled: bool)
signal bg_mode_toggled(is_transparent: bool)
signal export_requested
signal template_selected(name: String)
signal layer_up_requested
signal layer_down_requested
signal clear_requested
signal rotate_requested(angle_deg: float)
signal flip_h_requested
signal flip_v_requested
signal guide_toggled(enabled: bool)
signal grid_step_changed(step: float)
signal group_requested
signal ungroup_requested
signal equilateral_requested
signal zoom_reset_requested
signal scale_lock_toggled(locked: bool)
signal canvas_size_requested(size: Vector2)
signal save_project_requested
signal load_project_requested(json_str: String)
signal sound_toggled(enabled: bool)
signal challenge_toggled(enabled: bool)

@onready var btn_new: Button = %BtnNew
@onready var btn_equilateral: Button = %BtnEquilateral
@onready var btn_rotate: Button = %BtnRotate
@onready var btn_flip_h: Button = %BtnFlipH
@onready var btn_flip_v: Button = %BtnFlipV
@onready var btn_undo: Button = %BtnUndo
@onready var btn_redo: Button = %BtnRedo
@onready var btn_clear: Button = %BtnClear
@onready var btn_grid_step: Button = %BtnGridStep
@onready var btn_snap: Button = %BtnSnap
@onready var btn_zoom: Button = %BtnZoom
@onready var btn_guide: Button = %BtnGuide
@onready var btn_bg: Button = %BtnBg
@onready var btn_canvas_size: Button = %BtnCanvasSize
@onready var btn_sound: Button = %BtnSound
@onready var btn_challenge: Button = %BtnChallenge
@onready var btn_save_project: Button = %BtnSaveProject
@onready var btn_load_project: Button = %BtnLoadProject
@onready var btn_export: Button = %BtnExport
@onready var opt_templates: OptionButton = %OptTemplates
@onready var label_info: Label = %LabelInfo
@onready var badge_type: PanelContainer = %BadgeType
@onready var label_type: Label = %LabelType

# Compatibility references for removed toolbar buttons (now in right-click context menu)
var btn_duplicate: Button = null
var btn_delete: Button = null
var btn_layer_up: Button = null
var btn_layer_down: Button = null
var btn_group: Button = null
var btn_ungroup: Button = null
var btn_scale_lock: Button = null

const GRID_STEPS: Array[float] = [40.0, 20.0, 10.0, 5.0]
var current_grid_step_idx: int = 0
var snap_active: bool = false
var scale_lock_active: bool = false
var bg_transparent: bool = false
var guide_active: bool = false
var current_canvas_size: Vector2 = Vector2(1200, 800)
var canvas_size_menu: PopupMenu = null
var custom_size_dialog: PanelContainer = null
var spin_custom_w: SpinBox = null
var spin_custom_h: SpinBox = null
var load_project_dialog: PanelContainer = null

var sound_active: bool = true
var challenge_active: bool = false

var style_active_snap: StyleBoxFlat = null
var style_active_lock: StyleBoxFlat = null
var style_active_guide: StyleBoxFlat = null
var style_active_bg: StyleBoxFlat = null
var style_active_challenge: StyleBoxFlat = null

func _ready() -> void:
	_setup_active_styles()

	btn_new.pressed.connect(func(): _play_click(); new_triangle_requested.emit())
	btn_equilateral.pressed.connect(func(): _play_click(); equilateral_requested.emit())
	btn_rotate.pressed.connect(func(): _play_click(); rotate_requested.emit(45.0))
	btn_flip_h.pressed.connect(func(): _play_click(); flip_h_requested.emit())
	btn_flip_v.pressed.connect(func(): _play_click(); flip_v_requested.emit())
	btn_undo.pressed.connect(func(): _play_click(); undo_requested.emit())
	btn_redo.pressed.connect(func(): _play_click(); redo_requested.emit())
	btn_clear.pressed.connect(func(): _play_delete(); clear_requested.emit())
	btn_save_project.pressed.connect(func(): _play_click(); save_project_requested.emit())
	btn_load_project.pressed.connect(func(): _play_click(); _show_load_project_dialog())
	btn_export.pressed.connect(func(): _play_click(); export_requested.emit())

	btn_grid_step.pressed.connect(_on_grid_step_pressed)
	btn_snap.pressed.connect(_on_snap_pressed)
	btn_zoom.pressed.connect(func(): _play_click(); zoom_reset_requested.emit())
	btn_bg.pressed.connect(_on_bg_pressed)
	btn_guide.pressed.connect(_on_guide_pressed)
	btn_canvas_size.pressed.connect(_on_canvas_size_btn_pressed)
	btn_sound.pressed.connect(_on_sound_pressed)
	btn_challenge.pressed.connect(_on_challenge_pressed)

	_setup_templates_menu()
	_setup_canvas_size_menu()
	update_undo_redo_states(false, false)
	update_selection_state(null)
	update_multi_selection_state([], false)
	_update_snap_ui()
	_update_scale_lock_ui()
	_update_guide_ui()
	_update_bg_ui()
	_update_sound_ui()
	_update_challenge_ui()

func _setup_active_styles() -> void:
	style_active_snap = StyleBoxFlat.new()
	style_active_snap.bg_color = Color(0.06, 0.28, 0.38, 0.95)
	style_active_snap.border_color = Color(0.18, 0.88, 0.98, 1.0)
	style_active_snap.set_border_width_all(1)
	style_active_snap.set_corner_radius_all(6)
	style_active_snap.shadow_color = Color(0.05, 0.65, 0.85, 0.35)
	style_active_snap.shadow_size = 4

	style_active_lock = StyleBoxFlat.new()
	style_active_lock.bg_color = Color(0.32, 0.22, 0.05, 0.95)
	style_active_lock.border_color = Color(1.0, 0.78, 0.2, 1.0)
	style_active_lock.set_border_width_all(1)
	style_active_lock.set_corner_radius_all(6)
	style_active_lock.shadow_color = Color(0.9, 0.7, 0.1, 0.35)
	style_active_lock.shadow_size = 4

	style_active_guide = StyleBoxFlat.new()
	style_active_guide.bg_color = Color(0.2, 0.12, 0.38, 0.95)
	style_active_guide.border_color = Color(0.72, 0.45, 1.0, 1.0)
	style_active_guide.set_border_width_all(1)
	style_active_guide.set_corner_radius_all(6)
	style_active_guide.shadow_color = Color(0.6, 0.3, 0.9, 0.35)
	style_active_guide.shadow_size = 4

	style_active_bg = StyleBoxFlat.new()
	style_active_bg.bg_color = Color(0.18, 0.18, 0.26, 0.95)
	style_active_bg.border_color = Color(0.55, 0.65, 0.85, 1.0)
	style_active_bg.set_border_width_all(1)
	style_active_bg.set_corner_radius_all(6)

	style_active_challenge = StyleBoxFlat.new()
	style_active_challenge.bg_color = Color(0.42, 0.18, 0.78, 0.95)
	style_active_challenge.border_color = Color(0.85, 0.55, 1.0, 1.0)
	style_active_challenge.set_border_width_all(1)
	style_active_challenge.set_corner_radius_all(6)
	style_active_challenge.shadow_color = Color(0.6, 0.25, 0.95, 0.45)
	style_active_challenge.shadow_size = 6

func _setup_templates_menu() -> void:
	opt_templates.clear()
	opt_templates.add_item("도안 불러오기...")
	for t_name in TriangleTemplates.get_template_names():
		opt_templates.add_item("  " + t_name)

	opt_templates.item_selected.connect(func(idx: int):
		if idx > 0:
			var chosen: String = opt_templates.get_item_text(idx).strip_edges()
			template_selected.emit(chosen)
			opt_templates.select(0)
	)

func _on_grid_step_pressed() -> void:
	current_grid_step_idx = (current_grid_step_idx + 1) % GRID_STEPS.size()
	var step: float = GRID_STEPS[current_grid_step_idx]
	btn_grid_step.text = "격자: %dpx" % int(step)
	grid_step_changed.emit(step)

func _on_snap_pressed() -> void:
	snap_active = !snap_active
	_update_snap_ui()
	snap_toggled.emit(snap_active)

func _update_snap_ui() -> void:
	if snap_active:
		btn_snap.text = "● 스냅: 켜짐"
		btn_snap.add_theme_stylebox_override("normal", style_active_snap)
		btn_snap.add_theme_color_override("font_color", Color(0.3, 0.95, 1.0, 1.0))
	else:
		btn_snap.text = "○ 스냅: 꺼짐"
		btn_snap.remove_theme_stylebox_override("normal")
		btn_snap.remove_theme_color_override("font_color")

func _on_scale_lock_pressed() -> void:
	scale_lock_active = !scale_lock_active
	_update_scale_lock_ui()
	scale_lock_toggled.emit(scale_lock_active)

func _update_scale_lock_ui() -> void:
	if scale_lock_active:
		btn_scale_lock.text = "● 비율: 고정"
		btn_scale_lock.add_theme_stylebox_override("normal", style_active_lock)
		btn_scale_lock.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35, 1.0))
	else:
		btn_scale_lock.text = "○ 비율: 자유"
		btn_scale_lock.remove_theme_stylebox_override("normal")
		btn_scale_lock.remove_theme_color_override("font_color")

func _on_bg_pressed() -> void:
	bg_transparent = !bg_transparent
	_update_bg_ui()
	bg_mode_toggled.emit(bg_transparent)

func _update_bg_ui() -> void:
	if bg_transparent:
		btn_bg.text = "배경: 투명"
		btn_bg.add_theme_stylebox_override("normal", style_active_bg)
		btn_bg.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0, 1.0))
	else:
		btn_bg.text = "배경: 흰색"
		btn_bg.remove_theme_stylebox_override("normal")
		btn_bg.remove_theme_color_override("font_color")

func _on_guide_pressed() -> void:
	guide_active = !guide_active
	_update_guide_ui()
	guide_toggled.emit(guide_active)

func _update_guide_ui() -> void:
	if guide_active:
		btn_guide.text = "● 가이드: 켜짐"
		btn_guide.add_theme_stylebox_override("normal", style_active_guide)
		btn_guide.add_theme_color_override("font_color", Color(0.88, 0.65, 1.0, 1.0))
	else:
		btn_guide.text = "○ 가이드: 꺼짐"
		btn_guide.remove_theme_stylebox_override("normal")
		btn_guide.remove_theme_color_override("font_color")

func _play_click() -> void:
	if SoundManager.instance:
		SoundManager.instance.play_click()

func _play_delete() -> void:
	if SoundManager.instance:
		SoundManager.instance.play_delete()

func _on_sound_pressed() -> void:
	sound_active = !sound_active
	_update_sound_ui()
	sound_toggled.emit(sound_active)
	if sound_active:
		_play_click()

func _update_sound_ui() -> void:
	if btn_sound:
		btn_sound.text = "음향: ON" if sound_active else "음향: OFF"
		btn_sound.tooltip_text = "효과음: 켜짐" if sound_active else "효과음: 음소거"

func _on_challenge_pressed() -> void:
	challenge_active = !challenge_active
	_update_challenge_ui()
	challenge_toggled.emit(challenge_active)
	_play_click()

func _update_challenge_ui() -> void:
	if btn_challenge:
		if challenge_active:
			btn_challenge.text = "★ 챌린지: 켜짐"
			btn_challenge.add_theme_stylebox_override("normal", style_active_challenge)
		else:
			btn_challenge.text = "★ 챌린지"
			btn_challenge.remove_theme_stylebox_override("normal")

func set_challenge_active(active: bool) -> void:
	challenge_active = active
	_update_challenge_ui()

func update_zoom_display(zoom: float) -> void:
	var percent: int = int(roundf(zoom * 100.0))
	btn_zoom.text = "줌: %d%%" % percent
	if percent != 100:
		btn_zoom.add_theme_color_override("font_color", Color(0.35, 0.85, 1.0, 1.0))
	else:
		btn_zoom.remove_theme_color_override("font_color")

func update_scale_lock_display(locked: bool) -> void:
	scale_lock_active = locked
	_update_scale_lock_ui()

func update_undo_redo_states(can_undo: bool, can_redo: bool) -> void:
	btn_undo.disabled = !can_undo
	btn_redo.disabled = !can_redo

func update_multi_selection_state(selected: Array[TriangleNode], _has_group: bool) -> void:
	var count: int = selected.size()
	if count > 1:
		if label_type:
			label_type.text = "%d개 다중 선택" % count
			label_type.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3, 1.0))
		label_info.text = "%d개의 삼각형이 선택되었습니다. 마우스 우클릭으로 그룹화(Ctrl+G), 복제, 삭제, 순서 변경이 가능합니다." % count

func update_selection_state(triangle: TriangleNode) -> void:
	var has_sel: bool = (triangle != null and is_instance_valid(triangle))
	btn_rotate.disabled = !has_sel
	btn_flip_h.disabled = !has_sel
	btn_flip_v.disabled = !has_sel
	btn_equilateral.disabled = !has_sel

	if not has_sel:
		if label_type:
			label_type.text = "대기 중"
			label_type.add_theme_color_override("font_color", Color(0.5, 0.6, 0.75, 1.0))
		label_info.text = "삼각형을 클릭하여 선택하거나 + 새 삼각형을 만드세요. (마우스 우클릭: 상세 메뉴)"
		return

	var info = TriangleMath.classify_triangle(triangle.vertex_a, triangle.vertex_b, triangle.vertex_c)
	var angles = TriangleMath.get_display_angles_deg(triangle.vertex_a, triangle.vertex_b, triangle.vertex_c)
	var sides = TriangleMath.get_side_lengths_grid(triangle.vertex_a, triangle.vertex_b, triangle.vertex_c, triangle.grid_step)

	var s_ab: String = "%.1f" % sides["ab"]
	var s_bc: String = "%.1f" % sides["bc"]
	var s_ca: String = "%.1f" % sides["ca"]

	if label_type:
		label_type.text = "◆ " + info["name"]
		if info["is_equilateral"]:
			label_type.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0, 1.0))
		elif info["is_right"]:
			label_type.add_theme_color_override("font_color", Color(0.75, 0.55, 1.0, 1.0))
		elif info["is_isosceles"]:
			label_type.add_theme_color_override("font_color", Color(1.0, 0.78, 0.35, 1.0))
		else:
			label_type.add_theme_color_override("font_color", Color(0.45, 0.9, 0.65, 1.0))

	label_info.text = "각도: %d° · %d° · %d° (합 180°)  |  변의 길이: %s · %s · %s" % [
		angles["a"], angles["b"], angles["c"],
		s_ab, s_bc, s_ca
	]

const PRESET_SIZES: Array[Dictionary] = [
	{"name": "1200 × 800 (기본 와이드)", "size": Vector2(1200, 800)},
	{"name": "800 × 600 (4:3 클래식)", "size": Vector2(800, 600)},
	{"name": "1080 × 1080 (1:1 정사각형)", "size": Vector2(1080, 1080)},
	{"name": "1280 × 720 (16:9 HD)", "size": Vector2(1280, 720)},
	{"name": "1920 × 1080 (16:9 Full HD)", "size": Vector2(1920, 1080)},
	{"name": "1240 × 1754 (A4 세로)", "size": Vector2(1240, 1754)},
	{"name": "1754 × 1240 (A4 가로)", "size": Vector2(1754, 1240)},
]

func _setup_canvas_size_menu() -> void:
	if canvas_size_menu:
		canvas_size_menu.queue_free()
	canvas_size_menu = PopupMenu.new()
	canvas_size_menu.name = "CanvasSizePopup"
	for i in range(PRESET_SIZES.size()):
		var item = PRESET_SIZES[i]
		canvas_size_menu.add_item(item["name"], i)
	canvas_size_menu.add_separator()
	canvas_size_menu.add_item("직접 입력 (Custom Size)...", 100)
	canvas_size_menu.id_pressed.connect(_on_canvas_size_menu_id_pressed)
	add_child(canvas_size_menu)

func _on_canvas_size_btn_pressed() -> void:
	if canvas_size_menu:
		var pos: Vector2 = btn_canvas_size.global_position + Vector2(0, btn_canvas_size.size.y + 4)
		canvas_size_menu.reset_size()
		canvas_size_menu.popup(Rect2i(Vector2i(pos), Vector2i.ZERO))

func _on_canvas_size_menu_id_pressed(id: int) -> void:
	if id < PRESET_SIZES.size():
		var chosen_size: Vector2 = PRESET_SIZES[id]["size"]
		set_canvas_size(chosen_size)
		canvas_size_requested.emit(chosen_size)
	elif id == 100:
		_show_custom_size_dialog()

func set_canvas_size(new_size: Vector2) -> void:
	current_canvas_size = new_size
	if btn_canvas_size:
		btn_canvas_size.text = "%d×%d" % [int(current_canvas_size.x), int(current_canvas_size.y)]

func _show_custom_size_dialog() -> void:
	if custom_size_dialog and is_instance_valid(custom_size_dialog):
		custom_size_dialog.queue_free()

	custom_size_dialog = PanelContainer.new()
	custom_size_dialog.name = "CustomSizeDialog"
	custom_size_dialog.top_level = true
	custom_size_dialog.custom_minimum_size = Vector2(280, 160)

	var pstyle: StyleBoxFlat = StyleBoxFlat.new()
	pstyle.bg_color = Color(0.12, 0.16, 0.24, 0.96)
	pstyle.border_color = Color(0.35, 0.65, 0.95, 0.8)
	pstyle.set_border_width_all(2)
	pstyle.set_corner_radius_all(10)
	pstyle.shadow_color = Color(0, 0, 0, 0.4)
	pstyle.shadow_size = 12
	pstyle.content_margin_left = 16
	pstyle.content_margin_right = 16
	pstyle.content_margin_top = 14
	pstyle.content_margin_bottom = 14
	custom_size_dialog.add_theme_stylebox_override("panel", pstyle)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	custom_size_dialog.add_child(vbox)

	var title_lbl: Label = Label.new()
	title_lbl.text = "캔버스 크기 직접 설정"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0, 1.0))
	vbox.add_child(title_lbl)

	var grid_inputs: GridContainer = GridContainer.new()
	grid_inputs.columns = 3
	grid_inputs.add_theme_constant_override("h_separation", 8)
	grid_inputs.add_theme_constant_override("v_separation", 6)
	vbox.add_child(grid_inputs)

	# Width row
	var lbl_w: Label = Label.new()
	lbl_w.text = "가로 (W):"
	lbl_w.add_theme_font_size_override("font_size", 11)
	grid_inputs.add_child(lbl_w)

	spin_custom_w = SpinBox.new()
	spin_custom_w.min_value = 300
	spin_custom_w.max_value = 4096
	spin_custom_w.step = 10
	spin_custom_w.value = current_canvas_size.x
	grid_inputs.add_child(spin_custom_w)

	var lbl_px1: Label = Label.new()
	lbl_px1.text = "px"
	lbl_px1.add_theme_font_size_override("font_size", 11)
	grid_inputs.add_child(lbl_px1)

	# Height row
	var lbl_h: Label = Label.new()
	lbl_h.text = "세로 (H):"
	lbl_h.add_theme_font_size_override("font_size", 11)
	grid_inputs.add_child(lbl_h)

	spin_custom_h = SpinBox.new()
	spin_custom_h.min_value = 300
	spin_custom_h.max_value = 4096
	spin_custom_h.step = 10
	spin_custom_h.value = current_canvas_size.y
	grid_inputs.add_child(spin_custom_h)

	var lbl_px2: Label = Label.new()
	lbl_px2.text = "px"
	lbl_px2.add_theme_font_size_override("font_size", 11)
	grid_inputs.add_child(lbl_px2)

	# Action buttons row
	var btn_row: HBoxContainer = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var btn_cancel: Button = Button.new()
	btn_cancel.text = "취소"
	btn_cancel.custom_minimum_size = Vector2(70, 26)
	btn_cancel.pressed.connect(func(): custom_size_dialog.queue_free())
	btn_row.add_child(btn_cancel)

	var btn_apply: Button = Button.new()
	btn_apply.text = "적용"
	btn_apply.custom_minimum_size = Vector2(70, 26)
	btn_apply.pressed.connect(func():
		var w_val: float = spin_custom_w.value
		var h_val: float = spin_custom_h.value
		var sz: Vector2 = Vector2(w_val, h_val)
		set_canvas_size(sz)
		canvas_size_requested.emit(sz)
		custom_size_dialog.queue_free()
	)
	btn_row.add_child(btn_apply)

	get_tree().root.add_child(custom_size_dialog)
	var vp_size: Vector2 = get_viewport_rect().size
	custom_size_dialog.position = (vp_size - Vector2(280, 160)) / 2.0

func _show_load_project_dialog() -> void:
	if load_project_dialog and is_instance_valid(load_project_dialog):
		load_project_dialog.queue_free()

	load_project_dialog = PanelContainer.new()
	var style_bg: StyleBoxFlat = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.1, 0.13, 0.2, 0.98)
	style_bg.border_width_left = 1
	style_bg.border_width_top = 1
	style_bg.border_width_right = 1
	style_bg.border_width_bottom = 1
	style_bg.border_color = Color(0.3, 0.45, 0.8, 0.9)
	style_bg.corner_radius_top_left = 8
	style_bg.corner_radius_top_right = 8
	style_bg.corner_radius_bottom_right = 8
	style_bg.corner_radius_bottom_left = 8
	style_bg.shadow_color = Color(0, 0, 0, 0.6)
	style_bg.shadow_size = 16
	style_bg.content_margin_left = 16
	style_bg.content_margin_top = 16
	style_bg.content_margin_right = 16
	style_bg.content_margin_bottom = 16
	load_project_dialog.add_theme_stylebox_override("panel", style_bg)
	load_project_dialog.custom_minimum_size = Vector2(480, 340)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	load_project_dialog.add_child(vbox)

	# Title Bar
	var title_bar: HBoxContainer = HBoxContainer.new()
	vbox.add_child(title_bar)

	var lbl_title: Label = Label.new()
	lbl_title.text = "프로젝트 열기 (.triart / .json)"
	lbl_title.add_theme_font_size_override("font_size", 14)
	lbl_title.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_bar.add_child(lbl_title)

	var btn_x: Button = Button.new()
	btn_x.text = "✕"
	btn_x.custom_minimum_size = Vector2(28, 24)
	btn_x.pressed.connect(func(): load_project_dialog.queue_free())
	title_bar.add_child(btn_x)

	var lbl_desc: Label = Label.new()
	lbl_desc.text = "저장해둔 .triart 또는 .json 파일의 내용을 아래에 붙여넣거나 파일을 선택하세요."
	lbl_desc.add_theme_font_size_override("font_size", 11)
	lbl_desc.add_theme_color_override("font_color", Color(0.65, 0.75, 0.9))
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(lbl_desc)

	# Action bar for file selection and clipboard
	var action_bar: HBoxContainer = HBoxContainer.new()
	action_bar.add_theme_constant_override("separation", 8)
	vbox.add_child(action_bar)

	var btn_paste_clip: Button = Button.new()
	btn_paste_clip.text = "클립보드 붙여넣기"
	btn_paste_clip.custom_minimum_size = Vector2(130, 26)
	action_bar.add_child(btn_paste_clip)

	var btn_file_pick: Button = Button.new()
	btn_file_pick.text = "파일 탐색기..."
	btn_file_pick.custom_minimum_size = Vector2(110, 26)
	action_bar.add_child(btn_file_pick)

	var text_area: TextEdit = TextEdit.new()
	text_area.placeholder_text = "여기에 .triart 또는 .json 파일 내용을 붙여넣으세요..."
	text_area.custom_minimum_size = Vector2(440, 160)
	text_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_area.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	vbox.add_child(text_area)

	btn_paste_clip.pressed.connect(func():
		var clip: String = DisplayServer.clipboard_get()
		if not clip.is_empty():
			text_area.text = clip
	)

	btn_file_pick.pressed.connect(func():
		var f_dialog: FileDialog = FileDialog.new()
		f_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		f_dialog.access = FileDialog.ACCESS_FILESYSTEM
		f_dialog.filters = PackedStringArray(["*.triart, *.json ; Triangle Art Project"])
		f_dialog.file_selected.connect(func(path: String):
			var f = FileAccess.open(path, FileAccess.READ)
			if f:
				text_area.text = f.get_as_text()
				f.close()
			f_dialog.queue_free()
		)
		f_dialog.canceled.connect(func(): f_dialog.queue_free())
		get_tree().root.add_child(f_dialog)
		f_dialog.popup_centered(Vector2i(600, 400))
	)

	# Bottom action buttons
	var btn_box: HBoxContainer = HBoxContainer.new()
	btn_box.alignment = BoxContainer.ALIGNMENT_END
	btn_box.add_theme_constant_override("separation", 10)
	vbox.add_child(btn_box)

	var btn_cancel: Button = Button.new()
	btn_cancel.text = "취소"
	btn_cancel.custom_minimum_size = Vector2(80, 28)
	btn_cancel.pressed.connect(func(): load_project_dialog.queue_free())
	btn_box.add_child(btn_cancel)

	var btn_load: Button = Button.new()
	btn_load.text = "불러오기 (적용)"
	btn_load.custom_minimum_size = Vector2(110, 28)
	btn_load.pressed.connect(func():
		var content: String = text_area.text.strip_edges()
		if not content.is_empty():
			load_project_requested.emit(content)
			load_project_dialog.queue_free()
	)
	btn_box.add_child(btn_load)

	get_tree().root.add_child(load_project_dialog)
	var vp: Vector2 = get_viewport_rect().size
	load_project_dialog.position = (vp - Vector2(480, 340)) / 2.0
