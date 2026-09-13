class_name TriangleColorPalette
extends HBoxContainer

## Color palette supporting both Fill and Outline color selection, RGB mixing, and outline removal.

signal color_selected(color: Color, is_outline: bool)
signal color_preview(color: Color, is_outline: bool)
signal outline_remove_requested

enum TargetMode { FILL, OUTLINE }

const PALETTE_COLORS: Array[Dictionary] = [
	# Row 1: 12 Vivid rainbow colors
	{"name": "진빨강", "color": Color("#DC2626")},
	{"name": "빨강", "color": Color("#EF4444")},
	{"name": "주황", "color": Color("#F97316")},
	{"name": "귤색", "color": Color("#FB923C")},
	{"name": "노랑", "color": Color("#FACC15")},
	{"name": "연두", "color": Color("#84CC16")},
	{"name": "초록", "color": Color("#10B981")},
	{"name": "민트", "color": Color("#14B8A6")},
	{"name": "하늘", "color": Color("#06B6D4")},
	{"name": "파랑", "color": Color("#3B82F6")},
	{"name": "남색", "color": Color("#6366F1")},
	{"name": "보라", "color": Color("#A855F7")},

	# Row 2: 12 Soft pastels, earth, and monochrome tones
	{"name": "분홍", "color": Color("#EC4899")},
	{"name": "로즈", "color": Color("#F43F5E")},
	{"name": "살구", "color": Color("#FDBA74")},
	{"name": "베이지", "color": Color("#FDE68A")},
	{"name": "세이지", "color": Color("#A7F3D0")},
	{"name": "라벤더", "color": Color("#DDD6FE")},
	{"name": "갈색", "color": Color("#8D6E63")},
	{"name": "다크브라운", "color": Color("#5D4037")},
	{"name": "흰색", "color": Color("#F8FAFC")},
	{"name": "연회색", "color": Color("#94A3B8")},
	{"name": "먹색", "color": Color("#475569")},
	{"name": "흑색", "color": Color("#1E293B")}
]

const CUSTOM_COLORS_PATH: String = "user://custom_colors.json"
const MAX_CUSTOM_COLORS: int = 8

var current_mode: TargetMode = TargetMode.FILL
var current_fill_color: Color = Color("#3B82F6")
var current_outline_color: Color = Color(0.12, 0.22, 0.38, 1.0)

var custom_colors: Array[Color] = []
var custom_buttons: Array[Button] = []
var custom_grid: GridContainer = null
var btn_add_custom: Button = null

var buttons: Array[Button] = []
var btn_mode_fill: Button = null
var btn_mode_outline: Button = null
var btn_remove_outline: Button = null

var slider_r: HSlider = null
var slider_g: HSlider = null
var slider_b: HSlider = null
var slider_v: HSlider = null
var label_r_val: Label = null
var label_g_val: Label = null
var label_b_val: Label = null
var label_v_val: Label = null

var preview_swatch: Panel = null
var hex_label: Label = null

var _internal_updating: bool = false
var _is_dragging: bool = false

var style_mode_active: StyleBoxFlat = null
var style_mode_inactive: StyleBoxFlat = null

func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 8)
	_load_custom_colors()
	_setup_mode_styles()
	_build_palette()

func _setup_mode_styles() -> void:
	style_mode_active = StyleBoxFlat.new()
	style_mode_active.bg_color = Color(0.18, 0.32, 0.58, 0.95)
	style_mode_active.border_color = Color(0.45, 0.75, 1.0, 1.0)
	style_mode_active.set_border_width_all(1)
	style_mode_active.set_corner_radius_all(5)
	style_mode_active.content_margin_left = 6
	style_mode_active.content_margin_right = 6
	style_mode_active.content_margin_top = 3
	style_mode_active.content_margin_bottom = 3

	style_mode_inactive = StyleBoxFlat.new()
	style_mode_inactive.bg_color = Color(0.1, 0.13, 0.19, 0.85)
	style_mode_inactive.border_color = Color(0.2, 0.26, 0.38, 0.6)
	style_mode_inactive.set_border_width_all(1)
	style_mode_inactive.set_corner_radius_all(5)
	style_mode_inactive.content_margin_left = 6
	style_mode_inactive.content_margin_right = 6
	style_mode_inactive.content_margin_top = 3
	style_mode_inactive.content_margin_bottom = 3

