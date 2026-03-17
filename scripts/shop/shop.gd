extends Control

const COLS := 3
const CARD_W := 218
const CARD_GAP := 12
const VIEWPORT_W := 710

var current_tab := 0
var _time := 0.0

@onready var card_list: VBoxContainer = $VBox/Scroll/CardList
@onready var coin_label: Label = $TopBar/CoinLabel
@onready var crystal_label: Label = $TopBar/CrystalLabel
@onready var tab_skins: Button = $TabBar/TabSkins
@onready var tab_powerups: Button = $TabBar/TabPowerups
@onready var title_label: Label = $TopBar/Title


func _ready() -> void:
	_apply_safe_area()
	_update_currencies()
	GameManager.wallet_changed.connect(func(_v): _update_currencies())
	GameManager.crystals_changed.connect(func(_v): _update_currencies())
	UIStyle.small_neon_button($TopBar/BackBtn)
	_style_tabs()
	_select_tab(0)
	_start_title_glow()


func _apply_safe_area() -> void:
	var safe_top := GameManager.get_safe_top()
	$TopBar.offset_top = maxf(safe_top, 10.0)
	$TopBar.offset_bottom = $TopBar.offset_top + 50.0
	if has_node("TabBar"):
		$TabBar.offset_top = $TopBar.offset_bottom + 4.0
		$TabBar.offset_bottom = $TabBar.offset_top + 50.0
	if has_node("VBox"):
		var tab_bottom: float = $TabBar.offset_bottom if has_node("TabBar") else $TopBar.offset_bottom
		$VBox.offset_top = tab_bottom + 8.0
		$VBox.offset_bottom = -maxf(GameManager.get_safe_bottom(), 20.0)


func _process(delta: float) -> void:
	_time += delta


func _start_title_glow() -> void:
	var tw := create_tween().set_loops()
	tw.tween_property(title_label, "theme_override_colors/font_color", Color(0.3, 1, 1, 1), 1.0).set_trans(Tween.TRANS_SINE)
	tw.tween_property(title_label, "theme_override_colors/font_color", Color(0, 0.65, 0.75, 1), 1.0).set_trans(Tween.TRANS_SINE)


func _update_currencies() -> void:
	coin_label.text = str(GameManager.wallet)
	crystal_label.text = str(GameManager.crystals)


func _style_tabs() -> void:
	for btn in [tab_skins, tab_powerups]:
		UIStyle.small_neon_button(btn)


func _select_tab(idx: int) -> void:
	current_tab = idx
	var tabs := [tab_skins, tab_powerups]
	for i in range(tabs.size()):
		var active := i == idx
		tabs[i].add_theme_color_override("font_color", Color(0, 1, 1, 1) if active else Color(0.4, 0.4, 0.5, 0.7))
		var s := tabs[i].get_theme_stylebox("normal").duplicate() as StyleBoxFlat
		if s:
			s.border_color = Color(0, 1, 1, 0.8) if active else Color(0.3, 0.3, 0.4, 0.3)
			tabs[i].add_theme_stylebox_override("normal", s)
	match idx:
		0: _build_skins()
		1: _build_powerups()


func _clear_cards() -> void:
	for child in card_list.get_children():
		child.queue_free()


func _make_centered_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", CARD_GAP)
	return row


func _build_skins() -> void:
	_clear_cards()
	var cards: Array[PanelContainer] = []
	var idx := 0
	for skin_id in GameManager.get_all_skins():
		var data: Dictionary = GameManager.get_skin_data(skin_id)
		cards.append(_create_skin_card(skin_id, data, idx))
		idx += 1
	_layout_cards(cards)


func _layout_cards(cards: Array[PanelContainer]) -> void:
	var row := _make_centered_row()
	card_list.add_child(row)
	var col := 0
	for card in cards:
		if col >= COLS:
			row = _make_centered_row()
			card_list.add_child(row)
			col = 0
		row.add_child(card)
		col += 1


