extends Node
## Global game state — autoload singleton.
## Tracks money, inventory, location, game day, debt, and prices.

signal money_changed(amount: int)
signal inventory_changed(items: Dictionary)
signal day_changed(day: int)
signal location_changed(location: String)

var money: int = 4000:
	set(v):
		money = max(v, 0)
		money_changed.emit(money)

var inventory: Dictionary = {}:
	set(v):
		inventory = v
		inventory_changed.emit(inventory)

var capacity: int = 100
var current_location: String = "Buckhead":
	set(v):
		current_location = v
		location_changed.emit(v)

var day: int = 1:
	set(v):
		day = v
		day_changed.emit(v)

var max_days: int = 30
var difficulty: String = "normal"
var debt: int = 0

## Location data: coords in a 1000x1000 world space
## Positions from the canonical pixel map (Flutter version)
const LOCATIONS := {
	"Buckhead": {"coords": Vector2(534, 170)},
	"Midtown": {"coords": Vector2(534, 340)},
	"Cobb County": {"coords": Vector2(182, 300)},
	"Little Five Points": {"coords": Vector2(706, 520)},
	"Decatur": {"coords": Vector2(834, 610)},
	"West End": {"coords": Vector2(288, 530)},
}

## Connection graph (bidirectional edges)
const CONNECTIONS := {
	"Buckhead":          ["Midtown", "Cobb County"],
	"Midtown":           ["Buckhead", "Little Five Points", "West End"],
	"Cobb County":       ["Buckhead", "West End"],
	"West End":          ["Cobb County", "Midtown", "Little Five Points", "Decatur"],
	"Little Five Points":["Midtown", "West End", "Decatur"],
	"Decatur":           ["Little Five Points", "West End"],
}

## Location accent colors (for map screen)
const LOC_ACCENTS := {
	"Buckhead":          Color("#00ff9d"),
	"Midtown":           Color("#00bfff"),
	"Cobb County":       Color("#8b5cf6"),
	"West End":          Color("#ff6b6b"),
	"Little Five Points":Color("#ffd93d"),
	"Decatur":           Color("#ff8fab"),
}

func setup_difficulty(diff: String) -> void:
	match diff:
		"easy":
			money = 6000
			max_days = 30
			debt = 0
		"normal":
			money = 4000
			max_days = 60
			debt = 2000
		"hard":
			money = 2000
			max_days = 90
			debt = 5000
	difficulty = diff
	day = 1
	current_location = "Buckhead"
	inventory = {}

func get_current_weight() -> int:
	var total: int = 0
	for item in inventory.values():
		total += item.get("qty", 0) * item.get("weight", 1)
	return total

func get_debt() -> int:
	return debt

func get_price_mod() -> float:
	# Higher days = higher prices (inflation)
	return 1.0 + (day - 1) * 0.005

func apply_daily_interest() -> void:
	if debt > 0:
		debt = ceili(debt * 1.02)  # 2% daily

func get_connections(loc: String) -> Array:
	return CONNECTIONS.get(loc, [])

func has_connection(from_loc: String, to_loc: String) -> bool:
	return to_loc in CONNECTIONS.get(from_loc, [])
	
func travel_to(loc: String) -> bool:
	if not has_connection(current_location, loc):
		return false
	day += 1
	apply_daily_interest()
	current_location = loc
	return true

func load_save(data: Dictionary) -> void:
	money = data.get("money", 4000)
	inventory = data.get("inventory", {})
	current_location = data.get("location", "Buckhead")
	day = data.get("day", 1)
	max_days = data.get("max_days", 30)
	difficulty = data.get("difficulty", "normal")
	debt = data.get("debt", 0)

func to_save_dict() -> Dictionary:
	return {
		"money": money,
		"inventory": inventory,
		"location": current_location,
		"day": day,
		"max_days": max_days,
		"difficulty": difficulty,
		"debt": debt,
	}