func _build_palette() -> void:
	for child in get_children():
		child.queue_free()
	buttons.clear()

	# 1. Left Target Mode Switcher (Fill vs Outline)
	var mode_box: VBoxContainer = VBoxContainer.new()
	mode_box.add_theme_constant_override("separation", 4)
	mode_box.alignment = BoxContainer.ALIGNMENT_CENTER

	btn_mode_fill = Button.new()
	btn_mode_fill.custom_minimum_size = Vector2(72, 24)
	btn_mode_fill.tooltip_text = "면 채우기 색상을 조절합니다"
	btn_mode_fill.focus_mode = Control.FOCUS_NONE
	btn_mode_fill.add_theme_font_size_override("font_size", 11)
	btn_mode_fill.pressed.connect(func(): _set_target_mode(TargetMode.FILL))
	mode_box.add_child(btn_mode_fill)

	btn_mode_outline = Button.new()
	btn_mode_outline.custom_minimum_size = Vector2(72, 24)
	btn_mode_outline.tooltip_text = "테두리 외곽선 색상을 조절합니다"
	btn_mode_outline.focus_mode = Control.FOCUS_NONE
	btn_mode_outline.add_theme_font_size_override("font_size", 11)
	btn_mode_outline.pressed.connect(func(): _set_target_mode(TargetMode.OUTLINE))
	mode_box.add_child(btn_mode_outline)

	add_child(mode_box)

	# Separator 1
	add_child(_create_vsep())

	# 2. Grid container for 24 swatches (12 columns x 2 rows)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 12
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	add_child(grid)

	for item in PALETTE_COLORS:
		var c: Color = item["color"]
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(26, 26)
		btn.tooltip_text = item["name"]
		btn.focus_mode = Control.FOCUS_NONE

		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = c
		style.set_corner_radius_all(13)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0, 0, 0, 0.25)

		var hover_style: StyleBoxFlat = style.duplicate()
		hover_style.border_color = Color.WHITE
		hover_style.border_width_left = 3
		hover_style.border_width_top = 3
		hover_style.border_width_right = 3
		hover_style.border_width_bottom = 3

		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", hover_style)
		btn.add_theme_stylebox_override("pressed", hover_style)

		btn.pressed.connect(func():
			_on_color_picked(c)
		)

		grid.add_child(btn)
		buttons.append(btn)

	# Separator 2
	add_child(_create_vsep())

	# 3. Custom Colors Cluster ("내 색상", 4 columns x 2 rows = 8 slots)
	var custom_cluster: VBoxContainer = VBoxContainer.new()
	custom_cluster.add_theme_constant_override("separation", 2)
	custom_cluster.alignment = BoxContainer.ALIGNMENT_CENTER

	var custom_header: Label = Label.new()
	custom_header.text = "내 색상"
	custom_header.add_theme_font_size_override("font_size", 9)
	custom_header.add_theme_color_override("font_color", Color(0.65, 0.75, 0.9, 0.8))
	custom_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	custom_cluster.add_child(custom_header)

	custom_grid = GridContainer.new()
	custom_grid.columns = 4
	custom_grid.add_theme_constant_override("h_separation", 4)
	custom_grid.add_theme_constant_override("v_separation", 4)
	custom_cluster.add_child(custom_grid)
	add_child(custom_cluster)

	_refresh_custom_swatches()

	# Separator 3
	add_child(_create_vsep())

	# 4. RGB Sliders Cluster (VBoxContainer with R, G, B rows)
	var rgb_cluster: VBoxContainer = VBoxContainer.new()
	rgb_cluster.add_theme_constant_override("separation", 2)
	rgb_cluster.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(rgb_cluster)

	var active_c: Color = _get_active_target_color()
	var init_r: int = int(roundf(active_c.r * 255.0))
	var init_g: int = int(roundf(active_c.g * 255.0))
	var init_b: int = int(roundf(active_c.b * 255.0))
	var init_v: int = int(roundf(active_c.v * 100.0))

	var row_r = _create_slider_row("R", Color(0.95, 0.3, 0.3), init_r)
	slider_r = row_r["slider"]
	label_r_val = row_r["value_label"]
	rgb_cluster.add_child(row_r["container"])

	var row_g = _create_slider_row("G", Color(0.2, 0.85, 0.45), init_g)
	slider_g = row_g["slider"]
	label_g_val = row_g["value_label"]
	rgb_cluster.add_child(row_g["container"])

	var row_b = _create_slider_row("B", Color(0.3, 0.65, 1.0), init_b)
	slider_b = row_b["slider"]
	label_b_val = row_b["value_label"]
	rgb_cluster.add_child(row_b["container"])

	var row_v = _create_slider_row("명암", Color(0.96, 0.82, 0.28), init_v, 0, 100, "%")
	slider_v = row_v["slider"]
	label_v_val = row_v["value_label"]
	rgb_cluster.add_child(row_v["container"])

	for s in [slider_r, slider_g, slider_b]:
		s.drag_started.connect(_on_slider_drag_started)
		s.value_changed.connect(_on_slider_value_changed)
		s.drag_ended.connect(_on_slider_drag_ended)

	slider_v.drag_started.connect(_on_slider_drag_started)
	slider_v.value_changed.connect(_on_slider_v_value_changed)
	slider_v.drag_ended.connect(_on_slider_drag_ended)

	# Separator 4
	add_child(_create_vsep())

	# 5. Preview & Actions Cluster (Swatch, Hex, Add Custom, and Delete Border button)
	var action_cluster: VBoxContainer = VBoxContainer.new()
	action_cluster.add_theme_constant_override("separation", 3)
	action_cluster.alignment = BoxContainer.ALIGNMENT_CENTER

	var preview_row: HBoxContainer = HBoxContainer.new()
	preview_row.add_theme_constant_override("separation", 6)
	preview_row.alignment = BoxContainer.ALIGNMENT_CENTER

	preview_swatch = Panel.new()
	preview_swatch.custom_minimum_size = Vector2(38, 22)
	preview_row.add_child(preview_swatch)

	hex_label = Label.new()
	hex_label.add_theme_font_size_override("font_size", 10)
	hex_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.95, 1.0))
	hex_label.custom_minimum_size = Vector2(56, 16)
	hex_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	preview_row.add_child(hex_label)
	action_cluster.add_child(preview_row)

	# Button: Add Current RGB to Custom Palette
	btn_add_custom = Button.new()
	btn_add_custom.custom_minimum_size = Vector2(98, 20)
	btn_add_custom.focus_mode = Control.FOCUS_NONE
	btn_add_custom.tooltip_text = "현재 조합된 RGB 색상을 [내 색상] 팔레트 슬롯에 추가합니다"
	btn_add_custom.text = "+ 색상 추가"
	btn_add_custom.add_theme_font_size_override("font_size", 10)

	var add_style: StyleBoxFlat = StyleBoxFlat.new()
	add_style.bg_color = Color(0.12, 0.25, 0.44, 0.9)
	add_style.border_color = Color(0.35, 0.7, 1.0, 0.85)
	add_style.set_border_width_all(1)
	add_style.set_corner_radius_all(4)
	add_style.content_margin_left = 6
	add_style.content_margin_right = 6
	add_style.content_margin_top = 2
	add_style.content_margin_bottom = 2

	var add_hover: StyleBoxFlat = add_style.duplicate()
	add_hover.bg_color = Color(0.18, 0.38, 0.65, 1.0)
	add_hover.border_color = Color(0.55, 0.88, 1.0, 1.0)

	btn_add_custom.add_theme_stylebox_override("normal", add_style)
	btn_add_custom.add_theme_stylebox_override("hover", add_hover)
	btn_add_custom.add_theme_stylebox_override("pressed", add_hover)
	btn_add_custom.add_theme_color_override("font_color", Color(0.85, 0.94, 1.0, 1.0))
	btn_add_custom.pressed.connect(func():
		add_custom_color(_get_active_target_color())
	)
	action_cluster.add_child(btn_add_custom)

	# Button: Delete Border
	btn_remove_outline = Button.new()
	btn_remove_outline.custom_minimum_size = Vector2(98, 20)
	btn_remove_outline.focus_mode = Control.FOCUS_NONE
	btn_remove_outline.tooltip_text = "선택된 삼각형의 테두리를 완전히 삭제합니다 (외곽선 없음)"
	btn_remove_outline.text = "× 테두리 삭제"
	btn_remove_outline.add_theme_font_size_override("font_size", 10)

	var del_style: StyleBoxFlat = StyleBoxFlat.new()
	del_style.bg_color = Color(0.24, 0.08, 0.1, 0.85)
	del_style.border_color = Color(0.75, 0.25, 0.3, 0.75)
	del_style.set_border_width_all(1)
	del_style.set_corner_radius_all(4)
	del_style.content_margin_left = 6
	del_style.content_margin_right = 6
	del_style.content_margin_top = 2
	del_style.content_margin_bottom = 2

	var del_hover: StyleBoxFlat = del_style.duplicate()
	del_hover.bg_color = Color(0.38, 0.12, 0.15, 1.0)
	del_hover.border_color = Color(1.0, 0.4, 0.45, 1.0)

	btn_remove_outline.add_theme_stylebox_override("normal", del_style)
	btn_remove_outline.add_theme_stylebox_override("hover", del_hover)
	btn_remove_outline.add_theme_stylebox_override("pressed", del_hover)
	btn_remove_outline.add_theme_color_override("font_color", Color(1.0, 0.75, 0.78, 1.0))
	btn_remove_outline.pressed.connect(_on_remove_outline_pressed)
	action_cluster.add_child(btn_remove_outline)

	add_child(action_cluster)

	_update_mode_ui()
	_update_preview_and_sliders()

