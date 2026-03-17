extends Control

@onready var coin_label: Label = $TopBar/CoinLabel
@onready var crystal_label: Label = $TopBar/CrystalLabel
@onready var bg: TextureRect = $BG
@onready var bg2: TextureRect = $BG2
@onready var logo: VBoxContainer = $Logo
@onready var title_label: Label = $Logo/Title
@onready var subtitle_label: Label = $Logo/Subtitle

var time := 0.0
var bg_offset := 0.0
var _safe_top := 0.0


func _ready() -> void:
	_apply_safe_area()
	_update_currencies()
	GameManager.wallet_changed.connect(func(_v): _update_currencies())
	GameManager.crystals_changed.connect(func(_v): _update_currencies())
	_style_buttons()
	_animate_intro()
	_start_logo_glow()
	SoundManager.play_music("res://assets/music/bg_music.mp3")

	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	var AchScript = load("res://scripts/achievements/achievements.gd")
	if AchScript:
		AchScript.check_all()

	var DailyScript = load("res://scripts/overlays/daily_reward.gd")
	if DailyScript and DailyScript.should_show():
		var scene: PackedScene = load("res://scenes/overlays/daily_reward.tscn")
		if scene:
			add_child(scene.instantiate())


func _update_currencies() -> void:
	coin_label.text = str(GameManager.wallet)
	crystal_label.text = str(GameManager.crystals)


func _apply_safe_area() -> void:
	_safe_top = GameManager.get_safe_top()
	$TopBar.offset_top = maxf(_safe_top, 10.0)
	$TopBar.offset_bottom = $TopBar.offset_top + 40.0


func _process(delta: float) -> void:
	time += delta

	var vp_h := get_viewport_rect().size.y
	bg.size = Vector2(810, vp_h + 60)
	bg2.size = bg.size
	bg.position.y = sin(time * 0.3) * 20.0 - 30.0
	bg2.position.y = bg.position.y + bg.size.y

	bg.position.x = -30.0 + sin(time * 0.5) * 12.0
	bg2.position.x = bg.position.x

	var logo_base := maxf(160.0, _safe_top + 60.0)
	logo.position.y = logo_base + sin(time * 2.2) * 12.0
	logo.rotation = sin(time * 1.8) * 0.012
	var s := 1.0 + sin(time * 1.5) * 0.02
	logo.scale = Vector2(s, s)


