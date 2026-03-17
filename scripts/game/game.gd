extends Node2D

const BLOCK_HEIGHT := 40.0
const START_WIDTH := 300.0
const MIN_WIDTH := 15.0
const PERFECT_THRESHOLD := 8.0
const BASE_SPEED := 250.0
const VIEWPORT_W := 750.0
const BASE_Y := 1100.0

var score := 0
var combo := 0
var coins_earned := 0
var current_speed := BASE_SPEED
var direction := 1.0
var playing := false
var current_block: Panel
var previous_block: Panel
var tower_blocks: Array[Panel] = []

var current_zone_index := 0
var shield_active := false
var magnet_charges := 0
var slowdown_active := false
var x2_active := false
var active_pu_slots: Array[String] = []
var extra_lives := 0

var _glitch_block: Panel
var _invisible_block: Panel
var _speed_burst_timer := 0.0
var _zone_label: Label

var _block_type := "normal"
var _glass_blocks: Array[Dictionary] = []

var _laser: ColorRect
var _laser_dir := 1.0
var _laser_speed := 300.0
var _laser_active := false

@onready var tower: Node2D = $Tower
@onready var cam: Camera2D = $GameCamera
@onready var score_label: Label = $HUD/ScoreLabel
@onready var combo_label: Label = $HUD/ComboLabel
@onready var pause_btn: Button = $HUD/TopPanel/HBox/PauseBtn
@onready var coin_display: Label = $HUD/TopPanel/HBox/CoinDisplay
@onready var particles_node: Node2D = $Particles
@onready var top_panel: PanelContainer = $HUD/TopPanel
@onready var zone_name_label: Label = $HUD/ZoneLabel
@onready var pu_btn_left: Button = $HUD/PowerUpLeft
@onready var pu_btn_right: Button = $HUD/PowerUpRight


func _ready() -> void:
	Engine.time_scale = 1.0
	_style_hud()
	_setup_power_ups()
	_start_game()


func _style_hud() -> void:
	UIStyle.small_neon_button(pause_btn)
	var safe_top := GameManager.get_safe_top()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.01, 0.005, 0.03, 0.35)
	style.shadow_color = Color(0, 1, 1, 0.03)
	style.shadow_size = 2
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = maxf(safe_top, 10.0)
	style.content_margin_bottom = 10
	top_panel.add_theme_stylebox_override("panel", style)


func _setup_power_ups() -> void:
	active_pu_slots = []
	shield_active = false
	magnet_charges = 0
	slowdown_active = false
	x2_active = false
	extra_lives = 0

	for pu_id in GameManager.selected_power_ups:
		var data: Dictionary = PowerUpData.info(pu_id)
		if data.is_empty():
			continue
		if data.type == "auto" and pu_id == "shield":
			shield_active = true
			GameManager.consume_power_up(pu_id)
		elif data.type == "passive" and pu_id == "x2coins":
			x2_active = true
			GameManager.consume_power_up(pu_id)
		elif data.type == "manual":
			active_pu_slots.append(pu_id)
			GameManager.consume_power_up(pu_id)

	_update_pu_buttons()


func _update_pu_buttons() -> void:
	if active_pu_slots.size() > 0 and active_pu_slots[0] != "":
		var data: Dictionary = PowerUpData.info(active_pu_slots[0])
		pu_btn_left.text = ""
		pu_btn_left.icon = load(data.icon_path)
		pu_btn_left.expand_icon = true
		pu_btn_left.visible = true
	else:
		pu_btn_left.visible = false

	if active_pu_slots.size() > 1 and active_pu_slots[1] != "":
		var data: Dictionary = PowerUpData.info(active_pu_slots[1])
		pu_btn_right.text = ""
		pu_btn_right.icon = load(data.icon_path)
		pu_btn_right.expand_icon = true
		pu_btn_right.visible = true
	else:
		pu_btn_right.visible = false


func _vibrate() -> void:
	if GameManager.settings.vibration:
		Input.vibrate_handheld(30)


