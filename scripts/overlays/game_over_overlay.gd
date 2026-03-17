extends CanvasLayer

@onready var score_val: Label = $Panel/VBox/ScoreVal
@onready var best_val: Label = $Panel/VBox/BestRow/BestVal
@onready var coins_val: Label = $Panel/VBox/CoinsRow/CoinsVal
@onready var panel: PanelContainer = $Panel
@onready var dim: ColorRect = $Dim
@onready var title: Label = $Panel/VBox/Title
@onready var retry_btn: Button = $Panel/VBox/RetryBtn
@onready var menu_btn: Button = $Panel/VBox/MenuBtn
@onready var score_title: Label = $Panel/VBox/ScoreTitle
@onready var best_row: HBoxContainer = $Panel/VBox/BestRow
@onready var coins_row: HBoxContainer = $Panel/VBox/CoinsRow


func setup(final_score: int, coins: int, best: int) -> void:
	await ready
	var AchScript = load("res://scripts/achievements/achievements.gd")
	if AchScript:
		AchScript.check_all()
	UIStyle.neon_panel(panel)
	UIStyle.neon_button(retry_btn)
	UIStyle.neon_button(menu_btn)

	UIStyle.overlay_particles(self, Color(1, 0.3, 0.1, 0.12))

	_spawn_embers()

	dim.modulate.a = 0.0
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.4, 0.4)
	panel.pivot_offset = panel.size / 2.0

	for node in [title, score_title, score_val, best_row, coins_row, retry_btn, menu_btn]:
		node.modulate.a = 0.0

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(dim, "modulate:a", 1.0, 0.35)
	tw.tween_property(panel, "modulate:a", 1.0, 0.3).set_delay(0.1)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.5).set_delay(0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	await get_tree().create_timer(0.3).timeout

	title.pivot_offset = title.size / 2.0
	title.scale = Vector2(2.0, 2.0)
	var tw_title := create_tween()
	tw_title.set_parallel(true)
	tw_title.tween_property(title, "modulate:a", 1.0, 0.2)
	tw_title.tween_property(title, "scale", Vector2.ONE, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	await get_tree().create_timer(0.25).timeout

	score_title.modulate.a = 0.0
	var tw_st := create_tween()
	tw_st.tween_property(score_title, "modulate:a", 1.0, 0.2)

	score_val.text = "0"
	score_val.modulate.a = 1.0
	score_val.pivot_offset = score_val.size / 2.0
	best_val.text = str(best)
	coins_val.text = str(coins)

	await get_tree().create_timer(0.15).timeout
	_count_up(score_val, final_score, 0.8)

	await get_tree().create_timer(0.4).timeout

	var tw_info := create_tween()
	tw_info.tween_property(best_row, "modulate:a", 1.0, 0.2)
	tw_info.tween_property(coins_row, "modulate:a", 1.0, 0.2)

	await get_tree().create_timer(0.3).timeout

	var is_record := final_score >= best and final_score > 0
	if is_record:
		_spawn_record_burst()
		_record_label()

	var btn_delay := 0.0
	for btn in [retry_btn, menu_btn]:
		var tw_btn := create_tween()
		tw_btn.tween_property(btn, "modulate:a", 1.0, 0.25).set_delay(btn_delay)
		btn_delay += 0.12

	var glow := create_tween().set_loops()
	glow.tween_property(title, "theme_override_colors/font_color", Color(1, 0.3, 0.4, 1), 0.6).set_trans(Tween.TRANS_SINE)
	glow.tween_property(title, "theme_override_colors/font_color", Color(1, 0.08, 0.15, 1), 0.6).set_trans(Tween.TRANS_SINE)


func _record_label() -> void:
	var lbl := Label.new()
	lbl.text = "NEW RECORD!"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	lbl.offset_top = 100
	lbl.offset_left = -150
	lbl.offset_right = 150
	lbl.add_theme_color_override("font_color", Color(1, 0.85, 0))
	lbl.add_theme_font_size_override("font_size", 32)
	var font := load("res://assets/fonts/Orbitron-Bold.ttf")
	if font:
		lbl.add_theme_font_override("font", font)
	add_child(lbl)

	lbl.modulate.a = 0.0
	lbl.scale = Vector2(0.3, 0.3)
	lbl.pivot_offset = Vector2(150, 16)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "modulate:a", 1.0, 0.2)
	tw.tween_property(lbl, "scale", Vector2(1.2, 1.2), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.chain().tween_property(lbl, "scale", Vector2.ONE, 0.15)

	var pulse := create_tween().set_loops()
	pulse.tween_property(lbl, "theme_override_colors/font_color", Color(1, 1, 0.4), 0.5).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(lbl, "theme_override_colors/font_color", Color(1, 0.7, 0), 0.5).set_trans(Tween.TRANS_SINE)


func _spawn_embers() -> void:
	var host := Node2D.new()
	add_child(host)

	var embers := CPUParticles2D.new()
	embers.position = Vector2(375, 1400)
	embers.amount = 30
	embers.lifetime = 6.0
	embers.speed_scale = 0.6
	embers.randomness = 1.0
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	embers.emission_rect_extents = Vector2(400, 50)
	embers.direction = Vector2(0, -1)
	embers.spread = 30.0
	embers.initial_velocity_min = 30.0
	embers.initial_velocity_max = 80.0
	embers.gravity = Vector2(0, -5)
	embers.scale_amount_min = 1.5
	embers.scale_amount_max = 4.0
	embers.color = Color(1, 0.3, 0.05, 0.4)
	host.add_child(embers)

	var ash := CPUParticles2D.new()
	ash.position = Vector2(375, 667)
	ash.amount = 15
	ash.lifetime = 8.0
	ash.speed_scale = 0.3
	ash.randomness = 1.0
	ash.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	ash.emission_rect_extents = Vector2(380, 680)
	ash.direction = Vector2(0.5, -1)
	ash.spread = 180.0
	ash.initial_velocity_min = 5.0
	ash.initial_velocity_max = 20.0
	ash.gravity = Vector2(0, 3)
	ash.scale_amount_min = 1.0
	ash.scale_amount_max = 2.5
	ash.color = Color(1, 0.5, 0.2, 0.15)
	host.add_child(ash)


func _spawn_record_burst() -> void:
	var host := Node2D.new()
	add_child(host)
	for i in 3:
		var p := CPUParticles2D.new()
		p.position = Vector2(375, 500)
		p.emitting = true
		p.one_shot = true
		p.amount = 40
		p.lifetime = 1.2
		p.explosiveness = 0.9
		p.direction = Vector2(0, -1)
		p.spread = 180.0
		p.initial_velocity_min = 100.0
		p.initial_velocity_max = 350.0
		p.gravity = Vector2(0, 200)
		p.scale_amount_min = 2.0
		p.scale_amount_max = 5.0
		var colors := [Color(1, 0.85, 0, 0.9), Color(0, 1, 1, 0.9), Color(1, 0.3, 0.8, 0.9)]
		p.color = colors[i]
		host.add_child(p)
		if i < 2:
			await get_tree().create_timer(0.2).timeout


func _count_up(label: Label, target: int, duration: float) -> void:
	var tw := create_tween()
	tw.tween_method(func(v: float):
		label.text = str(int(v))
	, 0.0, float(target), duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	label.pivot_offset = label.size / 2.0
	var tw2 := create_tween()
	tw2.tween_property(label, "scale", Vector2(1.15, 1.15), duration * 0.5).set_ease(Tween.EASE_OUT)
	tw2.tween_property(label, "scale", Vector2.ONE, duration * 0.5).set_ease(Tween.EASE_IN_OUT)


func _on_retry_pressed() -> void:
	SoundManager.play_sfx("res://assets/sounds/button.mp3")
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "scale", Vector2(0.7, 0.7), 0.15)
	tw.tween_property(panel, "modulate:a", 0.0, 0.15)
	tw.tween_property(dim, "modulate:a", 0.0, 0.2)
	tw.chain().tween_callback(func():
		queue_free()
		var game_node := get_tree().current_scene
		if game_node.has_method("restart"):
			game_node.restart()
	)


func _on_menu_pressed() -> void:
	SoundManager.play_sfx("res://assets/sounds/button.mp3")
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "scale", Vector2(0.7, 0.7), 0.15)
	tw.tween_property(panel, "modulate:a", 0.0, 0.15)
	tw.tween_property(dim, "modulate:a", 0.0, 0.2)
	tw.chain().tween_callback(func():
		queue_free()
		GameManager.change_scene("res://scenes/main_menu/main_menu.tscn")
	)
