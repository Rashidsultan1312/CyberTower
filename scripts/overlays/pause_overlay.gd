extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var dim: ColorRect = $Dim
@onready var title: Label = $Panel/VBox/Title
@onready var resume_btn: Button = $Panel/VBox/ResumeBtn
@onready var menu_btn: Button = $Panel/VBox/MenuBtn


func _ready() -> void:
	get_tree().paused = true
	UIStyle.neon_panel(panel)
	UIStyle.neon_button(resume_btn)
	UIStyle.neon_button(menu_btn)

	UIStyle.overlay_particles(self, Color(0, 1, 1, 0.12))

	dim.modulate.a = 0.0
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.5, 0.5)
	panel.pivot_offset = panel.size / 2.0

	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.set_parallel(true)
	tw.tween_property(dim, "modulate:a", 1.0, 0.25)
	tw.tween_property(panel, "modulate:a", 1.0, 0.25).set_delay(0.1)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.4).set_delay(0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	title.modulate.a = 0.0
	resume_btn.modulate.a = 0.0
	menu_btn.modulate.a = 0.0

	var tw2 := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw2.tween_property(title, "modulate:a", 1.0, 0.2).set_delay(0.3)
	tw2.tween_property(resume_btn, "modulate:a", 1.0, 0.2).set_delay(0.1)
	tw2.tween_property(menu_btn, "modulate:a", 1.0, 0.2).set_delay(0.1)

	var glow := create_tween().set_loops().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	glow.tween_property(title, "theme_override_colors/font_color", Color(0.3, 1, 1, 1), 0.8).set_trans(Tween.TRANS_SINE)
	glow.tween_property(title, "theme_override_colors/font_color", Color(0, 0.7, 0.8, 1), 0.8).set_trans(Tween.TRANS_SINE)


func _on_resume_pressed() -> void:
	SoundManager.play_sfx("res://assets/sounds/button.mp3")
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.set_parallel(true)
	tw.tween_property(panel, "scale", Vector2(0.8, 0.8), 0.15)
	tw.tween_property(panel, "modulate:a", 0.0, 0.15)
	tw.tween_property(dim, "modulate:a", 0.0, 0.2)
	tw.chain().tween_callback(func():
		get_tree().paused = false
		queue_free()
	)


func _on_menu_pressed() -> void:
	SoundManager.play_sfx("res://assets/sounds/button.mp3")
	get_tree().paused = false
	queue_free()
	GameManager.change_scene("res://scenes/main_menu/main_menu.tscn")