func _vibrate_strong() -> void:
	if GameManager.settings.vibration:
		Input.vibrate_handheld(60)


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _start_game() -> void:
	score = 0
	combo = 0
	coins_earned = 0
	current_speed = BASE_SPEED
	current_zone_index = 0
	playing = true
	if not GameManager.tutorial_seen:
		_show_tutorial()
	extra_lives = 0
	_glass_blocks.clear()
	_laser_active = false
	_clear_tower()
	_spawn_base()
	_spawn_moving_block()
	_update_hud()
	_show_zone_name(0)
	cam.reset_to(BASE_Y)


func _clear_tower() -> void:
	for child in tower.get_children():
		child.queue_free()
	tower_blocks.clear()
	for child in particles_node.get_children():
		child.queue_free()
	if _laser:
		_laser.queue_free()
		_laser = null


func _get_skin() -> Dictionary:
	return GameManager.get_skin_data(GameManager.selected_skin)


func _make_style(override_color := Color.TRANSPARENT) -> StyleBoxFlat:
	var skin: Dictionary = _get_skin()
	var zone: Dictionary = ZoneManager.get_zone(score)
	var style := StyleBoxFlat.new()
	var fill_color: Color = skin.fill if override_color == Color.TRANSPARENT else override_color
	fill_color = fill_color.lerp(zone.tint, 0.3)
	style.bg_color = fill_color
	style.border_color = skin.outline
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style


func _create_block(x: float, y: float, w: float, block_style: StyleBoxFlat = null) -> Panel:
	var block := Panel.new()
	block.add_theme_stylebox_override("panel", block_style if block_style else _make_style())
	block.size = Vector2(w, BLOCK_HEIGHT)
	block.position = Vector2(x, y)
	block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tower.add_child(block)
	return block


func _spawn_base() -> void:
	var x := (VIEWPORT_W - START_WIDTH) / 2.0
	var base := _create_block(x, BASE_Y, START_WIDTH)
	previous_block = base
	tower_blocks.append(base)


func _roll_block_type() -> String:
	if score < 10:
		return "normal"
	var roll := randf()
	if roll < 0.08:
		return "golden"
	elif roll < 0.14:
		return "glass"
	elif roll < 0.19:
		return "magnetic"
	return "normal"


func _make_block_style_for_type(btype: String) -> StyleBoxFlat:
	match btype:
		"golden":
			var s := _make_style(Color(1, 0.85, 0.1))
			s.border_color = Color(1, 0.7, 0, 1)
			s.shadow_color = Color(1, 0.85, 0, 0.4)
			s.shadow_size = 8
			return s
		"glass":
			var skin: Dictionary = _get_skin()
			var s := _make_style(Color(0.7, 0.85, 1.0, 0.4))
			s.border_color = Color(0.8, 0.9, 1, 0.7)
			s.bg_color = Color(skin.fill.r, skin.fill.g, skin.fill.b, 0.35)
			return s
		"magnetic":
			var s := _make_style(Color(0.2, 0.5, 1.0))
			s.border_color = Color(0.3, 0.6, 1, 1)
			s.shadow_color = Color(0.3, 0.5, 1, 0.35)
			s.shadow_size = 6
			return s
	return _make_style()


func _spawn_moving_block() -> void:
	var w := previous_block.size.x
	var y := previous_block.position.y - BLOCK_HEIGHT
	var start_x := -w if direction > 0 else VIEWPORT_W

	_block_type = _roll_block_type()
	var style := _make_block_style_for_type(_block_type)
	current_block = _create_block(start_x, y, w, style)
	cam.target_y = y + BLOCK_HEIGHT / 2.0

	if _block_type == "magnetic":
		_magnetic_indicator(current_block)

	_apply_special_effects()
	_maybe_spawn_laser()
	_update_glass_blocks()


func _magnetic_indicator(block: Panel) -> void:
	var p := CPUParticles2D.new()
	p.position = Vector2(block.size.x / 2.0, BLOCK_HEIGHT / 2.0)
	p.amount = 6
	p.lifetime = 1.0
	p.speed_scale = 0.8
	p.randomness = 0.5
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(block.size.x / 2.0, 5)
	p.direction = Vector2(0, -1)
	p.spread = 60.0
	p.initial_velocity_min = 15.0
	p.initial_velocity_max = 40.0
	p.gravity = Vector2(0, 0)
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.0
	p.color = Color(0.3, 0.5, 1, 0.5)
	block.add_child(p)