func _create_vsep() -> VSeparator:
	var sep: VSeparator = VSeparator.new()
	var sep_style: StyleBoxLine = StyleBoxLine.new()
	sep_style.color = Color(0.22, 0.28, 0.4, 0.5)
	sep_style.vertical = true
	sep.add_theme_stylebox_override("separator", sep_style)
	return sep

func _create_slider_row(label_text: String, color: Color, initial_val: int, min_v: int = 0, max_v: int = 255, suffix: String = "") -> Dictionary:
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var lbl: Label = Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(24, 14)
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", color)
	hbox.add_child(lbl)

	var slider: HSlider = HSlider.new()
	slider.custom_minimum_size = Vector2(80, 14)
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = 1
	slider.value = initial_val
	slider.focus_mode = Control.FOCUS_NONE

	var track_bg: StyleBoxFlat = StyleBoxFlat.new()
	track_bg.bg_color = Color(0.08, 0.11, 0.17, 0.95)
	track_bg.set_border_width_all(1)
	track_bg.border_color = Color(0.18, 0.24, 0.35, 0.6)
	track_bg.set_corner_radius_all(2)
	track_bg.content_margin_top = 2
	track_bg.content_margin_bottom = 2

	var grab_area: StyleBoxFlat = StyleBoxFlat.new()
	grab_area.bg_color = color.lerp(Color(0.1, 0.1, 0.15), 0.2)
	grab_area.set_corner_radius_all(2)
	grab_area.content_margin_top = 2
	grab_area.content_margin_bottom = 2

	slider.add_theme_stylebox_override("slider", track_bg)
	slider.add_theme_stylebox_override("grabber_area", grab_area)
	slider.add_theme_stylebox_override("grabber_area_highlight", grab_area)

	var icon_tex: ImageTexture = _create_circle_icon(color, 4)
	slider.add_theme_icon_override("grabber", icon_tex)
	slider.add_theme_icon_override("grabber_highlight", icon_tex)

	hbox.add_child(slider)

	var val_lbl: Label = Label.new()
	val_lbl.text = str(initial_val) + suffix
	val_lbl.custom_minimum_size = Vector2(28, 14)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.add_theme_font_size_override("font_size", 10)
	val_lbl.add_theme_color_override("font_color", Color(0.85, 0.9, 0.98, 1.0))
	hbox.add_child(val_lbl)

	return {"container": hbox, "slider": slider, "value_label": val_lbl}