func _create_skin_card(skin_id: String, data: Dictionary, idx: int) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(CARD_W, 290)
	var selected := skin_id == GameManager.selected_skin
	var unlocked: bool = skin_id in GameManager.unlocked_skins

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.015, 0.07, 0.92)
	style.border_color = data.outline if selected else Color(0.2, 0.2, 0.3, 0.4)
	style.set_border_width_all(3 if selected else 2)
	style.set_corner_radius_all(14)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	if selected:
		style.shadow_color = Color(data.outline.r, data.outline.g, data.outline.b, 0.3)
		style.shadow_size = 16
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)

	var preview := Panel.new()
	preview.custom_minimum_size = Vector2(180, 85)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ps := StyleBoxFlat.new()
	ps.bg_color = data.fill
	ps.border_color = data.outline
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(8)
	ps.shadow_color = Color(data.outline.r, data.outline.g, data.outline.b, 0.2)
	ps.shadow_size = 8
	preview.add_theme_stylebox_override("panel", ps)
	vbox.add_child(preview)

	var name_lbl := Label.new()
	name_lbl.text = data.name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_color_override("font_color", data.outline)
	name_lbl.add_theme_font_size_override("font_size", 22)
	var font := load("res://assets/fonts/Orbitron-Bold.ttf")
	if font:
		name_lbl.add_theme_font_override("font", font)
	vbox.add_child(name_lbl)

	if not unlocked:
		var price_lbl := Label.new()
		if data.crystal_price > 0:
			price_lbl.text = "%d cr." % data.crystal_price
			price_lbl.add_theme_color_override("font_color", Color(0.5, 0.85, 1, 0.95))
		else:
			price_lbl.text = "%d $" % data.price
			price_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0, 0.9))
		price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price_lbl.add_theme_font_size_override("font_size", 17)
		vbox.add_child(price_lbl)

	var btn := Button.new()
	if selected:
		btn.text = "EQUIPPED"
		btn.disabled = true
	elif unlocked:
		btn.text = "EQUIP"
	else:
		btn.text = "BUY"
	btn.custom_minimum_size = Vector2(0, 42)
	btn.pressed.connect(_on_skin_pressed.bind(skin_id))
	UIStyle.small_neon_button(btn)
	vbox.add_child(btn)

	_animate_card(card, idx)
	return card


func _build_powerups() -> void:
	_clear_cards()
	var cards: Array[PanelContainer] = []
	var idx := 0
	for pu_id in PowerUpData.get_all_ids():
		var data: Dictionary = PowerUpData.info(pu_id)
		cards.append(_create_pu_card(pu_id, data, idx))
		idx += 1
	_layout_cards(cards)


func _create_pu_card(pu_id: String, data: Dictionary, idx: int) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(CARD_W, 270)
	var cnt := GameManager.get_power_up_count(pu_id)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.015, 0.07, 0.92)
	style.border_color = Color(data.color.r, data.color.g, data.color.b, 0.45)
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	if cnt > 0:
		style.shadow_color = Color(data.color.r, data.color.g, data.color.b, 0.15)
		style.shadow_size = 10
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)

	var icon_wrap := CenterContainer.new()
	icon_wrap.custom_minimum_size = Vector2(0, 50)
	var icon_tex := TextureRect.new()
	icon_tex.texture = load(data.icon_path)
	icon_tex.custom_minimum_size = Vector2(48, 48)
	icon_tex.expand_mode = 3
	icon_tex.stretch_mode = 5
	icon_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_wrap.add_child(icon_tex)
	vbox.add_child(icon_wrap)

	var name_lbl := Label.new()
	name_lbl.text = data.name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_color_override("font_color", data.color)
	name_lbl.add_theme_font_size_override("font_size", 19)
	vbox.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = data.desc
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.75, 0.7))
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_lbl)

	var count_lbl := Label.new()
	count_lbl.text = "x%d" % cnt if cnt > 0 else "none"
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_lbl.add_theme_color_override("font_color", Color(0, 1, 1, 0.8) if cnt > 0 else Color(0.4, 0.4, 0.5, 0.5))
	count_lbl.add_theme_font_size_override("font_size", 15)
	vbox.add_child(count_lbl)

	var btn := Button.new()
	btn.text = "%d $" % data.price
	btn.disabled = GameManager.wallet < data.price
	btn.custom_minimum_size = Vector2(0, 42)
	btn.pressed.connect(_on_pu_buy.bind(pu_id))
	UIStyle.small_neon_button(btn)
	vbox.add_child(btn)

	_animate_card(card, idx)
	return card