func _apply_special_effects() -> void:
	var special := ZoneManager.get_special(score)
	_glitch_block = null
	_invisible_block = null

	if special == "glitch":
		_glitch_block = current_block
	elif special == "invisible":
		_invisible_block = current_block
		current_block.modulate.a = 0.0
	elif special == "speed_burst":
		if randf() < 0.3:
			_speed_burst_timer = 2.0


func _maybe_spawn_laser() -> void:
	if score < 30:
		_laser_active = false
		return
	if score % 5 != 0:
		_laser_active = false
		if _laser:
			_laser.visible = false
		return

	_laser_active = true
	if not _laser:
		_laser = ColorRect.new()
		_laser.size = Vector2(VIEWPORT_W, 4)
		_laser.color = Color(1, 0.1, 0.1, 0.8)
		_laser.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tower.add_child(_laser)

	_laser.visible = true
	_laser.position = Vector2(0, current_block.position.y + BLOCK_HEIGHT / 2.0)
	_laser_dir = 1.0


func _update_glass_blocks() -> void:
	var to_remove: Array[int] = []
	for i in range(_glass_blocks.size() - 1, -1, -1):
		_glass_blocks[i].age += 1
		if _glass_blocks[i].age >= 3:
			var block: Panel = _glass_blocks[i].block
			if is_instance_valid(block):
				_glass_break_effect(block)
				var old_w := block.size.x
				var shrink := old_w * 0.35
				block.size.x = maxf(old_w - shrink, MIN_WIDTH)
				block.position.x += shrink / 2.0
			to_remove.append(i)
	for i in to_remove:
		_glass_blocks.remove_at(i)


func _glass_break_effect(block: Panel) -> void:
	var cx := block.position.x + block.size.x / 2.0
	var p := CPUParticles2D.new()
	p.position = Vector2(cx, block.position.y + BLOCK_HEIGHT / 2.0)
	p.emitting = true
	p.one_shot = true
	p.amount = 15
	p.lifetime = 0.6
	p.explosiveness = 0.9
	p.direction = Vector2(0, 1)
	p.spread = 120.0
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 120.0
	p.gravity = Vector2(0, 300)
	p.scale_amount_min = 1.0
	p.scale_amount_max = 3.0
	p.color = Color(0.7, 0.9, 1, 0.7)
	particles_node.add_child(p)
	create_tween().bind_node(p).tween_interval(1.5).finished.connect(p.queue_free)

	cam.shake(5.0)
	var tw := create_tween().bind_node(block)
	tw.tween_property(block, "modulate", Color(1, 0.5, 0.5, 0.7), 0.1)
	tw.tween_property(block, "modulate", Color.WHITE, 0.2)


func _process(delta: float) -> void:
	if not playing or not current_block:
		return

	var speed := current_speed
	if slowdown_active:
		speed *= 0.4
	if _speed_burst_timer > 0:
		speed *= 1.3
		_speed_burst_timer -= delta

	current_block.position.x += speed * direction * delta
	if direction > 0 and current_block.position.x > VIEWPORT_W:
		direction = -1.0
	elif direction < 0 and current_block.position.x + current_block.size.x < 0:
		direction = 1.0

	if _glitch_block:
		_glitch_block.position.x += randf_range(-1.5, 1.5)

	if _invisible_block and _invisible_block == current_block:
		var dist := absf(current_block.position.x - previous_block.position.x)
		var max_dist := VIEWPORT_W * 0.5
		current_block.modulate.a = clampf(1.0 - dist / max_dist, 0.05, 1.0)

	if _laser_active and _laser and _laser.visible:
		_laser.position.x += _laser_speed * _laser_dir * delta
		if _laser.position.x > VIEWPORT_W * 0.3:
			_laser_dir = -1.0
		elif _laser.position.x < -VIEWPORT_W * 0.3:
			_laser_dir = 1.0
		_laser.modulate.a = 0.5 + sin(Time.get_ticks_msec() * 0.01) * 0.5


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("tap") and playing:
		_place_block()