func _create_circle_icon(color: Color, radius: int) -> ImageTexture:
	var size: int = radius * 2 + 2
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(size * 0.5, size * 0.5)
	for y in range(size):
		for x in range(size):
			var dist: float = center.distance_to(Vector2(x + 0.5, y + 0.5))
			if dist <= radius:
				img.set_pixel(x, y, color)
			elif dist <= radius + 0.9:
				var alpha: float = 1.0 - (dist - radius)
				img.set_pixel(x, y, Color(color.r, color.g, color.b, color.a * alpha))
	return ImageTexture.create_from_image(img)

func _set_target_mode(mode: TargetMode) -> void:
	current_mode = mode
	_update_mode_ui()
	_update_preview_and_sliders()

func _update_mode_ui() -> void:
	if not btn_mode_fill or not btn_mode_outline:
		return
	if current_mode == TargetMode.FILL:
		btn_mode_fill.text = "● 면 채우기"
		btn_mode_fill.add_theme_stylebox_override("normal", style_mode_active)
		btn_mode_fill.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0, 1.0))

		btn_mode_outline.text = "○ 테두리 선"
		btn_mode_outline.add_theme_stylebox_override("normal", style_mode_inactive)
		btn_mode_outline.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85, 1.0))
	else:
		btn_mode_fill.text = "○ 면 채우기"
		btn_mode_fill.add_theme_stylebox_override("normal", style_mode_inactive)
		btn_mode_fill.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85, 1.0))

		btn_mode_outline.text = "● 테두리 선"
		btn_mode_outline.add_theme_stylebox_override("normal", style_mode_active)
		btn_mode_outline.add_theme_color_override("font_color", Color(1.0, 0.8, 0.35, 1.0))

