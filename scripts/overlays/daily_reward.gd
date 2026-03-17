extends CanvasLayer

const REWARDS := [
	{"coins": 20, "crystals": 0, "pu": "", "desc": "20 coins"},
	{"coins": 30, "crystals": 0, "pu": "", "desc": "30 coins"},
	{"coins": 0, "crystals": 0, "pu": "shield", "desc": "Shield x1"},
	{"coins": 50, "crystals": 0, "pu": "", "desc": "50 coins"},
	{"coins": 0, "crystals": 1, "pu": "", "desc": "1 crystal"},
	{"coins": 0, "crystals": 0, "pu": "slowdown|widen", "desc": "Slowdown + Widener"},
	{"coins": 100, "crystals": 3, "pu": "", "desc": "100 coins + 3 crystals"},
]

@onready var panel: PanelContainer = $Panel
@onready var day_label: Label = $Panel/VBox/DayLabel
@onready var reward_label: Label = $Panel/VBox/RewardLabel
@onready var claim_btn: Button = $Panel/VBox/ClaimBtn
@onready var dim: ColorRect = $Dim
@onready var title_label: Label = $Panel/VBox/Title


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	UIStyle.neon_panel(panel)
	UIStyle.neon_button(claim_btn)

	UIStyle.overlay_particles(self, Color(1, 0.85, 0, 0.15))

	var day := GameManager.login_streak % 7
	day_label.text = "DAY %d / 7" % (day + 1)
	reward_label.text = REWARDS[day].desc

	dim.modulate.a = 0.0
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.3, 0.3)
	panel.pivot_offset = panel.size / 2.0

	for node in [title_label, day_label, reward_label, claim_btn]:
		node.modulate.a = 0.0

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(dim, "modulate:a", 1.0, 0.3)
	tw.tween_property(panel, "modulate:a", 1.0, 0.35).set_delay(0.1)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.5).set_delay(0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	await get_tree().create_timer(0.35).timeout

	title_label.pivot_offset = title_label.size / 2.0
	title_label.scale = Vector2(0.3, 0.3)
	var tw_t := create_tween()
	tw_t.set_parallel(true)
	tw_t.tween_property(title_label, "modulate:a", 1.0, 0.2)
	tw_t.tween_property(title_label, "scale", Vector2.ONE, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	await get_tree().create_timer(0.2).timeout
	var tw_d := create_tween()
	tw_d.tween_property(day_label, "modulate:a", 1.0, 0.2)

	await get_tree().create_timer(0.15).timeout

	reward_label.pivot_offset = reward_label.size / 2.0
	reward_label.scale = Vector2(0.5, 0.5)
	var tw_r := create_tween()
	tw_r.set_parallel(true)
	tw_r.tween_property(reward_label, "modulate:a", 1.0, 0.2)
	tw_r.tween_property(reward_label, "scale", Vector2(1.15, 1.15), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw_r.chain().tween_property(reward_label, "scale", Vector2.ONE, 0.15)

	await get_tree().create_timer(0.2).timeout

	claim_btn.position.y += 20
	var orig_y: float = claim_btn.position.y - 20
	var tw_btn := create_tween()
	tw_btn.set_parallel(true)
	tw_btn.tween_property(claim_btn, "modulate:a", 1.0, 0.2)
	tw_btn.tween_property(claim_btn, "position:y", orig_y, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	_start_glow()
	_pulse_reward()


func _start_glow() -> void:
	var tw := create_tween().set_loops()
	tw.tween_property(title_label, "theme_override_colors/font_color", Color(1, 1, 0.3, 1), 0.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(title_label, "theme_override_colors/font_color", Color(1, 0.7, 0, 1), 0.8).set_trans(Tween.TRANS_SINE)


func _pulse_reward() -> void:
	reward_label.pivot_offset = reward_label.size / 2.0
	var tw := create_tween().set_loops()
	tw.tween_property(reward_label, "scale", Vector2(1.05, 1.05), 0.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(reward_label, "scale", Vector2.ONE, 0.8).set_trans(Tween.TRANS_SINE)


func _on_claim_pressed() -> void:
	SoundManager.play_sfx("res://assets/sounds/coin.mp3")
	var day := GameManager.login_streak % 7
	var reward: Dictionary = REWARDS[day]

	if reward.coins > 0:
		GameManager.add_coins(reward.coins)
	if reward.crystals > 0:
		GameManager.add_crystals(reward.crystals)
	if reward.pu != "":
		for pu_id in reward.pu.split("|"):
			GameManager.add_power_up(pu_id)

	GameManager.login_streak += 1
	GameManager.last_reward_date = GameManager.get_today_str()
	GameManager.save_game()

	_claim_celebration()

	claim_btn.disabled = true
	var tw := create_tween()
	tw.tween_property(panel, "scale", Vector2(1.2, 1.2), 0.12).set_trans(Tween.TRANS_BACK)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.1)
	tw.tween_interval(0.15)
	var tw2 := create_tween()
	tw2.set_parallel(true)
	tw2.tween_property(dim, "modulate:a", 0.0, 0.2).set_delay(0.2)
	tw2.tween_property(panel, "modulate:a", 0.0, 0.2).set_delay(0.2)
	tw2.tween_property(panel, "scale", Vector2(0.6, 0.6), 0.2).set_delay(0.2)
	tw2.chain().tween_callback(queue_free)


func _claim_celebration() -> void:
	var host := Node2D.new()
	add_child(host)

	var colors := [
		Color(1, 0.85, 0, 0.9),
		Color(0, 1, 1, 0.9),
		Color(1, 0.4, 0.8, 0.9),
		Color(0.4, 1, 0.4, 0.9),
	]
	for i in 4:
		var p := CPUParticles2D.new()
		p.position = Vector2(375, 667)
		p.emitting = true
		p.one_shot = true
		p.amount = 30
		p.lifetime = 1.2
		p.explosiveness = 0.95
		p.direction = Vector2(0, -1)
		p.spread = 180.0
		p.initial_velocity_min = 150.0
		p.initial_velocity_max = 450.0
		p.gravity = Vector2(0, 300)
		p.scale_amount_min = 2.0
		p.scale_amount_max = 5.0
		p.color = colors[i]
		host.add_child(p)

	var sparkle := CPUParticles2D.new()
	sparkle.position = Vector2(375, 667)
	sparkle.emitting = true
	sparkle.one_shot = true
	sparkle.amount = 25
	sparkle.lifetime = 1.5
	sparkle.explosiveness = 0.5
	sparkle.direction = Vector2(0, 0)
	sparkle.spread = 180.0
	sparkle.initial_velocity_min = 50.0
	sparkle.initial_velocity_max = 120.0
	sparkle.gravity = Vector2(0, -10)
	sparkle.scale_amount_min = 1.0
	sparkle.scale_amount_max = 3.0
	sparkle.color = Color(1, 1, 1, 0.5)
	sparkle.damping_min = 50.0
	sparkle.damping_max = 100.0
	host.add_child(sparkle)


static func should_show() -> bool:
	var today := GameManager.get_today_str()
	if GameManager.last_reward_date == today:
		return false
	var last := GameManager.last_login_date
	GameManager.last_login_date = today
	if last != "" and last != today:
		var last_dt := Time.get_datetime_dict_from_datetime_string(last + "T00:00:00", false)
		var today_dt := Time.get_datetime_dict_from_datetime_string(today + "T00:00:00", false)
		var last_unix := Time.get_unix_time_from_datetime_dict(last_dt)
		var today_unix := Time.get_unix_time_from_datetime_dict(today_dt)
		var diff_days := int((today_unix - last_unix) / 86400.0)
		if diff_days > 1:
			GameManager.login_streak = 0
	GameManager.save_game()
	return true