func _place_block() -> void:
	if not current_block or not previous_block:
		return

	if _block_type == "magnetic" or magnet_charges > 0:
		if _block_type == "magnetic":
			pass
		else:
			magnet_charges -= 1
		current_block.position.x = previous_block.position.x
		current_block.size.x = previous_block.size.x
		combo += 1
		_perfect_effect(current_block)
		_place_dust(current_block)
		SoundManager.play_sfx("res://assets/sounds/perfect.mp3")
		cam.shake(3.0)
		_vibrate()
		_after_place(true)
		return

	var cur_left := current_block.position.x
	var cur_right := cur_left + current_block.size.x
	var prev_left := previous_block.position.x
	var prev_right := prev_left + previous_block.size.x

	var overlap_left := maxf(cur_left, prev_left)
	var overlap_right := minf(cur_right, prev_right)
	var overlap := overlap_right - overlap_left

	if overlap <= 0:
		if shield_active:
			shield_active = false
			_shield_effect()
			current_block.position.x = previous_block.position.x
			current_block.size.x = previous_block.size.x
			_after_place(false)
			return
		if extra_lives > 0:
			extra_lives -= 1
			_extra_life_effect()
			current_block.position.x = previous_block.position.x
			current_block.size.x = previous_block.size.x
			_after_place(false)
			return
		_game_over()
		return

	var shift := absf(cur_left - prev_left)

	if shift < PERFECT_THRESHOLD:
		combo += 1
		current_block.position.x = previous_block.position.x
		current_block.size.x = previous_block.size.x
		_perfect_effect(current_block)
		if combo > 1:
			SoundManager.play_sfx("res://assets/sounds/combo.mp3")
		else:
			SoundManager.play_sfx("res://assets/sounds/perfect.mp3")
		GameManager.total_perfects += 1
	else:
		combo = 0
		if overlap < MIN_WIDTH:
			if shield_active:
				shield_active = false
				_shield_effect()
				current_block.position.x = previous_block.position.x
				current_block.size.x = previous_block.size.x
				_after_place(false)
				return
			if extra_lives > 0:
				extra_lives -= 1
				_extra_life_effect()
				current_block.position.x = previous_block.position.x
				current_block.size.x = previous_block.size.x
				_after_place(false)
				return
			_game_over()
			return
		var cut_width := current_block.size.x - overlap
		_spawn_falling_piece(current_block, overlap_left, overlap_right, cur_left, cur_right, cut_width)
		current_block.position.x = overlap_left
		current_block.size.x = overlap
		SoundManager.play_sfx("res://assets/sounds/place.mp3")

	if _laser_active and _laser and _laser.visible:
		var laser_cx := _laser.position.x + VIEWPORT_W / 2.0
		var block_left := current_block.position.x
		var block_right := block_left + current_block.size.x
		if laser_cx > block_left and laser_cx < block_right:
			var penalty := current_block.size.x * 0.2
			current_block.size.x = maxf(current_block.size.x - penalty, MIN_WIDTH)
			current_block.position.x += penalty / 2.0
			_laser_hit_effect()

	cam.shake(3.0)
	_vibrate()
	_place_dust(current_block)
	_after_place(shift < PERFECT_THRESHOLD)


func _after_place(is_perfect: bool) -> void:
	var coin_mult := 1
	if _block_type == "golden":
		coin_mult = 3
		_golden_collect_effect(current_block)

	score += 1 + combo
	coins_earned += coin_mult
	current_speed = minf(current_speed + ZoneManager.get_speed_increment(score), ZoneManager.MAX_SPEED)

	if combo > GameManager.max_combo:
		GameManager.max_combo = combo

	_check_streak_rewards()

	if combo >= 5:
		var strength := minf(0.04 + combo * 0.008, 0.15)
		cam.zoom_pulse(strength, 0.35)

	if _block_type == "glass":
		_glass_blocks.append({"block": current_block, "age": 0})

	var new_zone := ZoneManager.get_zone_index(score)
	if new_zone != current_zone_index:
		current_zone_index = new_zone
		_show_zone_name(new_zone)
		GameManager.zone_reached.emit(new_zone)
		if new_zone >= 2:
			GameManager.add_crystals(1)

	GameManager.block_placed.emit(score, combo, is_perfect)

	previous_block = current_block
	tower_blocks.append(current_block)
	direction *= -1.0
	_update_hud()
	_spawn_moving_block()