func _get_active_target_color() -> Color:
	return current_fill_color if current_mode == TargetMode.FILL else current_outline_color

func _update_preview_and_sliders() -> void:
	var c: Color = _get_active_target_color()
	var is_none: bool = (current_mode == TargetMode.OUTLINE and c.a <= 0.001)

	_internal_updating = true
	var r: int = int(roundf(clampf(c.r, 0.0, 1.0) * 255.0))
	var g: int = int(roundf(clampf(c.g, 0.0, 1.0) * 255.0))
	var b: int = int(roundf(clampf(c.b, 0.0, 1.0) * 255.0))

	if slider_r:
		slider_r.value = r
	if slider_g:
		slider_g.value = g
	if slider_b:
		slider_b.value = b

	if label_r_val:
		label_r_val.text = str(r)
	if label_g_val:
		label_g_val.text = str(g)
	if label_b_val:
		label_b_val.text = str(b)

	if slider_v:
		var v_pct: int = int(roundf(clampf(c.v, 0.0, 1.0) * 100.0))
		slider_v.value = v_pct
		if label_v_val:
			label_v_val.text = "%d%%" % v_pct
	_internal_updating = false

	if preview_swatch:
		var pstyle: StyleBoxFlat = StyleBoxFlat.new()
		pstyle.set_corner_radius_all(5)
		pstyle.set_border_width_all(1)
		if is_none:
			pstyle.bg_color = Color(0.12, 0.15, 0.22, 0.9)
			pstyle.border_color = Color(0.7, 0.3, 0.35, 0.8)
		else:
			pstyle.bg_color = c
			pstyle.border_color = Color(0.4, 0.5, 0.7, 0.8)
		preview_swatch.add_theme_stylebox_override("panel", pstyle)

	if hex_label:
		if is_none:
			hex_label.text = "없음"
			hex_label.add_theme_color_override("font_color", Color(0.85, 0.45, 0.45, 1.0))
		else:
			hex_label.text = "#" + c.to_html(false).to_upper()
			hex_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.95, 1.0))

func _on_color_picked(c: Color) -> void:
	var is_outline: bool = (current_mode == TargetMode.OUTLINE)
	if is_outline:
		current_outline_color = c
	else:
		current_fill_color = c
	_update_preview_and_sliders()
	color_selected.emit(c, is_outline)

func _on_slider_drag_started() -> void:
	_is_dragging = true

