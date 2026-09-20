class_name TestResponsiveUI
extends RefCounted

## Unit and integration tests for responsive UI scaling, mobile layouts, and scroll containers.

const MainScene = preload("res://scenes/main/main.tscn")
const ToolbarScene = preload("res://scenes/ui/toolbar.tscn")
const GalleryScene = preload("res://scenes/ui/template_gallery_dialog.tscn")

static func run(runner) -> void:
	test_toolbar_scroll_actions(runner)
	test_template_gallery_responsive(runner)
	test_main_responsive_modes(runner)

static func test_toolbar_scroll_actions(runner) -> void:
	var toolbar = ToolbarScene.instantiate()
	runner.add_child(toolbar)
	runner.assert_not_null(toolbar, "Toolbar scene should instantiate")

	var scroll_actions: ScrollContainer = toolbar.get_node_or_null("VBox/ScrollActions") as ScrollContainer
	runner.assert_not_null(scroll_actions, "ScrollActions ScrollContainer must exist in Toolbar")
	runner.assert_eq(scroll_actions.horizontal_scroll_mode, ScrollContainer.SCROLL_MODE_AUTO, "Horizontal scroll should be AUTO")
	runner.assert_eq(scroll_actions.vertical_scroll_mode, ScrollContainer.SCROLL_MODE_DISABLED, "Vertical scroll should be DISABLED")

	# Verify buttons are bound via unique names
	runner.assert_not_null(toolbar.btn_new, "BtnNew should be resolved")
	runner.assert_not_null(toolbar.btn_export, "BtnExport should be resolved")
	runner.assert_not_null(toolbar.btn_templates, "BtnTemplates should be resolved")

	# Test compact mode toggle
	toolbar.set_compact_mode(true)
	if toolbar.label_tips:
		runner.assert_true("터치" in toolbar.label_tips.text, "Tips label should show touch gestures in compact mode")

	toolbar.set_compact_mode(false)
	if toolbar.label_tips:
		runner.assert_true("우클릭" in toolbar.label_tips.text, "Tips label should show mouse/keyboard shortcuts in normal mode")

	runner.remove_child(toolbar)
	toolbar.queue_free()

static func test_template_gallery_responsive(runner) -> void:
	var gallery = GalleryScene.instantiate()
	runner.add_child(gallery)
	runner.assert_not_null(gallery, "Gallery dialog should instantiate")

	var scroll_filter: ScrollContainer = gallery.get_node_or_null("CenterContainer/MainPanel/VBox/ScrollFilter") as ScrollContainer
	runner.assert_not_null(scroll_filter, "FilterBar should be wrapped in ScrollFilter ScrollContainer")
	runner.assert_eq(scroll_filter.horizontal_scroll_mode, ScrollContainer.SCROLL_MODE_AUTO, "Filter scroll horizontal should be AUTO")

	var main_panel: PanelContainer = gallery.get_node_or_null("CenterContainer/MainPanel") as PanelContainer
	runner.assert_not_null(main_panel, "MainPanel must exist")

	runner.remove_child(gallery)
	gallery.queue_free()

static func test_main_responsive_modes(runner) -> void:
	var main = MainScene.instantiate()
	runner.add_child(main)
	runner.assert_not_null(main, "Main scene should instantiate")

	runner.assert_not_null(main.palette_container, "PaletteContainer should be resolved via unique name")
	runner.assert_not_null(main.palette, "ColorPalette should be resolved")
	runner.assert_not_null(main.toolbar, "Toolbar should be resolved")
	runner.assert_not_null(main.toast_label, "ToastLabel should be resolved")

	# Test applying compact mode
	main._apply_responsive_ui(true)
	runner.assert_eq(main.palette_container.anchor_left, 0.0, "Palette anchor_left should be 0.0 in compact mode")
	runner.assert_eq(main.palette_container.anchor_right, 1.0, "Palette anchor_right should be 1.0 in compact mode")
	runner.assert_eq(main.toast_label.anchor_left, 0.0, "Toast anchor_left should be 0.0 in compact mode")
	runner.assert_eq(main.toast_label.anchor_right, 1.0, "Toast anchor_right should be 1.0 in compact mode")
	if main.palette.buttons.size() > 0:
		runner.assert_eq(main.palette.buttons[0].custom_minimum_size, Vector2(28, 28), "Swatches should enlarge in compact mode")

	# Test applying desktop mode
	main._apply_responsive_ui(false)
	runner.assert_eq(main.palette_container.anchor_left, 0.5, "Palette anchor_left should be 0.5 in desktop mode")
	runner.assert_eq(main.palette_container.anchor_right, 0.5, "Palette anchor_right should be 0.5 in desktop mode")
	runner.assert_eq(main.toast_label.anchor_left, 0.5, "Toast anchor_left should be 0.5 in desktop mode")
	runner.assert_eq(main.toast_label.anchor_right, 0.5, "Toast anchor_right should be 0.5 in desktop mode")
	if main.palette.buttons.size() > 0:
		runner.assert_eq(main.palette.buttons[0].custom_minimum_size, Vector2(26, 26), "Swatches should restore desktop size")

	runner.remove_child(main)
	main.queue_free()
