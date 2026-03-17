extends Node

signal wallet_changed(amount: int)
signal crystals_changed(amount: int)
signal skin_changed(skin_id: String)
signal block_placed(score: int, combo: int, is_perfect: bool)
signal game_ended(score: int, coins: int, zone: int)
signal zone_reached(zone_index: int)

const SAVE_PATH := "user://save.cfg"

var wallet := 0:
	set(v):
		wallet = v
		wallet_changed.emit(wallet)
var crystals := 0:
	set(v):
		crystals = v
		crystals_changed.emit(crystals)
var high_score := 0
var selected_skin := "default"
var unlocked_skins := ["default"]
var completed_puzzles: Array[String] = []
var tutorial_seen := false
var settings := {"sound": true, "music": true, "vibration": true, "sfx_volume": 1.0, "music_volume": 0.7}

var power_up_inventory := {}
var selected_power_ups: Array[String] = []
var zones_reached := 0
var login_streak := 0
var last_login_date := ""
var last_reward_date := ""

var active_missions: Array[Dictionary] = []
var completed_mission_ids: Array[String] = []
var completed_achievements: Array[String] = []

var games_played := 0
var total_perfects := 0
var max_combo := 0

var _fade_rect: ColorRect
var _transitioning := false

const SKINS := {
	"default": {"name": "Neon", "outline": Color.CYAN, "fill": Color(0.0, 0.3, 0.4, 0.6), "price": 0, "crystal_price": 0},
	"cyber": {"name": "Cyber", "outline": Color(1, 0.2, 0.6), "fill": Color(0.4, 0.05, 0.2, 0.6), "price": 100, "crystal_price": 0},
	"vapor": {"name": "Vapor", "outline": Color(0.6, 0.2, 1), "fill": Color(0.2, 0.05, 0.4, 0.6), "price": 200, "crystal_price": 0},
	"matrix": {"name": "Matrix", "outline": Color(0.2, 1, 0.3), "fill": Color(0.05, 0.3, 0.08, 0.6), "price": 300, "crystal_price": 0},
	"ice": {"name": "Ice", "outline": Color(0.5, 0.85, 1), "fill": Color(0.1, 0.2, 0.4, 0.6), "price": 250, "crystal_price": 0},
	"sunset": {"name": "Sunset", "outline": Color(1, 0.5, 0.15), "fill": Color(0.4, 0.15, 0.02, 0.6), "price": 400, "crystal_price": 0},
	"gold": {"name": "Gold", "outline": Color(1, 0.85, 0.2), "fill": Color(0.35, 0.28, 0.05, 0.6), "price": 500, "crystal_price": 15},
	"plasma": {"name": "Plasma", "outline": Color(0.9, 0.3, 1), "fill": Color(0.35, 0.08, 0.4, 0.6), "price": 150, "crystal_price": 0},
	"toxic": {"name": "Toxic", "outline": Color(0.5, 1, 0.1), "fill": Color(0.15, 0.35, 0.02, 0.6), "price": 200, "crystal_price": 0},
	"chrome": {"name": "Chrome", "outline": Color(0.8, 0.82, 0.85), "fill": Color(0.25, 0.26, 0.28, 0.6), "price": 250, "crystal_price": 0},
	"ruby": {"name": "Ruby", "outline": Color(0.9, 0.1, 0.2), "fill": Color(0.35, 0.03, 0.06, 0.6), "price": 300, "crystal_price": 0},
	"sapphire": {"name": "Sapphire", "outline": Color(0.15, 0.3, 1), "fill": Color(0.04, 0.1, 0.4, 0.6), "price": 300, "crystal_price": 0},
	"emerald": {"name": "Emerald", "outline": Color(0.1, 0.85, 0.5), "fill": Color(0.02, 0.3, 0.15, 0.6), "price": 350, "crystal_price": 0},
	"phantom": {"name": "Phantom", "outline": Color(0.6, 0.55, 0.75), "fill": Color(0.15, 0.12, 0.25, 0.6), "price": 350, "crystal_price": 0},
	"blaze": {"name": "Blaze", "outline": Color(1, 0.35, 0.0), "fill": Color(0.4, 0.1, 0.0, 0.6), "price": 400, "crystal_price": 0},
	"storm": {"name": "Storm", "outline": Color(0.4, 0.6, 0.95), "fill": Color(0.1, 0.18, 0.35, 0.6), "price": 400, "crystal_price": 0},
	"frost": {"name": "Frost", "outline": Color(0.7, 0.95, 1), "fill": Color(0.2, 0.32, 0.38, 0.6), "price": 450, "crystal_price": 0},
	"lava": {"name": "Lava", "outline": Color(1, 0.25, 0.05), "fill": Color(0.4, 0.08, 0.0, 0.6), "price": 450, "crystal_price": 0},
	"nova": {"name": "Nova", "outline": Color(1, 0.9, 0.5), "fill": Color(0.4, 0.3, 0.1, 0.6), "price": 500, "crystal_price": 0},
	"eclipse": {"name": "Eclipse", "outline": Color(0.3, 0.1, 0.5), "fill": Color(0.1, 0.02, 0.2, 0.6), "price": 500, "crystal_price": 10},
	"nebula": {"name": "Nebula", "outline": Color(0.7, 0.3, 0.9), "fill": Color(0.25, 0.08, 0.35, 0.6), "price": 550, "crystal_price": 0},
	"quantum": {"name": "Quantum", "outline": Color(0.0, 1, 0.9), "fill": Color(0.0, 0.3, 0.28, 0.6), "price": 600, "crystal_price": 0},
	"shadow": {"name": "Shadow", "outline": Color(0.35, 0.3, 0.4), "fill": Color(0.08, 0.06, 0.1, 0.6), "price": 600, "crystal_price": 0},
	"lightning": {"name": "Lightning", "outline": Color(0.95, 1, 0.3), "fill": Color(0.35, 0.38, 0.05, 0.6), "price": 650, "crystal_price": 0},
	"crimson": {"name": "Crimson", "outline": Color(0.85, 0.05, 0.15), "fill": Color(0.32, 0.01, 0.04, 0.6), "price": 650, "crystal_price": 0},
	"nuke": {"name": "Nuke", "outline": Color(1, 0.8, 0.0), "fill": Color(0.4, 0.25, 0.0, 0.6), "price": 700, "crystal_price": 10},
	"obsidian": {"name": "Obsidian", "outline": Color(0.2, 0.15, 0.25), "fill": Color(0.05, 0.03, 0.08, 0.6), "price": 750, "crystal_price": 0},
	"titanium": {"name": "Titanium", "outline": Color(0.65, 0.7, 0.75), "fill": Color(0.2, 0.22, 0.25, 0.6), "price": 800, "crystal_price": 0},
	"holo": {"name": "Holo", "outline": Color(0.5, 1, 0.8), "fill": Color(0.12, 0.35, 0.25, 0.6), "price": 900, "crystal_price": 20},
	"prism": {"name": "Prism", "outline": Color(1, 0.5, 0.7), "fill": Color(0.38, 0.15, 0.22, 0.6), "price": 1000, "crystal_price": 25},
}