func _start_logo_glow() -> void:
	var tw := create_tween().set_loops()
	tw.tween_property(title_label, "theme_override_colors/font_color", Color(0.3, 1, 1, 1), 0.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(title_label, "theme_override_colors/font_color", Color(0, 0.7, 0.8, 1), 0.8).set_trans(Tween.TRANS_SINE)

	var tw2 := create_tween().set_loops()
	tw2.tween_property(subtitle_label, "theme_override_colors/font_color", Color(0.7, 0.3, 1, 0.9), 0.6).set_trans(Tween.TRANS_SINE)
	tw2.tween_property(subtitle_label, "theme_override_colors/font_color", Color(0.5, 0.15, 0.85, 0.75), 0.6).set_trans(Tween.TRANS_SINE)


func _animate_intro() -> void:
	logo.modulate.a = 0.0
	logo.scale = Vector2(0.3, 0.3)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(logo, "modulate:a", 1.0, 0.4)
	tw.tween_property(logo, "scale", Vector2.ONE, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	var idx := 0
	for btn in $Buttons.get_children():
		if btn is Button:
			var orig_x: float = btn.position.x
			btn.modulate.a = 0.0
			btn.position.x = 400.0
			var d := 0.15 + idx * 0.07
			var tw2 := create_tween()
			tw2.set_parallel(true)
			tw2.tween_property(btn, "modulate:a", 1.0, 0.25).set_delay(d)
			tw2.tween_property(btn, "position:x", orig_x, 0.35).set_delay(d).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			idx += 1

	$TopBar.modulate.a = 0.0
	create_tween().tween_property($TopBar, "modulate:a", 1.0, 0.4).set_delay(0.5)


func _style_buttons() -> void:
	for btn in $Buttons.get_children():
		if btn is Button:
			UIStyle.neon_button(btn)


func _on_play_pressed() -> void:
	SoundManager.play_sfx("res://assets/sounds/button.mp3")
	var has_pu := false
	for pu_id in GameManager.power_up_inventory:
		if GameManager.power_up_inventory[pu_id] > 0:
			has_pu = true
			break
	if has_pu:
		var scene: PackedScene = load("res://scenes/game/pre_game.tscn")
		add_child(scene.instantiate())
	else:
		GameManager.selected_power_ups = []
		GameManager.change_scene("res://scenes/game/game.tscn")


func _on_shop_pressed() -> void:
	SoundManager.play_sfx("res://assets/sounds/button.mp3")
	GameManager.change_scene("res://scenes/shop/shop.tscn")


func _on_puzzle_pressed() -> void:
	SoundManager.play_sfx("res://assets/sounds/button.mp3")
	GameManager.change_scene("res://scenes/puzzle/puzzle_list.tscn")


func _on_missions_pressed() -> void:
	SoundManager.play_sfx("res://assets/sounds/button.mp3")
	_show_missions_popup()


func _on_achievements_pressed() -> void:
	SoundManager.play_sfx("res://assets/sounds/button.mp3")
	GameManager.change_scene("res://scenes/achievements/achievements.tscn")


func _on_settings_pressed() -> void:
	SoundManager.play_sfx("res://assets/sounds/button.mp3")
	var packed: PackedScene = load("res://scenes/settings/settings.tscn")
	var overlay := packed.instantiate()
	add_child(overlay)


func _show_missions_popup() -> void:
	var overlay := CanvasLayer.new()
	overlay.layer = 30
	add_child(overlay)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.6)
	overlay.add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -300
	panel.offset_top = -350
	panel.offset_right = 300
	panel.offset_bottom = 350
	UIStyle.neon_panel(panel)
	overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "MISSIONS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0, 1, 1, 1))
	title.add_theme_font_size_override("font_size", 28)
	var font := load("res://assets/fonts/Orbitron-Bold.ttf")
	if font:
		title.add_theme_font_override("font", font)
	vbox.add_child(title)

	var missions := MissionManager.get_active_with_pool()
	if missions.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "All missions completed!"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		empty_lbl.add_theme_font_size_override("font_size", 20)
		vbox.add_child(empty_lbl)
	else:
		for m in missions:
			var row := PanelContainer.new()
			var rs := StyleBoxFlat.new()
			rs.bg_color = Color(0.02, 0.01, 0.05, 0.7)
			rs.border_color = Color(0, 0.8, 0.85, 0.3)
			rs.set_border_width_all(1)
			rs.set_corner_radius_all(8)
			rs.content_margin_left = 12
			rs.content_margin_right = 12
			rs.content_margin_top = 10
			rs.content_margin_bottom = 10
			row.add_theme_stylebox_override("panel", rs)

			var rv := VBoxContainer.new()
			rv.add_theme_constant_override("separation", 4)
			row.add_child(rv)

			var desc := Label.new()
			desc.text = m.desc
			desc.add_theme_color_override("font_color", Color(0.9, 0.9, 1, 0.9))
			desc.add_theme_font_size_override("font_size", 18)
			rv.add_child(desc)

			var progress := Label.new()
			progress.text = "%d / %d" % [mini(m.progress, m.target), m.target]
			progress.add_theme_color_override("font_color", Color(0, 1, 1, 0.7))
			progress.add_theme_font_size_override("font_size", 14)
			rv.add_child(progress)

			var reward_parts: Array[String] = []
			if m.reward_coins > 0:
				reward_parts.append("%d coins" % m.reward_coins)
			if m.reward_crystals > 0:
				reward_parts.append("%d crystals" % m.reward_crystals)
			if m.reward_pu != "":
				var pu_data: Dictionary = PowerUpData.info(m.reward_pu)
				reward_parts.append(pu_data.name if not pu_data.is_empty() else m.reward_pu)
			var reward := Label.new()
			reward.text = "Reward: " + ", ".join(reward_parts)
			reward.add_theme_color_override("font_color", Color(1, 0.85, 0, 0.7))
			reward.add_theme_font_size_override("font_size", 14)
			rv.add_child(reward)

			vbox.add_child(row)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	var close_btn := Button.new()
	close_btn.text = "CLOSE"
	close_btn.custom_minimum_size = Vector2(200, 56)
	close_btn.pressed.connect(func():
		SoundManager.play_sfx("res://assets/sounds/button.mp3")
		overlay.queue_free()
	)
	UIStyle.neon_button(close_btn)
	vbox.add_child(close_btn)

	panel.modulate.a = 0.0
	panel.scale = Vector2(0.7, 0.7)
	panel.pivot_offset = Vector2(300, 350)
	dim.modulate.a = 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(dim, "modulate:a", 1.0, 0.25)
	tw.tween_property(panel, "modulate:a", 1.0, 0.25)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
