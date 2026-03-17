extends Control

const ACHIEVEMENT_LIST := [
	{"id": "first_game", "name": "First Steps", "desc": "Play 1 game", "crystals": 1},
	{"id": "games_10", "name": "Regular", "desc": "Play 10 games", "crystals": 1},
	{"id": "games_50", "name": "Veteran", "desc": "Play 50 games", "crystals": 2},
	{"id": "score_50", "name": "Half Century", "desc": "Score 50 points", "crystals": 1},
	{"id": "score_100", "name": "Tower Master", "desc": "Score 100 points", "crystals": 3},
	{"id": "score_200", "name": "Legend", "desc": "Score 200 points", "crystals": 5},
	{"id": "combo_5", "name": "Combo x5", "desc": "5 perfects in a row", "crystals": 1},
	{"id": "combo_10", "name": "Perfect x10", "desc": "10 perfects in a row", "crystals": 2},
	{"id": "combo_20", "name": "Unreal", "desc": "20 perfects in a row", "crystals": 3},
	{"id": "zone_2", "name": "Neon Tourist", "desc": "Reach Neon District", "crystals": 1},
	{"id": "zone_3", "name": "Chromed", "desc": "Reach Chrome Bridge", "crystals": 1},
	{"id": "zone_4", "name": "Corporate", "desc": "Reach Megacorp", "crystals": 2},
	{"id": "zone_5", "name": "Cosmonaut", "desc": "Reach Orbit", "crystals": 3},
	{"id": "zone_6", "name": "The One", "desc": "Reach Matrix", "crystals": 5},
	{"id": "all_skins", "name": "Collector", "desc": "Unlock all skins", "crystals": 5},
]

@onready var scroll: ScrollContainer = $VBox/Scroll
@onready var list: VBoxContainer = $VBox/Scroll/List
@onready var title_label: Label = $TopBar/Title


func _ready() -> void:
	_apply_safe_area()
	UIStyle.small_neon_button($TopBar/BackBtn)
	_build_list()
	_start_title_glow()


func _apply_safe_area() -> void:
	var safe_top := GameManager.get_safe_top()
	var safe_bottom := GameManager.get_safe_bottom()
	$TopBar.offset_top = maxf(safe_top, 10.0)
	$TopBar.offset_bottom = $TopBar.offset_top + 50.0
	$VBox.offset_top = $TopBar.offset_bottom + 10.0
	$VBox.offset_bottom = -maxf(safe_bottom, 20.0)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _start_title_glow() -> void:
	var tw := create_tween().set_loops()
	tw.tween_property(title_label, "theme_override_colors/font_color", Color(0.3, 1, 1, 1), 1.0).set_trans(Tween.TRANS_SINE)
	tw.tween_property(title_label, "theme_override_colors/font_color", Color(0, 0.65, 0.75, 1), 1.0).set_trans(Tween.TRANS_SINE)


func _build_list() -> void:
	for child in list.get_children():
		child.queue_free()

	var done_count := 0
	var idx := 0
	for ach in ACHIEVEMENT_LIST:
		var done: bool = ach.id in GameManager.completed_achievements
		if done:
			done_count += 1
		var row := _create_row(ach, done, idx)
		list.add_child(row)
		idx += 1

	var counter := Label.new()
	counter.text = "%d / %d completed" % [done_count, ACHIEVEMENT_LIST.size()]
	counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	counter.add_theme_color_override("font_color", Color(0, 1, 1, 0.6))
	counter.add_theme_font_size_override("font_size", 16)
	list.add_child(counter)
	list.move_child(counter, 0)


