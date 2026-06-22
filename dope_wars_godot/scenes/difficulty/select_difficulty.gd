extends Control
## Difficulty / Duration Selector
## Pick your starting conditions before entering Atlanta's underworld.

@onready var gs: Node = get_node("/root/GameState")

const DIFFICULTIES := [
	{
		"id": "easy",
		"name": "Mount Paran",
		"tag": "EASY",
		"cash": 6000,
		"days": 30,
		"debt": 0,
		"desc": "Low risk, quick game.\nNo debt to start.",
		"color": Color("#00ff9d"),
	},
	{
		"id": "normal",
		"name": "East Atlanta",
		"tag": "NORMAL",
		"cash": 4000,
		"days": 60,
		"debt": 2000,
		"desc": "Balanced start.\n$2,000 debt at 2%/day.",
		"color": Color("#ffd93d"),
	},
	{
		"id": "hard",
		"name": "Hapeville",
		"tag": "HARD",
		"cash": 2000,
		"days": 90,
		"debt": 5000,
		"desc": "Deep in the hole.\n$5,000 debt — interest kills.",
		"color": Color("#ff4444"),
	},
]

func _ready() -> void:
	_setup_ui()

func _setup_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.color = ThemeConst.BG_DARK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Title
	var title := Label.new()
	title.text = "CHOOSE YOUR START"
	title.add_theme_color_override("font_color", ThemeConst.NEON_GREEN)
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 60)
	title.size = Vector2(540, 30)
	add_child(title)

	var sub := Label.new()
	sub.text = "Difficulty determines cash, debt, and game length"
	sub.add_theme_color_override("font_color", ThemeConst.TEXT_DIM)
	sub.add_theme_font_size_override("font_size", 10)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(20, 90)
	sub.size = Vector2(500, 20)
	add_child(sub)

	# Difficulty cards
	var card_y := 140
	for diff in DIFFICULTIES:
		add_child(_build_card(diff, card_y))
		card_y += 210

func _build_card(diff: Dictionary, y: int) -> Panel:
	var card := Panel.new()
	card.position = Vector2(30, y)
	card.size = Vector2(480, 190)

	var style := StyleBoxFlat.new()
	style.bg_color = ThemeConst.CARD_DARK
	style.border_color = diff.color
	style.border_color.a = 0.4
	style.set_border_width_all(1)
	card.add_theme_stylebox_override("panel", style)

	# Invisible button over the whole card
	var btn := TouchScreenButton.new()
	btn.shape = RectangleShape2D.new()
	btn.shape.size = card.size
	btn.position = Vector2.ZERO
	btn.action = "touch"
	btn.pressed.connect(func():
		_select_difficulty(diff.id))
	card.add_child(btn)

	# Card content
	var vbox := VBoxContainer.new()
	vbox.position = Vector2(20, 16)
	vbox.size = Vector2(440, 160)
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	# Row 1: Name + tag
	var row1 := HBoxContainer.new()
	row1.size_flags_horizontal = Control.SIZE_FILL
	vbox.add_child(row1)

	var name_lbl := Label.new()
	name_lbl.text = diff.name
	name_lbl.add_theme_color_override("font_color", diff.color)
	name_lbl.add_theme_font_size_override("font_size", 22)
	row1.add_child(name_lbl)

	var sp1 := Control.new()
	sp1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row1.add_child(sp1)

	var tag_lbl := Label.new()
	tag_lbl.text = "[" + diff.tag + "]"
	tag_lbl.add_theme_color_override("font_color", diff.color)
	tag_lbl.add_theme_font_size_override("font_size", 13)
	tag_lbl.add_theme_constant_override("outline_size", 0)
	row1.add_child(tag_lbl)

	# Separator
	var sep := ColorRect.new()
	sep.color = diff.color
	sep.color.a = 0.15
	sep.custom_minimum_size = Vector2(0, 1)
	vbox.add_child(sep)

	# Stats row
	var stats := HBoxContainer.new()
	vbox.add_child(stats)

	var cash_label := Label.new()
	cash_label.text = "💰 $" + _fmt_num(diff.cash)
	cash_label.add_theme_color_override("font_color", ThemeConst.CASH_GREEN)
	cash_label.add_theme_font_size_override("font_size", 13)
	stats.add_child(cash_label)

	var sp2 := Control.new()
	sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.add_child(sp2)

	var days_label := Label.new()
	days_label.text = "📅 %d Days" % diff.days
	days_label.add_theme_color_override("font_color", ThemeConst.NEON_YELLOW)
	days_label.add_theme_font_size_override("font_size", 13)
	stats.add_child(days_label)

	var sp3 := Control.new()
	sp3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.add_child(sp3)

	var debt_label := Label.new()
	debt_label.text = "💳 $%d debt" % diff.debt if diff.debt > 0 else "💳 No debt"
	debt_label.add_theme_color_override("font_color", ThemeConst.RED if diff.debt > 0 else ThemeConst.NEON_GREEN)
	debt_label.add_theme_font_size_override("font_size", 13)
	stats.add_child(debt_label)

	# Description
	var desc := Label.new()
	desc.text = diff.desc
	desc.add_theme_color_override("font_color", ThemeConst.TEXT_DIM)
	desc.add_theme_font_size_override("font_size", 11)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	return card

func _select_difficulty(diff_id: String) -> void:
	gs.setup_difficulty(diff_id)
	get_tree().change_scene_to_file("res://scenes/shop/shop.tscn")

static func _fmt_num(n: int) -> String:
	var s := str(n)
	var result := ""
	for i in range(s.length(), 0, -1):
		if (s.length() - i) % 3 == 0 and i != s.length():
			result = "," + result
		result = s[i-1] + result
	return result