func _on_slider_value_changed(_val: float) -> void:
	if _internal_updating:
		return

	var r: int = int(slider_r.value)
	var g: int = int(slider_g.value)
	var b: int = int(slider_b.value)

	label_r_val.text = str(r)
	label_g_val.text = str(g)
	label_b_val.text = str(b)

	var new_color: Color = Color8(r, g, b, 255)

	_internal_updating = true
	if slider_v:
		var v_pct: int = int(roundf(clampf(new_color.v, 0.0, 1.0) * 100.0))
		slider_v.value = v_pct
		if label_v_val:
			label_v_val.text = "%d%%" % v_pct
	_internal_updating = false

	var is_outline: bool = (current_mode == TargetMode.OUTLINE)
	if is_outline:
		current_outline_color = new_color
	else:
		current_fill_color = new_color

	_update_preview_swatch_only(new_color)

	if _is_dragging:
		color_preview.emit(new_color, is_outline)
	else:
		color_selected.emit(new_color, is_outline)

func _on_slider_v_value_changed(_val: float) -> void:
	if _internal_updating:
		return

	var v_percent: int = int(slider_v.value)
	if label_v_val:
		label_v_val.text = "%d%%" % v_percent

	var cur: Color = _get_active_target_color()
	var new_v: float = clampf(float(v_percent) / 100.0, 0.0, 1.0)
	var new_color: Color
	if cur.s < 0.01 and cur.v < 0.01:
		new_color = Color(new_v, new_v, new_v, cur.a)
	elif cur.s < 0.01:
		new_color = Color(new_v, new_v, new_v, cur.a)
	else:
		new_color = Color.from_hsv(cur.h, cur.s, new_v, cur.a)

	_internal_updating = true
	var r: int = int(roundf(clampf(new_color.r, 0.0, 1.0) * 255.0))
	var g: int = int(roundf(clampf(new_color.g, 0.0, 1.0) * 255.0))
	var b: int = int(roundf(clampf(new_color.b, 0.0, 1.0) * 255.0))
	if slider_r: slider_r.value = r
	if slider_g: slider_g.value = g
	if slider_b: slider_b.value = b
	if label_r_val: label_r_val.text = str(r)
	if label_g_val: label_g_val.text = str(g)
	if label_b_val: label_b_val.text = str(b)
	_internal_updating = false

	var is_outline: bool = (current_mode == TargetMode.OUTLINE)
	if is_outline:
		current_outline_color = new_color
	else:
		current_fill_color = new_color

	_update_preview_swatch_only(new_color)

	if _is_dragging:
		color_preview.emit(new_color, is_outline)
	else:
		color_selected.emit(new_color, is_outline)

func _update_preview_swatch_only(c: Color) -> void:
	if preview_swatch:
		var pstyle: StyleBoxFlat = StyleBoxFlat.new()
		pstyle.set_corner_radius_all(5)
		pstyle.set_border_width_all(1)
		pstyle.bg_color = c
		pstyle.border_color = Color(0.4, 0.5, 0.7, 0.8)
		preview_swatch.add_theme_stylebox_override("panel", pstyle)
	if hex_label:
		hex_label.text = "#" + c.to_html(false).to_upper()
		hex_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.95, 1.0))

func _on_slider_drag_ended(value_changed: bool) -> void:
	_is_dragging = false
	if value_changed:
		var active_c: Color = _get_active_target_color()
		color_selected.emit(active_c, current_mode == TargetMode.OUTLINE)

func _on_remove_outline_pressed() -> void:
	current_outline_color = Color(0, 0, 0, 0)
	if current_mode == TargetMode.OUTLINE:
		_update_preview_and_sliders()
	outline_remove_requested.emit()

## Sets the active color (for legacy / compatibility callers)
func set_color(c: Color) -> void:
	if current_mode == TargetMode.FILL:
		current_fill_color = c
	else:
		current_outline_color = c
	_update_preview_and_sliders()

## Synchronizes both fill and outline colors from the selected triangle.
func sync_triangle_colors(fill_c: Color, outline_c: Color) -> void:
	current_fill_color = fill_c
	current_outline_color = outline_c
	_update_preview_and_sliders()