var safe_area := Rect2i()


func get_safe_top() -> float:
	_update_safe_area()
	var vp := get_viewport()
	if not vp:
		return 0.0
	var screen_h := float(DisplayServer.screen_get_size().y)
	var vp_h := vp.get_visible_rect().size.y
	return float(safe_area.position.y) / screen_h * vp_h


func get_safe_bottom() -> float:
	_update_safe_area()
	var vp := get_viewport()
	if not vp:
		return 0.0
	var screen_h := float(DisplayServer.screen_get_size().y)
	var vp_h := vp.get_visible_rect().size.y
	var bottom_inset := screen_h - (safe_area.position.y + safe_area.size.y)
	return bottom_inset / screen_h * vp_h


func _update_safe_area() -> void:
	safe_area = DisplayServer.get_display_safe_area()


func _ready() -> void:
	_update_safe_area()
	_create_fade_rect()
	load_game()


func _create_fade_rect() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0.05, 0.02, 0.1, 1)
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.modulate.a = 0
	canvas.add_child(_fade_rect)


func change_scene(path: String) -> void:
	if _transitioning:
		return
	_transitioning = true
	var tw := create_tween()
	tw.tween_property(_fade_rect, "modulate:a", 1.0, 0.3)
	tw.tween_callback(get_tree().change_scene_to_file.bind(path))
	tw.tween_interval(0.1)
	tw.tween_property(_fade_rect, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func(): _transitioning = false)


