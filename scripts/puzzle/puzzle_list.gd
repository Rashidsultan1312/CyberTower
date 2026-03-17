extends Control

const PUZZLES := [
	"puzzle_01", "puzzle_02", "puzzle_03", "puzzle_04", "puzzle_05",
	"puzzle_06", "puzzle_07", "puzzle_08", "puzzle_09", "puzzle_10",
	"puzzle_11", "puzzle_12", "puzzle_13", "puzzle_14", "puzzle_15",
	"puzzle_16", "puzzle_17", "puzzle_18", "puzzle_19", "puzzle_20",
	"puzzle_21", "puzzle_22", "puzzle_23", "puzzle_24", "puzzle_25",
]

@onready var grid: GridContainer = $VBox/Scroll/Grid
@onready var scroll: ScrollContainer = $VBox/Scroll
@onready var coin_label: Label = $TopBar/CoinLabel
@onready var bg: TextureRect = $BG
var _time := 0.0

var _dragging := false
var _drag_start_y := 0.0
var _scroll_start := 0
var _velocity := 0.0
var _last_y := 0.0
var _last_time := 0.0
const DECEL := 8.0
const DRAG_THRESHOLD := 8.0
var _drag_distance := 0.0


func _ready() -> void:
	_apply_safe_area()
	coin_label.text = str(GameManager.wallet)
	UIStyle.small_neon_button($TopBar/BackBtn)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_build_list()


func _apply_safe_area() -> void:
	var safe_top := GameManager.get_safe_top()
	var safe_bottom := GameManager.get_safe_bottom()
	$TopBar.offset_top = maxf(safe_top, 10.0)
	$TopBar.offset_bottom = $TopBar.offset_top + 50.0
	$VBox.offset_top = $TopBar.offset_bottom + 10.0
	$VBox.offset_bottom = -maxf(safe_bottom, 20.0)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_dragging = true
			_drag_start_y = event.position.y
			_last_y = event.position.y
			_scroll_start = scroll.scroll_vertical
			_velocity = 0.0
			_drag_distance = 0.0
			_last_time = Time.get_ticks_msec()
		else:
			_dragging = false
	elif event is InputEventScreenDrag and _dragging:
		var dy: float = event.position.y - _last_y
		var now: float = float(Time.get_ticks_msec())
		var dt: float = maxf((now - _last_time) / 1000.0, 0.001)
		_velocity = -dy / dt
		_last_y = event.position.y
		_last_time = now
		_drag_distance += absf(dy)
		scroll.scroll_vertical = _scroll_start + int(_drag_start_y - event.position.y)


func _process(delta: float) -> void:
	_time += delta
	bg.position.x = sin(_time * 0.4) * 10.0
	bg.position.y = cos(_time * 0.3) * 8.0
	var pulse := 0.92 + sin(_time * 0.8) * 0.08
	bg.self_modulate = Color(pulse, pulse * 0.95, pulse * 1.05, 1.0)

	if not _dragging and absf(_velocity) > 1.0:
		scroll.scroll_vertical += int(_velocity * delta)
		_velocity = lerpf(_velocity, 0.0, DECEL * delta)


func _build_list() -> void:
	for child in grid.get_children():
		child.queue_free()
	var idx := 0
	for puzzle_id in PUZZLES:
		_add_puzzle_card(puzzle_id, idx)
		idx += 1


func _add_puzzle_card(puzzle_id: String, idx: int) -> void:
	var path := "res://assets/sprites/puzzle/%s/full.png" % puzzle_id
	if not ResourceLoader.exists(path):
		return
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(210, 240)
	var completed: bool = puzzle_id in GameManager.completed_puzzles
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.015, 0.07, 0.85)
	style.border_color = Color(0, 1, 0.7, 0.7) if completed else Color(0.3, 0.3, 0.4, 0.4)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	card.add_child(vbox)

	var tex := load(path) as Texture2D
	var img := TextureRect.new()
	img.texture = tex
	img.custom_minimum_size = Vector2(185, 145)
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(img)

	if completed:
		var check := Label.new()
		check.text = "DONE"
		check.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		check.add_theme_color_override("font_color", Color(0, 1, 0.7))
		check.add_theme_font_size_override("font_size", 18)
		vbox.add_child(check)

	var btn := Button.new()
	btn.text = "SOLVE"
	btn.pressed.connect(_open_puzzle.bind(puzzle_id))
	UIStyle.small_neon_button(btn)
	vbox.add_child(btn)

	grid.add_child(card)

	card.modulate.a = 0.0
	card.scale = Vector2(0.8, 0.8)
	card.pivot_offset = card.custom_minimum_size / 2.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(card, "modulate:a", 1.0, 0.3).set_delay(idx * 0.1)
	tw.tween_property(card, "scale", Vector2.ONE, 0.35).set_delay(idx * 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _open_puzzle(puzzle_id: String) -> void:
	SoundManager.play_sfx("res://assets/sounds/button.mp3")
	var packed: PackedScene = load("res://scenes/puzzle/puzzle_play.tscn")
	var instance := packed.instantiate()
	instance.puzzle_id = puzzle_id
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(instance)
	get_tree().current_scene = instance


func _on_back_pressed() -> void:
	SoundManager.play_sfx("res://assets/sounds/button.mp3")
	GameManager.change_scene("res://scenes/main_menu/main_menu.tscn")