func _load_custom_colors() -> void:
	custom_colors.clear()
	if FileAccess.file_exists(CUSTOM_COLORS_PATH):
		var f: FileAccess = FileAccess.open(CUSTOM_COLORS_PATH, FileAccess.READ)
		if f:
			var res = JSON.parse_string(f.get_as_text())
			if res is Array:
				for hex_val in res:
					custom_colors.append(Color(str(hex_val)))
	if custom_colors.is_empty():
		custom_colors = [Color("#FF6B81"), Color("#6C5CE7")]

func _save_custom_colors() -> void:
	var f: FileAccess = FileAccess.open(CUSTOM_COLORS_PATH, FileAccess.WRITE)
	if f:
		var arr: Array[String] = []
		for c in custom_colors:
			arr.append(c.to_html(false))
		f.store_string(JSON.stringify(arr))

func add_custom_color(col: Color) -> void:
	for c in custom_colors:
		if c.is_equal_approx(col):
			return
	if custom_colors.size() >= MAX_CUSTOM_COLORS:
		custom_colors.pop_front()
	custom_colors.append(col)
	_save_custom_colors()
	_refresh_custom_swatches()

func remove_custom_color(col: Color) -> void:
	for i in range(custom_colors.size() - 1, -1, -1):
		if custom_colors[i].is_equal_approx(col):
			custom_colors.remove_at(i)
			break
	_save_custom_colors()
	_refresh_custom_swatches()

func _refresh_custom_swatches() -> void:
	if not custom_grid:
		return
	for child in custom_grid.get_children():
		child.queue_free()
	custom_buttons.clear()

	for i in range(MAX_CUSTOM_COLORS):
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(24, 24)
		btn.focus_mode = Control.FOCUS_NONE

		if i < custom_colors.size():
			var col: Color = custom_colors[i]
			btn.tooltip_text = "내 색상 #%s (우클릭: 삭제)" % col.to_html(false).to_upper()

			var style: StyleBoxFlat = StyleBoxFlat.new()
			style.bg_color = col
			style.set_corner_radius_all(12)
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2
			style.border_color = Color(0, 0, 0, 0.3)

			var hover_style: StyleBoxFlat = style.duplicate()
			hover_style.border_color = Color.WHITE
			hover_style.border_width_left = 2
			hover_style.border_width_top = 2
			hover_style.border_width_right = 2
			hover_style.border_width_bottom = 2

			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_stylebox_override("hover", hover_style)
			btn.add_theme_stylebox_override("pressed", hover_style)

			btn.gui_input.connect(func(event: InputEvent):
				if event is InputEventMouseButton and event.pressed:
					if event.button_index == MOUSE_BUTTON_RIGHT:
						remove_custom_color(col)
						accept_event()
			)
			btn.pressed.connect(func():
				_on_color_picked(col)
			)
		else:
			btn.tooltip_text = "빈 슬롯 (클릭하거나 [+ 색상 추가]로 등록)"
			var empty_style: StyleBoxFlat = StyleBoxFlat.new()
			empty_style.bg_color = Color(0.15, 0.2, 0.28, 0.5)
			empty_style.set_corner_radius_all(12)
			empty_style.border_width_left = 1
			empty_style.border_width_top = 1
			empty_style.border_width_right = 1
			empty_style.border_width_bottom = 1
			empty_style.border_color = Color(0.3, 0.4, 0.55, 0.4)

			var empty_hover: StyleBoxFlat = empty_style.duplicate()
			empty_hover.border_color = Color(0.4, 0.7, 1.0, 0.8)
			empty_hover.bg_color = Color(0.2, 0.28, 0.4, 0.7)

			btn.add_theme_stylebox_override("normal", empty_style)
			btn.add_theme_stylebox_override("hover", empty_hover)
			btn.add_theme_stylebox_override("pressed", empty_hover)
			btn.text = "+"
			btn.add_theme_font_size_override("font_size", 10)
			btn.add_theme_color_override("font_color", Color(0.5, 0.65, 0.8, 0.6))
			btn.pressed.connect(func():
				add_custom_color(_get_active_target_color())
			)

		custom_grid.add_child(btn)
		custom_buttons.append(btn)