func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "wallet", wallet)
	cfg.set_value("game", "crystals", crystals)
	cfg.set_value("game", "high_score", high_score)
	cfg.set_value("game", "tutorial_seen", tutorial_seen)
	cfg.set_value("game", "selected_skin", selected_skin)
	cfg.set_value("game", "zones_reached", zones_reached)
	cfg.set_value("game", "games_played", games_played)
	cfg.set_value("game", "total_perfects", total_perfects)
	cfg.set_value("game", "max_combo", max_combo)
	cfg.set_value("skins", "unlocked", ",".join(unlocked_skins))
	cfg.set_value("puzzles", "completed", ",".join(completed_puzzles))
	cfg.set_value("settings", "sound", settings.sound)
	cfg.set_value("settings", "music", settings.music)
	cfg.set_value("settings", "vibration", settings.vibration)
	cfg.set_value("settings", "sfx_volume", settings.sfx_volume)
	cfg.set_value("settings", "music_volume", settings.music_volume)

	var pu_parts: Array[String] = []
	for pu_id in power_up_inventory:
		pu_parts.append("%s:%d" % [pu_id, power_up_inventory[pu_id]])
	cfg.set_value("powerups", "inventory", ",".join(pu_parts))
	cfg.set_value("powerups", "selected", ",".join(selected_power_ups))

	cfg.set_value("progress", "login_streak", login_streak)
	cfg.set_value("progress", "last_login_date", last_login_date)
	cfg.set_value("progress", "last_reward_date", last_reward_date)

	var mission_strs: Array[String] = []
	for m in active_missions:
		mission_strs.append("%s|%d" % [m.id, m.progress])
	cfg.set_value("missions", "active", ",".join(mission_strs))
	cfg.set_value("missions", "completed_ids", ",".join(completed_mission_ids))

	cfg.set_value("achievements", "completed", ",".join(completed_achievements))
	cfg.save(SAVE_PATH)