func _create_row(ach: Dictionary, done: bool, idx: int) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	if done:
		style.bg_color = Color(0.02, 0.08, 0.06, 0.88)
		style.border_color = Color(0.2, 1, 0.4, 0.55)
		style.shadow_color = Color(0.2, 1, 0.4, 0.1)
		style.shadow_size = 8
	else:
		style.bg_color = Color(0.03, 0.015, 0.07, 0.85)
		style.border_color = Color(0.2, 0.2, 0.3, 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	panel.add_child(hbox)

	var icon_tex := TextureRect.new()
	icon_tex.texture = load("res://assets/sprites/ui/crystal.png") if done else load("res://assets/sprites/ui/lock.png")
	icon_tex.custom_minimum_size = Vector2(38, 38)
	icon_tex.expand_mode = 3
	icon_tex.stretch_mode = 5
	icon_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not done:
		icon_tex.modulate = Color(0.4, 0.4, 0.5, 0.5)
	hbox.add_child(icon_tex)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	hbox.add_child(info)

	var name_lbl := Label.new()
	name_lbl.text = ach.name
	name_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.95) if done else Color(0.7, 0.7, 0.8, 0.7))
	name_lbl.add_theme_font_size_override("font_size", 19)
	info.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = ach.desc
	desc_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6, 0.6))
	desc_lbl.add_theme_font_size_override("font_size", 13)
	info.add_child(desc_lbl)

	var reward_box := HBoxContainer.new()
	reward_box.add_theme_constant_override("separation", 4)
	reward_box.alignment = BoxContainer.ALIGNMENT_END
	var cr_icon := TextureRect.new()
	cr_icon.texture = load("res://assets/sprites/ui/crystal.png")
	cr_icon.custom_minimum_size = Vector2(20, 20)
	cr_icon.expand_mode = 3
	cr_icon.stretch_mode = 5
	cr_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if done:
		cr_icon.modulate = Color(0.5, 0.7, 0.5, 0.5)
	reward_box.add_child(cr_icon)
	var reward_lbl := Label.new()
	reward_lbl.text = str(ach.crystals)
	reward_lbl.add_theme_color_override("font_color", Color(0.5, 0.85, 1, 0.85) if not done else Color(0.3, 0.6, 0.4, 0.5))
	reward_lbl.add_theme_font_size_override("font_size", 17)
	reward_box.add_child(reward_lbl)
	hbox.add_child(reward_box)

	panel.modulate.a = 0.0
	panel.scale = Vector2(0.95, 0.95)
	panel.pivot_offset = Vector2(355, 25)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "modulate:a", 1.0, 0.25).set_delay(idx * 0.04)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.3).set_delay(idx * 0.04).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	if done:
		var glow_tw := create_tween().set_loops().bind_node(panel)
		glow_tw.tween_property(panel, "modulate", Color(1, 1, 1, 1), 2.0).set_trans(Tween.TRANS_SINE).set_delay(idx * 0.04 + 0.3)
		glow_tw.tween_property(panel, "modulate", Color(1.1, 1.1, 1.1, 1), 2.0).set_trans(Tween.TRANS_SINE)

	return panel


func _on_back_pressed() -> void:
	SoundManager.play_sfx("res://assets/sounds/button.mp3")
	GameManager.change_scene("res://scenes/main_menu/main_menu.tscn")


static func check_all() -> void:
	_check("first_game", GameManager.games_played >= 1)
	_check("games_10", GameManager.games_played >= 10)
	_check("games_50", GameManager.games_played >= 50)
	_check("score_50", GameManager.high_score >= 50)
	_check("score_100", GameManager.high_score >= 100)
	_check("score_200", GameManager.high_score >= 200)
	_check("combo_5", GameManager.max_combo >= 5)
	_check("combo_10", GameManager.max_combo >= 10)
	_check("combo_20", GameManager.max_combo >= 20)
	_check("zone_2", GameManager.zones_reached >= 1)
	_check("zone_3", GameManager.zones_reached >= 2)
	_check("zone_4", GameManager.zones_reached >= 3)
	_check("zone_5", GameManager.zones_reached >= 4)
	_check("zone_6", GameManager.zones_reached >= 5)
	_check("all_skins", GameManager.unlocked_skins.size() >= GameManager.SKINS.size())


static func _check(ach_id: String, condition: bool) -> void:
	if not condition:
		return
	if ach_id in GameManager.completed_achievements:
		return
	GameManager.completed_achievements.append(ach_id)
	var crystals := 0
	for ach in ACHIEVEMENT_LIST:
		if ach.id == ach_id:
			crystals = ach.crystals
			break
	if crystals > 0:
		GameManager.add_crystals(crystals)
	GameManager.save_game()