func _check_streak_rewards() -> void:
	if combo == 5:
		coins_earned += 5
		_streak_label("x3 BONUS!", Color(1, 0.85, 0))
		SoundManager.play_sfx("res://assets/sounds/streak.mp3")
		_vibrate()
	elif combo == 10:
		extra_lives += 1
		_streak_label("EXTRA LIFE!", Color(0, 1, 0.5))
		SoundManager.play_sfx("res://assets/sounds/streak.mp3")
		_vibrate_strong()
	elif combo == 15:
		coins_earned += 15
		_streak_label("x5 MEGA!", Color(1, 0.4, 0.8))
		SoundManager.play_sfx("res://assets/sounds/streak.mp3")
		_vibrate()
	elif combo == 20:
		extra_lives += 1
		coins_earned += 20
		_streak_label("UNSTOPPABLE!", Color(1, 0.2, 0.2))
		SoundManager.play_sfx("res://assets/sounds/streak.mp3")
		_vibrate_strong()


func _streak_label(text: String, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = Vector2(VIEWPORT_W / 2.0 - 80, current_block.position.y - 100)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 36)
	var font := load("res://assets/fonts/Orbitron-Bold.ttf")
	if font:
		lbl.add_theme_font_override("font", font)
	particles_node.add_child(lbl)

	lbl.scale = Vector2(0.3, 0.3)
	lbl.modulate.a = 0.0
	var tw := create_tween().bind_node(lbl)
	tw.set_parallel(true)
	tw.tween_property(lbl, "scale", Vector2(1.2, 1.2), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(lbl, "modulate:a", 1.0, 0.15)
	tw.chain().tween_property(lbl, "scale", Vector2.ONE, 0.15)
	tw.chain().tween_property(lbl, "position:y", lbl.position.y - 80, 0.8)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.6).set_delay(0.5)
	tw.chain().tween_callback(lbl.queue_free)

	var cx := current_block.position.x + current_block.size.x / 2.0
	var burst := CPUParticles2D.new()
	burst.position = Vector2(cx, current_block.position.y - 40)
	burst.emitting = true
	burst.one_shot = true
	burst.amount = 35
	burst.lifetime = 0.8
	burst.explosiveness = 1.0
	burst.direction = Vector2(0, -1)
	burst.spread = 180.0
	burst.initial_velocity_min = 150.0
	burst.initial_velocity_max = 350.0
	burst.gravity = Vector2(0, 200)
	burst.scale_amount_min = 2.0
	burst.scale_amount_max = 5.0
	burst.color = color
	particles_node.add_child(burst)
	create_tween().bind_node(burst).tween_interval(1.5).finished.connect(burst.queue_free)


func _golden_collect_effect(block: Panel) -> void:
	var cx := block.position.x + block.size.x / 2.0
	var p := CPUParticles2D.new()
	p.position = Vector2(cx, block.position.y)
	p.emitting = true
	p.one_shot = true
	p.amount = 25
	p.lifetime = 0.8
	p.explosiveness = 0.9
	p.direction = Vector2(0, -1)
	p.spread = 100.0
	p.initial_velocity_min = 80.0
	p.initial_velocity_max = 220.0
	p.gravity = Vector2(0, 250)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 5.0
	p.color = Color(1, 0.85, 0, 0.9)
	particles_node.add_child(p)
	create_tween().bind_node(p).tween_interval(1.5).finished.connect(p.queue_free)

	var lbl := Label.new()
	lbl.text = "x3 GOLD!"
	lbl.position = Vector2(cx - 50, block.position.y - 40)
	lbl.add_theme_color_override("font_color", Color(1, 0.85, 0))
	lbl.add_theme_font_size_override("font_size", 24)
	particles_node.add_child(lbl)
	var tw := create_tween().bind_node(lbl)
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - 60, 0.5)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.5).set_delay(0.3)
	tw.chain().tween_callback(lbl.queue_free)


