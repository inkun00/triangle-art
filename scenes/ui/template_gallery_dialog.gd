class_name TemplateGalleryDialog
extends Control

## Modern Modal Gallery Dialog for browsing and loading 30 curated templates
## across 3 progressive difficulty levels (초급, 중급, 고급).

signal template_load_requested(template_name: String)
signal challenge_requested(template_name: String)
signal closed

@onready var btn_close: Button = %BtnClose
@onready var tab_all: Button = %TabAll
@onready var tab_stage1: Button = %TabStage1
@onready var tab_stage2: Button = %TabStage2
@onready var tab_stage3: Button = %TabStage3
@onready var grid_container: GridContainer = %GridContainer
@onready var count_label: Label = %CountLabel

var current_filter: int = 0 # 0: all, 1: stage 1, 2: stage 2, 3: stage 3

func _ready() -> void:
	visible = false

	btn_close.pressed.connect(_on_close_pressed)
	tab_all.pressed.connect(func(): _set_filter(0))
	tab_stage1.pressed.connect(func(): _set_filter(1))
	tab_stage2.pressed.connect(func(): _set_filter(2))
	tab_stage3.pressed.connect(func(): _set_filter(3))

	tab_stage1.icon = _create_circle_icon(Color("#22C55E"), 5)
	tab_stage2.icon = _create_circle_icon(Color("#F59E0B"), 5)
	tab_stage3.icon = _create_circle_icon(Color("#EF4444"), 5)

	resized.connect(_update_responsive_layout)
	_update_responsive_layout()
	_rebuild_cards()

func _update_responsive_layout() -> void:
	if not is_inside_tree():
		return
	var vp_size: Vector2 = get_viewport_rect().size
	if vp_size.x <= 0 or vp_size.y <= 0:
		return
	var panel: PanelContainer = get_node_or_null("CenterContainer/MainPanel") as PanelContainer
	if panel:
		var target_w: float = clampf(vp_size.x - 20.0, 300.0, 950.0)
		var target_h: float = clampf(vp_size.y - 30.0, 340.0, 620.0)
		panel.custom_minimum_size = Vector2(target_w, target_h)
	if grid_container:
		if vp_size.x < 520.0:
			grid_container.columns = 1
		elif vp_size.x < 820.0:
			grid_container.columns = 2
		else:
			grid_container.columns = 3


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

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		# Clicked backdrop outside modal panel
		var panel: Control = get_node_or_null("CenterContainer/MainPanel") as Control
		if panel:
			var local_mouse: Vector2 = panel.get_local_mouse_position()
			if not Rect2(Vector2.ZERO, panel.size).has_point(local_mouse):
				_on_close_pressed()
				accept_event()

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()

func open_gallery() -> void:
	visible = true
	_update_responsive_layout()
	_set_filter(0)


func _on_close_pressed() -> void:
	visible = false
	closed.emit()

func _set_filter(stage: int) -> void:
	current_filter = stage
	_update_tab_styles()
	_rebuild_cards()

func _update_tab_styles() -> void:
	var tabs: Array[Button] = [tab_all, tab_stage1, tab_stage2, tab_stage3]
	for i in range(tabs.size()):
		var b: Button = tabs[i]
		if i == current_filter:
			b.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
		else:
			b.remove_theme_color_override("font_color")

func _rebuild_cards() -> void:
	for child in grid_container.get_children():
		child.queue_free()

	var all_meta: Array[Dictionary] = TriangleTemplates.get_all_template_metadata()
	var displayed_count: int = 0

	for item in all_meta:
		var stage: int = int(item["stage"])
		if current_filter != 0 and stage != current_filter:
			continue

		displayed_count += 1
		var card: PanelContainer = _create_card(item)
		grid_container.add_child(card)

	if count_label:
		count_label.text = "표시 중: %d개 도안" % displayed_count

func _create_card(meta: Dictionary) -> PanelContainer:
	var t_name: String = meta["name"]
	var stage: int = int(meta["stage"])
	var pieces: int = int(meta["pieces"])
	var tag: String = str(meta.get("tag", ""))
	var desc: String = str(meta.get("desc", ""))

	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(285, 140)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Card Style
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.14, 0.22, 0.95)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1

	var stage_color: Color
	var stage_text: String
	match stage:
		1:
			stage_color = Color("#22C55E")
			stage_text = "1단계 · 초급"
			style.border_color = Color(0.18, 0.45, 0.32, 0.7)
		2:
			stage_color = Color("#F59E0B")
			stage_text = "2단계 · 중급"
			style.border_color = Color(0.48, 0.38, 0.18, 0.7)
		3:
			stage_color = Color("#EC4899")
			stage_text = "3단계 · 고급"
			style.border_color = Color(0.55, 0.2, 0.45, 0.7)
		_:
			stage_color = Color("#3B82F6")
			stage_text = "도안"
			style.border_color = Color(0.2, 0.3, 0.5, 0.7)

	style.set_corner_radius_all(10)
	style.content_margin_left = 12.0
	style.content_margin_top = 10.0
	style.content_margin_right = 12.0
	style.content_margin_bottom = 10.0
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	card.add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	# Header row: Stage Badge + Tag + Pieces
	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 6)
	vbox.add_child(top_row)

	var stage_lbl: Label = Label.new()
	stage_lbl.text = stage_text
	stage_lbl.add_theme_color_override("font_color", stage_color)
	stage_lbl.add_theme_font_size_override("font_size", 11)
	top_row.add_child(stage_lbl)

	var dot_lbl: Label = Label.new()
	dot_lbl.text = "·"
	dot_lbl.add_theme_color_override("font_color", Color(0.4, 0.5, 0.65))
	top_row.add_child(dot_lbl)

	var tag_lbl: Label = Label.new()
	tag_lbl.text = tag
	tag_lbl.add_theme_color_override("font_color", Color(0.55, 0.7, 0.9))
	tag_lbl.add_theme_font_size_override("font_size", 11)
	top_row.add_child(tag_lbl)

	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)

	var pieces_lbl: Label = Label.new()
	pieces_lbl.text = "▲ %d조각" % pieces
	pieces_lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 0.95))
	pieces_lbl.add_theme_font_size_override("font_size", 11)
	top_row.add_child(pieces_lbl)

	# Title
	var title_lbl: Label = Label.new()
	title_lbl.text = t_name
	title_lbl.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))
	title_lbl.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title_lbl)

	# Description
	var desc_lbl: Label = Label.new()
	desc_lbl.text = desc
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.72, 0.85))
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(desc_lbl)

	# Buttons Row
	var btn_row: HBoxContainer = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 6)
	vbox.add_child(btn_row)

	# Load button
	var btn_load: Button = Button.new()
	btn_load.text = "도안 불러오기"
	btn_load.custom_minimum_size = Vector2(100, 28)
	btn_load.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_load.tooltip_text = "이 도안의 삼각형들을 캔버스에 색상과 함께 즉시 불러옵니다."
	btn_load.pressed.connect(func():
		visible = false
		template_load_requested.emit(t_name)
	)
	btn_row.add_child(btn_load)

	var btn_challenge: Button = Button.new()
	btn_challenge.text = "도전하기"
	btn_challenge.custom_minimum_size = Vector2(88, 28)
	btn_challenge.tooltip_text = "빈 캔버스에서 이 도안의 실루엣에 도전합니다. 현재 작품은 실행 취소로 복원할 수 있습니다."
	btn_challenge.pressed.connect(func():
		visible = false
		challenge_requested.emit(t_name)
	)
	btn_row.add_child(btn_challenge)

	return card
