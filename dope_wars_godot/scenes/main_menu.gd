extends Control
## Main Menu — Dope Wars Atlanta
## Routes to difficulty selector for new game.

const _ThemeConst := preload("res://scripts/theme/theme_constants.gd")

func _ready() -> void:
	_use_ThemeConst_ref()  # ensure autoload is warm

	# Background
	var bg := ColorRect.new()
	bg.color = ThemeConst.BG_DARK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Decorative grid overlay (subtle)
	var grid := ColorRect.new()
	grid.color = ThemeConst.BORDER_DIM
	grid.color.a = 0.04
	grid.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(grid)

	# Title glows (decorative circles behind title)
	for i in 3:
		var glow := ColorRect.new()
		glow.color = ThemeConst.NEON_GREEN
		glow.color.a = 0.03
		glow.size = Vector2(200 + i * 40, 200 + i * 40)
		glow.set_anchors_preset(Control.PRESET_CENTER)
		glow.position -= glow.size / 2
		glow.position.y -= 80
		add_child(glow)

	# Title
	var title := Label.new()
	title.text = "DOPE WARS"
	title.add_theme_color_override("font_color", ThemeConst.NEON_GREEN)
	title.add_theme_font_size_override("font_size", 42)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.offset_top = -70
	add_child(title)

	# Subtitle
	var sub := Label.new()
	sub.text = "A T L A N T A"
	sub.add_theme_color_override("font_color", ThemeConst.NEON_PINK)
	sub.add_theme_font_size_override("font_size", 18)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.set_anchors_preset(Control.PRESET_CENTER)
	sub.offset_top = -28
	add_child(sub)

	# Separator line
	var sep := ColorRect.new()
	sep.color = ThemeConst.NEON_GREEN
	sep.color.a = 0.2
	sep.size = Vector2(120, 1)
	sep.set_anchors_preset(Control.PRESET_CENTER)
	sep.position = Vector2(-60, 10)
	add_child(sep)

	# Tagline
	var tagline := Label.new()
	tagline.text = "Build your empire. Stay alive."
	tagline.add_theme_color_override("font_color", ThemeConst.TEXT_DIM)
	tagline.add_theme_font_size_override("font_size", 11)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.set_anchors_preset(Control.PRESET_CENTER)
	tagline.offset_top = 28
	add_child(tagline)

	# Start button
	var btn := _make_menu_btn("▶  NEW GAME")
	btn.position = Vector2(170, 560)
	btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/difficulty/select_difficulty.tscn"))
	add_child(btn)


func _make_menu_btn(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(200, 44)

	var normal := _ThemeConst.flat_style(_ThemeConst.BAR_BG, _ThemeConst.NEON_GREEN, 1)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_color_override("font_color", ThemeConst.NEON_GREEN)
	btn.add_theme_font_size_override("font_size", 14)

	var hov := _ThemeConst.flat_style(_ThemeConst.CARD_INNER, _ThemeConst.NEON_GREEN, 2)
	btn.add_theme_stylebox_override("hover", hov)
	btn.add_theme_color_override("font_color_hover", ThemeConst.NEON_GREEN)

	return btn


func _use_ThemeConst_ref() -> void:
	# Touch autoload so it's fully initialized
	pass