func _extra_life_effect() -> void:
	var lbl := Label.new()
	lbl.text = "SAVED!"
	lbl.position = Vector2(VIEWPORT_W / 2.0 - 50, current_block.position.y - 50)
	lbl.add_theme_color_override("font_color", Color(0, 1, 0.5))
	lbl.add_theme_font_size_override("font_size", 32)
	particles_node.add_child(lbl)
	var tw := create_tween().bind_node(lbl)
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - 80, 0.6)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.6).set_delay(0.3)
	tw.chain().tween_callback(lbl.queue_free)
	cam.shake(8.0)


func _laser_hit_effect() -> void:
	cam.shake(6.0)
	var p := CPUParticles2D.new()
	p.position = Vector2(_laser.position.x + VIEWPORT_W / 2.0, current_block.position.y + BLOCK_HEIGHT / 2.0)
	p.emitting = true
	p.one_shot = true
	p.amount = 15
	p.lifetime = 0.4
	p.explosiveness = 1.0
	p.direction = Vector2(0, 0)
	p.spread = 180.0
	p.initial_velocity_min = 80.0
	p.initial_velocity_max = 180.0
	p.gravity = Vector2(0, 0)
	p.scale_amount_min = 1.5
	p.scale_amount_max = 4.0
	p.color = Color(1, 0.1, 0.1, 0.8)
	p.damping_min = 200.0
	p.damping_max = 300.0
	particles_node.add_child(p)
	create_tween().bind_node(p).tween_interval(1.0).finished.connect(p.queue_free)


func _show_zone_name(zone_idx: int) -> void:
	var zone: Dictionary = ZoneManager.ZONES[zone_idx]
	zone_name_label.text = zone.name
	zone_name_label.modulate.a = 0.0
	zone_name_label.scale = Vector2(1.5, 1.5)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(zone_name_label, "modulate:a", 1.0, 0.3)
	tw.tween_property(zone_name_label, "scale", Vector2.ONE, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.chain().tween_interval(1.5)
	tw.chain().tween_property(zone_name_label, "modulate:a", 0.0, 0.5)


func _shield_effect() -> void:
	var lbl := Label.new()
	lbl.text = "SHIELD!"
	lbl.position = Vector2(VIEWPORT_W / 2.0 - 50, current_block.position.y - 50)
	lbl.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	lbl.add_theme_font_size_override("font_size", 32)
	particles_node.add_child(lbl)
	var tw := create_tween().bind_node(lbl)
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - 80, 0.6)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.6).set_delay(0.3)
	tw.chain().tween_callback(lbl.queue_free)


func _spawn_falling_piece(block: Panel, ol: float, or_: float, cl: float, _cr: float, cut_w: float) -> void:
	var fall_x := cl if cl < ol else or_
	var piece := _create_block(fall_x, block.position.y, cut_w)
	var tw := create_tween().bind_node(piece)
	tw.set_parallel(true)
	tw.tween_property(piece, "position:y", piece.position.y + 600, 0.8).set_ease(Tween.EASE_IN)
	tw.tween_property(piece, "rotation", randf_range(-1.5, 1.5), 0.8)
	tw.tween_property(piece, "modulate:a", 0.0, 0.6).set_delay(0.2)
	tw.chain().tween_callback(piece.queue_free)
	_slice_sparks(Vector2(ol if cl < ol else or_, block.position.y))
	SoundManager.play_sfx("res://assets/sounds/slice.mp3")


func _slice_sparks(pos: Vector2) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.emitting = true
	p.one_shot = true
	p.amount = 12
	p.lifetime = 0.5
	p.explosiveness = 0.9
	p.direction = Vector2(0, -1)
	p.spread = 120.0
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 150.0
	p.gravity = Vector2(0, 400)
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.0
	p.color = Color(1, 0.6, 0.1, 0.9)
	particles_node.add_child(p)
	create_tween().bind_node(p).tween_interval(1.0).finished.connect(p.queue_free)


func _place_dust(block: Panel) -> void:
	var skin: Dictionary = _get_skin()
	var cx := block.position.x + block.size.x / 2.0
	var p := CPUParticles2D.new()
	p.position = Vector2(cx, block.position.y + BLOCK_HEIGHT)
	p.emitting = true
	p.one_shot = true
	p.amount = 8
	p.lifetime = 0.4
	p.explosiveness = 0.8
	p.direction = Vector2(0, 1)
	p.spread = 80.0
	p.initial_velocity_min = 20.0
	p.initial_velocity_max = 60.0
	p.gravity = Vector2(0, 100)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 5.0
	p.color = Color(skin.fill.r, skin.fill.g, skin.fill.b, 0.3)
	particles_node.add_child(p)
	create_tween().bind_node(p).tween_interval(1.0).finished.connect(p.queue_free)