func _animate_card(card: PanelContainer, idx: int) -> void:
	card.modulate.a = 0.0
	card.scale = Vector2(0.8, 0.8)
	card.pivot_offset = card.custom_minimum_size / 2.0
	var delay := idx * 0.07
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(card, "modulate:a", 1.0, 0.3).set_delay(delay)
	tw.tween_property(card, "scale", Vector2.ONE, 0.35).set_delay(delay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _purchase_burst() -> void:
	var host := Node2D.new()
	host.position = Vector2(375, 667)
	add_child(host)
	var colors := [Color(1, 0.85, 0), Color(0, 1, 1), Color(1, 1, 1, 0.6)]
	for c in colors:
		var p := CPUParticles2D.new()
		p.emitting = true
		p.one_shot = true
		p.amount = 20
		p.lifetime = 0.8
		p.explosiveness = 0.9
		p.direction = Vector2(0, -1)
		p.spread = 180.0
		p.initial_velocity_min = 100.0
		p.initial_velocity_max = 300.0
		p.gravity = Vector2(0, 250)
		p.scale_amount_min = 2.0
		p.scale_amount_max = 4.0
		p.color = c
		host.add_child(p)
	create_tween().bind_node(host).tween_interval(2.0).finished.connect(host.queue_free)


func _not_enough_coins() -> void:
	var lbl := Label.new()
	lbl.text = "NOT ENOUGH!"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_CENTER)
	lbl.offset_left = -120
	lbl.offset_right = 120
	lbl.offset_top = 50
	lbl.offset_bottom = 90
	lbl.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	lbl.add_theme_font_size_override("font_size", 28)
	var font := load("res://assets/fonts/Orbitron-Bold.ttf")
	if font:
		lbl.add_theme_font_override("font", font)
	add_child(lbl)

	lbl.modulate.a = 0.0
	lbl.scale = Vector2(0.5, 0.5)
	lbl.pivot_offset = Vector2(120, 20)
	var tw := create_tween().bind_node(lbl)
	tw.set_parallel(true)
	tw.tween_property(lbl, "modulate:a", 1.0, 0.15)
	tw.tween_property(lbl, "scale", Vector2(1.1, 1.1), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.chain().tween_property(lbl, "scale", Vector2.ONE, 0.1)
	tw.chain().tween_property(lbl, "position:y", lbl.position.y - 40, 0.6)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.4).set_delay(0.5)
	tw.chain().tween_callback(lbl.queue_free)

	coin_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	var tw2 := create_tween()
	tw2.tween_property(coin_label, "scale", Vector2(1.3, 1.3), 0.1)
	tw2.tween_property(coin_label, "scale", Vector2.ONE, 0.15)
	tw2.tween_callback(func(): coin_label.add_theme_color_override("font_color", Color(1, 0.85, 0, 1)))


func _on_skin_pressed(skin_id: String) -> void:
	SoundManager.play_sfx("res://assets/sounds/button.mp3")
	if skin_id in GameManager.unlocked_skins:
		GameManager.select_skin(skin_id)
	else:
		if GameManager.unlock_skin(skin_id):
			SoundManager.play_sfx("res://assets/sounds/purchase.mp3")
			_purchase_burst()
		else:
			_not_enough_coins()
	_select_tab(0)


func _on_pu_buy(pu_id: String) -> void:
	var data: Dictionary = PowerUpData.info(pu_id)
	if GameManager.wallet >= data.price:
		GameManager.wallet -= data.price
		GameManager.add_power_up(pu_id)
		SoundManager.play_sfx("res://assets/sounds/purchase.mp3")
		_purchase_burst()
		_select_tab(1)
	else:
		_not_enough_coins()


func _on_tab_skins_pressed() -> void:
	SoundManager.play_sfx("res://assets/sounds/button.mp3")
	_select_tab(0)


func _on_tab_powerups_pressed() -> void:
	SoundManager.play_sfx("res://assets/sounds/button.mp3")
	_select_tab(1)



func _on_back_pressed() -> void:
	SoundManager.play_sfx("res://assets/sounds/button.mp3")
	GameManager.change_scene("res://scenes/main_menu/main_menu.tscn")