func load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	wallet = cfg.get_value("game", "wallet", 0)
	crystals = cfg.get_value("game", "crystals", 0)
	high_score = cfg.get_value("game", "high_score", 0)
	tutorial_seen = cfg.get_value("game", "tutorial_seen", false)
	selected_skin = cfg.get_value("game", "selected_skin", "default")
	zones_reached = cfg.get_value("game", "zones_reached", 0)
	games_played = cfg.get_value("game", "games_played", 0)
	total_perfects = cfg.get_value("game", "total_perfects", 0)
	max_combo = cfg.get_value("game", "max_combo", 0)

	var skins_str: String = cfg.get_value("skins", "unlocked", "default")
	unlocked_skins = skins_str.split(",") as Array
	var puzzles_str: String = cfg.get_value("puzzles", "completed", "")
	if puzzles_str.length() > 0:
		completed_puzzles.assign(puzzles_str.split(","))

	settings.sound = cfg.get_value("settings", "sound", true)
	settings.music = cfg.get_value("settings", "music", true)
	settings.vibration = cfg.get_value("settings", "vibration", true)
	settings.sfx_volume = cfg.get_value("settings", "sfx_volume", 1.0)
	settings.music_volume = cfg.get_value("settings", "music_volume", 0.7)

	var pu_str: String = cfg.get_value("powerups", "inventory", "")
	power_up_inventory = {}
	if pu_str.length() > 0:
		for part in pu_str.split(","):
			var kv := part.split(":")
			if kv.size() == 2:
				power_up_inventory[kv[0]] = int(kv[1])
	var sel_str: String = cfg.get_value("powerups", "selected", "")
	selected_power_ups = []
	if sel_str.length() > 0:
		selected_power_ups.assign(sel_str.split(","))

	login_streak = cfg.get_value("progress", "login_streak", 0)
	last_login_date = cfg.get_value("progress", "last_login_date", "")
	last_reward_date = cfg.get_value("progress", "last_reward_date", "")

	var missions_str: String = cfg.get_value("missions", "active", "")
	active_missions = []
	if missions_str.length() > 0:
		for part in missions_str.split(","):
			var ms := part.split("|")
			if ms.size() == 2:
				active_missions.append({"id": ms[0], "progress": int(ms[1])})
	var cmi_str: String = cfg.get_value("missions", "completed_ids", "")
	completed_mission_ids = []
	if cmi_str.length() > 0:
		completed_mission_ids.assign(cmi_str.split(","))

	var ach_str: String = cfg.get_value("achievements", "completed", "")
	completed_achievements = []
	if ach_str.length() > 0:
		completed_achievements.assign(ach_str.split(","))


func reset_save() -> void:
	wallet = 0
	crystals = 0
	high_score = 0
	selected_skin = "default"
	unlocked_skins = ["default"]
	completed_puzzles = []
	tutorial_seen = false
	settings = {"sound": true, "music": true, "vibration": true, "sfx_volume": 1.0, "music_volume": 0.7}
	power_up_inventory = {}
	selected_power_ups = []
	zones_reached = 0
	login_streak = 0
	last_login_date = ""
	last_reward_date = ""
	active_missions = []
	completed_mission_ids = []
	completed_achievements = []
	games_played = 0
	total_perfects = 0
	max_combo = 0
	save_game()


func add_coins(amount: int) -> void:
	wallet += amount
	save_game()


func add_crystals(amount: int) -> void:
	crystals += amount
	save_game()


func get_power_up_count(pu_id: String) -> int:
	return power_up_inventory.get(pu_id, 0)


func add_power_up(pu_id: String, count := 1) -> void:
	power_up_inventory[pu_id] = get_power_up_count(pu_id) + count
	save_game()


func consume_power_up(pu_id: String) -> bool:
	var cnt := get_power_up_count(pu_id)
	if cnt <= 0:
		return false
	power_up_inventory[pu_id] = cnt - 1
	if power_up_inventory[pu_id] <= 0:
		power_up_inventory.erase(pu_id)
	save_game()
	return true


func unlock_skin(skin_id: String) -> bool:
	if skin_id in unlocked_skins:
		return false
	var data: Dictionary = get_skin_data(skin_id)
	if data.crystal_price > 0:
		if crystals < data.crystal_price:
			return false
		crystals -= data.crystal_price
	else:
		if wallet < data.price:
			return false
		wallet -= data.price
	unlocked_skins.append(skin_id)
	save_game()
	return true


func select_skin(skin_id: String) -> void:
	if skin_id in unlocked_skins:
		selected_skin = skin_id
		skin_changed.emit(skin_id)
		save_game()



func complete_puzzle(puzzle_id: String) -> void:
	if puzzle_id not in completed_puzzles:
		completed_puzzles.append(puzzle_id)
		add_coins(5)
		add_crystals(5)


func get_skin_data(skin_id: String) -> Dictionary:
	return SKINS.get(skin_id, SKINS["default"])


func get_all_skins() -> Array:
	return SKINS.keys()


func get_today_str() -> String:
	var dt := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [dt.year, dt.month, dt.day]