func _perfect_effect(block: Panel) -> void:
	var skin: Dictionary = _get_skin()
	var cx := block.position.x + block.size.x / 2.0

	var burst := CPUParticles2D.new()
	burst.position = Vector2(cx, block.position.y)
	burst.emitting = true
	burst.one_shot = true
	burst.amount = 30
	burst.lifetime = 0.7
	burst.explosiveness = 1.0
	burst.direction = Vector2(0, -1)
	burst.spread = 80.0
	burst.initial_velocity_min = 120.0
	burst.initial_velocity_max = 280.0
	burst.gravity = Vector2(0, 350)
	burst.scale_amount_min = 2.0
	burst.scale_amount_max = 5.0
	burst.color = skin.outline
	particles_node.add_child(burst)
	create_tween().bind_node(burst).tween_interval(1.5).finished.connect(burst.queue_free)

	var shimmer := CPUParticles2D.new()
	shimmer.position = Vector2(cx, block.position.y)
	shimmer.emitting = true
	shimmer.one_shot = true
	shimmer.amount = 16
	shimmer.lifetime = 0.9
	shimmer.explosiveness = 0.7
	shimmer.direction = Vector2(0, 0)
	shimmer.spread = 180.0
	shimmer.initial_velocity_min = 30.0
	shimmer.initial_velocity_max = 80.0
	shimmer.gravity = Vector2(0, -20)
	shimmer.scale_amount_min = 1.0
	shimmer.scale_amount_max = 3.0
	shimmer.color = Color(1, 1, 1, 0.6)
	particles_node.add_child(shimmer)
	create_tween().bind_node(shimmer).tween_interval(1.5).finished.connect(shimmer.queue_free)

	if combo >= 3:
		var ring := CPUParticles2D.new()
		ring.position = Vector2(cx, block.position.y + BLOCK_HEIGHT / 2.0)
		ring.emitting = true
		ring.one_shot = true
		ring.amount = 40
		ring.lifetime = 0.5
		ring.explosiveness = 1.0
		ring.direction = Vector2(0, 0)
		ring.spread = 180.0
		ring.initial_velocity_min = 200.0
		ring.initial_velocity_max = 350.0
		ring.gravity = Vector2(0, 0)
		ring.scale_amount_min = 1.0
		ring.scale_amount_max = 2.5
		ring.color = Color(skin.outline.r, skin.outline.g, skin.outline.b, 0.8)
		ring.damping_min = 300.0
		ring.damping_max = 500.0
		particles_node.add_child(ring)
		create_tween().bind_node(ring).tween_interval(1.0).finished.connect(ring.queue_free)

	if combo > 1:
		var lbl := Label.new()
		lbl.text = "x%d COMBO!" % combo if combo < 5 else "x%d PERFECT!" % combo
		lbl.position = Vector2(cx - 60, block.position.y - 50)
		lbl.add_theme_color_override("font_color", skin.outline)
		lbl.add_theme_font_size_override("font_size", 28 + mini(combo, 8) * 2)
		particles_node.add_child(lbl)
		var tw2 := create_tween().bind_node(lbl)
		tw2.set_parallel(true)
		tw2.tween_property(lbl, "position:y", lbl.position.y - 80, 0.6)
		tw2.tween_property(lbl, "scale", Vector2(1.3, 1.3), 0.15).set_ease(Tween.EASE_OUT)
		tw2.chain().tween_property(lbl, "scale", Vector2.ONE, 0.2)
		tw2.tween_property(lbl, "modulate:a", 0.0, 0.5).set_delay(0.4)
		tw2.chain().tween_callback(lbl.queue_free)


