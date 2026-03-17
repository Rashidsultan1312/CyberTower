class_name UIStyle


static func neon_button(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.02, 0.01, 0.06, 0.7)
	normal.border_color = Color(0, 0.9, 0.95, 0.65)
	normal.set_border_width_all(3)
	normal.set_corner_radius_all(32)
	normal.content_margin_left = 28
	normal.content_margin_right = 28
	normal.content_margin_top = 14
	normal.content_margin_bottom = 14
	normal.shadow_color = Color(0, 1, 1, 0.15)
	normal.shadow_size = 10

	var hover := normal.duplicate()
	hover.border_color = Color(0, 1, 1, 1)
	hover.bg_color = Color(0, 0.06, 0.1, 0.85)
	hover.shadow_color = Color(0, 1, 1, 0.35)
	hover.shadow_size = 16

	var pressed := normal.duplicate()
	pressed.border_color = Color(0.5, 1, 1, 1)
	pressed.bg_color = Color(0, 0.1, 0.15, 0.9)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_color_override("font_color", Color(0, 1, 1, 1))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))


static func small_neon_button(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.02, 0.01, 0.06, 0.6)
	normal.border_color = Color(0, 0.9, 0.95, 0.5)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(16)
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6
	normal.shadow_color = Color(0, 1, 1, 0.1)
	normal.shadow_size = 4

	var hover := normal.duplicate()
	hover.border_color = Color(0, 1, 1, 1)
	hover.bg_color = Color(0, 0.06, 0.1, 0.8)

	var pressed := normal.duplicate()
	pressed.border_color = Color(0.5, 1, 1, 1)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_color_override("font_color", Color(0, 1, 1, 0.9))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))


static func neon_panel(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.01, 0.05, 0.92)
	style.border_color = Color(0, 0.85, 0.9, 0.6)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 28
	style.content_margin_bottom = 28
	style.shadow_color = Color(0, 1, 1, 0.12)
	style.shadow_size = 14
	panel.add_theme_stylebox_override("panel", style)


static func overlay_particles(parent: Node, accent := Color(0, 1, 1, 0.15)) -> void:
	var host := Node2D.new()
	parent.add_child(host)

	var sparkles := CPUParticles2D.new()
	sparkles.position = Vector2(375, 667)
	sparkles.amount = 20
	sparkles.lifetime = 5.0
	sparkles.speed_scale = 0.4
	sparkles.randomness = 1.0
	sparkles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sparkles.emission_rect_extents = Vector2(380, 680)
	sparkles.direction = Vector2(0, -1)
	sparkles.spread = 180.0
	sparkles.initial_velocity_min = 8.0
	sparkles.initial_velocity_max = 30.0
	sparkles.gravity = Vector2(0, 0)
	sparkles.scale_amount_min = 1.0
	sparkles.scale_amount_max = 3.0
	sparkles.color = accent
	host.add_child(sparkles)

	var orbs := CPUParticles2D.new()
	orbs.position = Vector2(375, 667)
	orbs.amount = 6
	orbs.lifetime = 10.0
	orbs.speed_scale = 0.1
	orbs.randomness = 1.0
	orbs.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	orbs.emission_rect_extents = Vector2(350, 600)
	orbs.direction = Vector2(0, -1)
	orbs.spread = 180.0
	orbs.initial_velocity_min = 3.0
	orbs.initial_velocity_max = 10.0
	orbs.gravity = Vector2(0, 0)
	orbs.scale_amount_min = 8.0
	orbs.scale_amount_max = 20.0
	orbs.color = Color(accent.r, accent.g, accent.b, 0.03)
	host.add_child(orbs)


static func animate_buttons_entrance(buttons: Array, tree: SceneTree, delay_start := 0.2) -> void:
	for i in buttons.size():
		var btn: Button = buttons[i]
		var orig_pos := btn.position
		btn.modulate.a = 0.0
		btn.position.y += 30.0
		var d := delay_start + i * 0.08
		var tw := tree.create_tween()
		tw.set_parallel(true)
		tw.tween_property(btn, "modulate:a", 1.0, 0.25).set_delay(d)
		tw.tween_property(btn, "position:y", orig_pos.y, 0.3).set_delay(d).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


static func animate_label_pop(label: Label, delay := 0.0) -> Tween:
	label.modulate.a = 0.0
	label.scale = Vector2(0.5, 0.5)
	var tw := label.create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "modulate:a", 1.0, 0.2).set_delay(delay)
	tw.tween_property(label, "scale", Vector2.ONE, 0.3).set_delay(delay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	return tw
