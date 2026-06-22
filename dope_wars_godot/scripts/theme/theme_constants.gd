extends Node
## Theme constants for Dope Wars Atlanta
## All colors, spacing, and style helpers in one place.

## Colors
const BG_DARK := Color("#1a1625")
const CARD_DARK := Color("#2a2438")
const CARD_INNER := Color("#1f1a30")
const NEON_GREEN := Color("#00ff9d")
const NEON_PINK := Color("#ff00f7")
const NEON_YELLOW := Color("#ffd700")
const NEON_PURPLE := Color("#aa66ff")
const TEXT_DIM := Color("#666666")
const TEXT_BODY := Color("#e0e0e0")
const BORDER_DIM := Color("#3a2a48")
const BAR_BG := Color("#0f0b1a")
const CASH_GREEN := Color("#00e676")
const RED := Color("#ff4444")

## Spacing
const PAD_SMALL := 4
const PAD_MEDIUM := 8
const PAD_LARGE := 16
const PAD_XL := 24

## Font sizes
const FONT_TINY := 11
const FONT_SMALL := 13
const FONT_BODY := 15
const FONT_LARGE := 18
const FONT_TITLE := 24
const FONT_HERO := 36

## Shop item data
const ITEMS := {
	"blunts": {"name": "Blunts", "emoji": "🚬", "price": 75, "weight": 1},
	"shrooms": {"name": "Shrooms", "emoji": "🍄", "price": 55, "weight": 2},
	"powda": {"name": "Powda", "emoji": "❄️", "price": 47, "weight": 1},
}

## Helpers
static func flat_style(bg: Color, border: Color, border_width: int = 1, corner: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_width)
	s.corner_radius_top_left = corner
	s.corner_radius_top_right = corner
	s.corner_radius_bottom_left = corner
	s.corner_radius_bottom_right = corner
	return s

static func dark_button() -> StyleBoxFlat:
	return flat_style(Color("#0f0b1a"), NEON_GREEN, 1)

static func hover_button() -> StyleBoxFlat:
	var s := flat_style(CARD_INNER, NEON_GREEN, 2)
	s.border_color.a = 1.0
	return s
