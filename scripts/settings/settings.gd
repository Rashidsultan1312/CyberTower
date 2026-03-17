extends CanvasLayer

@onready var sound_toggle: CheckButton = $Panel/VBox/SoundRow/Toggle
@onready var music_toggle: CheckButton = $Panel/VBox/MusicRow/Toggle
@onready var vibration_toggle: CheckButton = $Panel/VBox/VibrationRow/Toggle
@onready var sfx_slider: HSlider = $Panel/VBox/SFXVolRow/Slider
@onready var music_slider: HSlider = $Panel/VBox/MusicVolRow/Slider
@onready var panel: PanelContainer = $Panel
@onready var dim: ColorRect = $Dim
@onready var title: Label = $Panel/VBox/Header/Title


func _ready() -> void:
	sound_toggle.button_pressed = GameManager.settings.sound
	music_toggle.button_pressed = GameManager.settings.music
	vibration_toggle.button_pressed = GameManager.settings.vibration
	sfx_slider.value = GameManager.settings.sfx_volume
	music_slider.value = GameManager.settings.music_volume

	_style_panel()
	UIStyle.small_neon_button($Panel/VBox/Header/CloseBtn)
	_style_sliders()

	UIStyle.overlay_particles(self, Color(0, 1, 1, 0.08))
	_animate_in()


func _style_panel() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.01, 0.05, 0.82)
	style.border_color = Color(0, 0.85, 0.9, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 28
	style.content_margin_bottom = 28
	style.shadow_color = Color(0, 1, 1, 0.1)
	style.shadow_size = 12
	panel.add_theme_stylebox_override("panel", style)


func _style_sliders() -> void:
	for slider in [sfx_slider, music_slider]:
		var grabber := StyleBoxFlat.new()
		grabber.bg_color = Color(0, 1, 1, 0.9)
		grabber.set_corner_radius_all(10)
		grabber.content_margin_left = 10
		grabber.content_margin_right = 10
		grabber.content_margin_top = 10
		grabber.content_margin_bottom = 10
		grabber.shadow_color = Color(0, 1, 1, 0.3)
		grabber.shadow_size = 6

		var grabber_hl := grabber.duplicate()
		grabber_hl.bg_color = Color(0.3, 1, 1, 1)
		grabber_hl.shadow_size = 10

		var track := StyleBoxFlat.new()
		track.bg_color = Color(0.1, 0.1, 0.15, 0.6)
		track.set_corner_radius_all(4)
		track.content_margin_top = 4
		track.content_margin_bottom = 4

		var fill := StyleBoxFlat.new()
		fill.bg_color = Color(0, 0.6, 0.65, 0.4)
		fill.set_corner_radius_all(4)
		fill.content_margin_top = 4
		fill.content_margin_bottom = 4

		slider.add_theme_stylebox_override("grabber_area", fill)
		slider.add_theme_stylebox_override("grabber_area_highlight", fill)
		slider.add_theme_stylebox_override("slider", track)
		slider.add_theme_icon_override("grabber", ImageTexture.new())
		slider.add_theme_icon_override("grabber_highlight", ImageTexture.new())
		slider.add_theme_stylebox_override("grabber", grabber)
		slider.add_theme_stylebox_override("grabber_highlight", grabber_hl)


func _animate_in() -> void:
	dim.modulate.a = 0.0
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.5, 0.5)
	panel.pivot_offset = panel.size / 2.0

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(dim, "modulate:a", 1.0, 0.25)
	tw.tween_property(panel, "modulate:a", 1.0, 0.25).set_delay(0.05)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.4).set_delay(0.05).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	var glow := create_tween().set_loops()
	glow.tween_property(title, "theme_override_colors/font_color", Color(0.3, 1, 1, 1), 1.0).set_trans(Tween.TRANS_SINE)
	glow.tween_property(title, "theme_override_colors/font_color", Color(0, 0.7, 0.8, 1), 1.0).set_trans(Tween.TRANS_SINE)


func _animate_out() -> void:
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(dim, "modulate:a", 0.0, 0.2)
	tw.tween_property(panel, "modulate:a", 0.0, 0.2)
	tw.tween_property(panel, "scale", Vector2(0.8, 0.8), 0.2)
	tw.chain().tween_callback(queue_free)


func _on_sound_toggled(on: bool) -> void:
	GameManager.settings.sound = on
	SoundManager.update_sfx_state()
	GameManager.save_game()


func _on_music_toggled(on: bool) -> void:
	GameManager.settings.music = on
	SoundManager.update_music_state()
	GameManager.save_game()


func _on_vibration_toggled(on: bool) -> void:
	GameManager.settings.vibration = on
	GameManager.save_game()


func _on_sfx_vol_changed(val: float) -> void:
	GameManager.settings.sfx_volume = val
	SoundManager.set_sfx_volume(val)
	GameManager.save_game()


func _on_music_vol_changed(val: float) -> void:
	GameManager.settings.music_volume = val
	SoundManager.set_music_volume(val)
	GameManager.save_game()


func _on_close_pressed() -> void:
	SoundManager.play_sfx("res://assets/sounds/button.mp3")
	_animate_out()
