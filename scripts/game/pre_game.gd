extends CanvasLayer

var selected: Array[String] = []

@onready var slots_box: HBoxContainer = $Panel/VBox/SlotsBox
@onready var items_box: VBoxContainer = $Panel/VBox/Scroll/Items
@onready var start_btn: Button = $Panel/VBox/StartBtn
@onready var panel: PanelContainer = $Panel
@onready var dim: ColorRect = $Dim


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	UIStyle.neon_panel(panel)
	UIStyle.neon_button(start_btn)
	UIStyle.small_neon_button($Panel/VBox/HButtons/SkipBtn)
	_build_inventory()
	_update_slots()
	_animate_in()


func _animate_in() -> void:
	dim.modulate.a = 0.0
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.6, 0.6)
	panel.pivot_offset = panel.size / 2.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(dim, "modulate:a", 1.0, 0.25)
	tw.tween_property(panel, "modulate:a", 1.0, 0.3).set_delay(0.05)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.4).set_delay(0.05).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _build_inventory() -> void:
	for child in items_box.get_children():
		child.queue_free()

	var idx := 0
	for pu_id in PowerUpData.get_all_ids():
		var count := GameManager.get_power_up_count(pu_id)
		var data: Dictionary = PowerUpData.info(pu_id)
		var is_selected: bool = pu_id in selected
		var can_select: bool = count > 0 and selected.size() < 2 and not is_selected

		var row := PanelContainer.new()
		var rs := StyleBoxFlat.new()
		if is_selected:
			rs.bg_color = Color(data.color.r * 0.15, data.color.g * 0.15, data.color.b * 0.15, 0.8)
			rs.border_color = data.color
			rs.shadow_color = Color(data.color.r, data.color.g, data.color.b, 0.15)
			rs.shadow_size = 8
		elif count > 0:
			rs.bg_color = Color(0.03, 0.015, 0.07, 0.8)
			rs.border_color = Color(data.color.r, data.color.g, data.color.b, 0.35)
		else:
			rs.bg_color = Color(0.02, 0.01, 0.04, 0.5)
			rs.border_color = Color(0.2, 0.2, 0.25, 0.2)
		rs.set_border_width_all(2)
		rs.set_corner_radius_all(10)
		rs.content_margin_left = 12
		rs.content_margin_right = 12
		rs.content_margin_top = 10
		rs.content_margin_bottom = 10
		row.add_theme_stylebox_override("panel", rs)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		row.add_child(hbox)

		var icon_tex := TextureRect.new()
		icon_tex.texture = load(data.icon_path)
		icon_tex.custom_minimum_size = Vector2(36, 36)
		icon_tex.expand_mode = 3
		icon_tex.stretch_mode = 5
		icon_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(icon_tex)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 2)
		hbox.add_child(info)

		var name_lbl := Label.new()
		name_lbl.text = data.name
		name_lbl.add_theme_color_override("font_color", data.color if count > 0 else Color(0.4, 0.4, 0.5, 0.5))
		name_lbl.add_theme_font_size_override("font_size", 18)
		info.add_child(name_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = data.desc
		desc_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6, 0.5))
		desc_lbl.add_theme_font_size_override("font_size", 12)
		info.add_child(desc_lbl)

		var count_lbl := Label.new()
		if is_selected:
			count_lbl.text = "OK"
			count_lbl.add_theme_color_override("font_color", data.color)
		elif count > 0:
			count_lbl.text = "x%d" % count
			count_lbl.add_theme_color_override("font_color", Color(0, 1, 1, 0.8))
		else:
			count_lbl.text = "—"
			count_lbl.add_theme_color_override("font_color", Color(0.3, 0.3, 0.4, 0.4))
		count_lbl.add_theme_font_size_override("font_size", 18)
		count_lbl.custom_minimum_size = Vector2(40, 0)
		count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hbox.add_child(count_lbl)

		if can_select:
			row.mouse_filter = Control.MOUSE_FILTER_STOP
			row.gui_input.connect(_on_row_input.bind(pu_id))
		else:
			row.mouse_filter = Control.MOUSE_FILTER_IGNORE

		row.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(row, "modulate:a", 1.0 if count > 0 else 0.5, 0.2).set_delay(idx * 0.05)
		items_box.add_child(row)
		idx += 1


func _on_row_input(event: InputEvent, pu_id: String) -> void:
	if event is InputEventMouseButton and event.pressed:
		_on_select(pu_id)


func _update_slots() -> void:
	for child in slots_box.get_children():
		child.queue_free()
	for i in range(2):
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(240, 50)
		var ss := StyleBoxFlat.new()
		ss.set_corner_radius_all(8)
		ss.content_margin_left = 10
		ss.content_margin_right = 10
		ss.content_margin_top = 6
		ss.content_margin_bottom = 6

		var lbl := Label.new()
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 18)

		if i < selected.size():
			var data: Dictionary = PowerUpData.info(selected[i])
			lbl.text = data.name
			lbl.add_theme_color_override("font_color", data.color)
			ss.bg_color = Color(data.color.r * 0.1, data.color.g * 0.1, data.color.b * 0.1, 0.6)
			ss.border_color = Color(data.color.r, data.color.g, data.color.b, 0.5)
			ss.set_border_width_all(2)
		else:
			lbl.text = "slot %d" % (i + 1)
			lbl.add_theme_color_override("font_color", Color(0.35, 0.35, 0.4, 0.4))
			ss.bg_color = Color(0.02, 0.01, 0.05, 0.4)
			ss.border_color = Color(0.2, 0.2, 0.3, 0.2)
			ss.set_border_width_all(1)

		slot.add_theme_stylebox_override("panel", ss)
		slot.add_child(lbl)
		slots_box.add_child(slot)

		slot.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(slot, "modulate:a", 1.0, 0.2).set_delay(i * 0.1)


func _on_select(pu_id: String) -> void:
	if selected.size() >= 2 or pu_id in selected:
		return
	selected.append(pu_id)
	SoundManager.play_sfx("res://assets/sounds/button.mp3")
	_build_inventory()
	_update_slots()


func _on_start_pressed() -> void:
	SoundManager.play_sfx("res://assets/sounds/button.mp3")
	GameManager.selected_power_ups = selected.duplicate()
	_close()
	GameManager.change_scene("res://scenes/game/game.tscn")


func _on_skip_pressed() -> void:
	SoundManager.play_sfx("res://assets/sounds/button.mp3")
	GameManager.selected_power_ups = []
	_close()
	GameManager.change_scene("res://scenes/game/game.tscn")


func _close() -> void:
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(dim, "modulate:a", 0.0, 0.15)
	tw.tween_property(panel, "modulate:a", 0.0, 0.15)
	tw.tween_property(panel, "scale", Vector2(0.8, 0.8), 0.15)
	tw.tween_callback(queue_free)
