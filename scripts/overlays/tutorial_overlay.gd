extends CanvasLayer

var _step := 0
var _dim: ColorRect
var _container: VBoxContainer
var _title: Label
var _desc: Label
var _hand: Label
var _next_btn: Button
var _skip_btn: Button

const STEPS := [
	{
		"title": "BLOCK MOVES",
		"desc": "Block slides left and right\nautomatically",
		"hand_pos": Vector2(375, 800),
		"hand_text": ">>>",
	},
	{
		"title": "TAP TO PLACE",
		"desc": "Tap anywhere to drop\nthe block on the tower",
		"hand_pos": Vector2(375, 950),
		"hand_text": "TAP!",
	},
	{
		"title": "PERFECT = BONUS",
		"desc": "Align perfectly for combo\npoints and extra coins!",
		"hand_pos": Vector2(375, 800),
		"hand_text": "PERFECT!",
	},
]


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS

	_dim = ColorRect.new()
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0.01, 0.005, 0.04, 0.75)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)

	_container = VBoxContainer.new()
	_container.set_anchors_preset(Control.PRESET_CENTER)
	_container.offset_left = -250
	_container.offset_top = -200
	_container.offset_right = 250
	_container.offset_bottom = 200
	_container.add_theme_constant_override("separation", 20)
	_container.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_container)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_color_override("font_color", Color(0, 1, 1))
	_title.add_theme_font_size_override("font_size", 36)
	var font := load("res://assets/fonts/Orbitron-Bold.ttf")
	if font:
		_title.add_theme_font_override("font", font)
	_container.add_child(_title)

	_hand = Label.new()
	_hand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hand.add_theme_color_override("font_color", Color(1, 0.85, 0))
	_hand.add_theme_font_size_override("font_size", 48)
	_container.add_child(_hand)

	_desc = Label.new()
	_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9, 0.9))
	_desc.add_theme_font_size_override("font_size", 22)
	_container.add_child(_desc)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	_container.add_child(spacer)

	_next_btn = Button.new()
	_next_btn.text = "NEXT"
	_next_btn.custom_minimum_size = Vector2(200, 60)
	_next_btn.pressed.connect(_on_next)
	UIStyle.neon_button(_next_btn)
	_container.add_child(_next_btn)

	_skip_btn = Button.new()
	_skip_btn.text = "SKIP"
	_skip_btn.custom_minimum_size = Vector2(200, 50)
	_skip_btn.pressed.connect(_on_skip)
	UIStyle.small_neon_button(_skip_btn)
	_container.add_child(_skip_btn)

	var dots := Label.new()
	dots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dots.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6, 0.6))
	dots.add_theme_font_size_override("font_size", 18)
	dots.name = "Dots"
	_container.add_child(dots)

	_show_step(0)
	_animate_in()


func _show_step(idx: int) -> void:
	_step = idx
	var s: Dictionary = STEPS[idx]
	_title.text = s.title
	_desc.text = s.desc
	_hand.text = s.hand_text
	_next_btn.text = "GOT IT!" if idx == STEPS.size() - 1 else "NEXT"

	var dots_str := ""
	for i in STEPS.size():
		dots_str += " O " if i == idx else " . "
	var dots_label: Label = _container.get_node("Dots")
	dots_label.text = dots_str

	_hand.modulate.a = 0.0
	_hand.scale = Vector2(0.5, 0.5)
	_hand.pivot_offset = Vector2(125, 24)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_hand, "modulate:a", 1.0, 0.2)
	tw.tween_property(_hand, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	var pulse := create_tween().set_loops(3)
	pulse.tween_property(_hand, "scale", Vector2(1.15, 1.15), 0.4).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(_hand, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_SINE)


func _animate_in() -> void:
	_dim.modulate.a = 0.0
	_container.modulate.a = 0.0
	_container.scale = Vector2(0.5, 0.5)
	_container.pivot_offset = Vector2(250, 200)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_dim, "modulate:a", 1.0, 0.3)
	tw.tween_property(_container, "modulate:a", 1.0, 0.25).set_delay(0.1)
	tw.tween_property(_container, "scale", Vector2.ONE, 0.4).set_delay(0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _on_next() -> void:
	SoundManager.play_sfx("res://assets/sounds/button.mp3")
	if _step >= STEPS.size() - 1:
		_close()
	else:
		_show_step(_step + 1)


func _on_skip() -> void:
	SoundManager.play_sfx("res://assets/sounds/button.mp3")
	_close()


func _close() -> void:
	GameManager.tutorial_seen = true
	GameManager.save_game()
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_dim, "modulate:a", 0.0, 0.2)
	tw.tween_property(_container, "modulate:a", 0.0, 0.2)
	tw.tween_property(_container, "scale", Vector2(0.7, 0.7), 0.2)
	tw.chain().tween_callback(queue_free)