func _game_over() -> void:
	playing = false
	cam.shake(25.0)
	_vibrate_strong()
	_game_over_explosion()
	SoundManager.play_sfx("res://assets/sounds/game_over.mp3")

	GameManager.games_played += 1
	if current_zone_index > GameManager.zones_reached:
		GameManager.zones_reached = current_zone_index

	var new_record := score > GameManager.high_score
	if new_record:
		GameManager.high_score = score
		GameManager.add_crystals(3)

	var final_coins := coins_earned * (2 if x2_active else 1)
	GameManager.add_coins(final_coins)
	GameManager.game_ended.emit(score, final_coins, current_zone_index)

	await get_tree().create_timer(0.5).timeout
	var packed: PackedScene = load("res://scenes/overlays/game_over_overlay.tscn")
	var overlay := packed.instantiate()
	overlay.setup(score, final_coins, GameManager.high_score)
	add_child(overlay)


func _game_over_explosion() -> void:
	if not current_block:
		return
	var cx := current_block.position.x + current_block.size.x / 2.0
	var cy := current_block.position.y + BLOCK_HEIGHT / 2.0

	var debris := CPUParticles2D.new()
	debris.position = Vector2(cx, cy)
	debris.emitting = true
	debris.one_shot = true
	debris.amount = 50
	debris.lifetime = 1.2
	debris.explosiveness = 1.0
	debris.direction = Vector2(0, -1)
	debris.spread = 180.0
	debris.initial_velocity_min = 150.0
	debris.initial_velocity_max = 400.0
	debris.gravity = Vector2(0, 500)
	debris.scale_amount_min = 2.0
	debris.scale_amount_max = 6.0
	debris.color = Color(1, 0.15, 0.1, 0.9)
	particles_node.add_child(debris)
	create_tween().bind_node(debris).tween_interval(2.0).finished.connect(debris.queue_free)

	var flash := CPUParticles2D.new()
	flash.position = Vector2(cx, cy)
	flash.emitting = true
	flash.one_shot = true
	flash.amount = 25
	flash.lifetime = 0.8
	flash.explosiveness = 1.0
	flash.direction = Vector2(0, 0)
	flash.spread = 180.0
	flash.initial_velocity_min = 80.0
	flash.initial_velocity_max = 200.0
	flash.gravity = Vector2(0, 0)
	flash.scale_amount_min = 4.0
	flash.scale_amount_max = 10.0
	flash.color = Color(1, 0.5, 0, 0.6)
	flash.damping_min = 200.0
	flash.damping_max = 400.0
	particles_node.add_child(flash)
	create_tween().bind_node(flash).tween_interval(1.5).finished.connect(flash.queue_free)


func _update_hud() -> void:
	score_label.text = str(score)
	combo_label.text = "x%d" % combo if combo > 1 else ""
	combo_label.visible = combo > 1
	coin_display.text = str(GameManager.wallet + coins_earned)


func _on_pause_pressed() -> void:
	if not playing:
		return
	var pause_packed: PackedScene = load("res://scenes/overlays/pause_overlay.tscn")
	var pause_overlay := pause_packed.instantiate()
	add_child(pause_overlay)


func _on_pu_left_pressed() -> void:
	if active_pu_slots.size() > 0:
		_activate_power_up(active_pu_slots[0], 0)


func _on_pu_right_pressed() -> void:
	if active_pu_slots.size() > 1:
		_activate_power_up(active_pu_slots[1], 1)


func _activate_power_up(pu_id: String, slot: int) -> void:
	match pu_id:
		"slowdown":
			if not slowdown_active:
				slowdown_active = true
				active_pu_slots[slot] = ""
				_update_pu_buttons()
				await get_tree().create_timer(5.0).timeout
				slowdown_active = false
		"widen":
			if current_block:
				var new_w := minf(current_block.size.x + 60.0, START_WIDTH)
				var diff := new_w - current_block.size.x
				current_block.size.x = new_w
				current_block.position.x -= diff / 2.0
			active_pu_slots[slot] = ""
			_update_pu_buttons()
		"magnet":
			magnet_charges = 3
			active_pu_slots[slot] = ""
			_update_pu_buttons()


func _show_tutorial() -> void:
	playing = false
	var tutorial: CanvasLayer = load("res://scripts/overlays/tutorial_overlay.gd").new()
	tutorial.tree_exited.connect(func(): playing = true)
	add_child(tutorial)


func restart() -> void:
	_setup_power_ups()
	_start_game()
