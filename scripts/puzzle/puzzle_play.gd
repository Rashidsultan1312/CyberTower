extends Control

var puzzle_id := ""
const GRID := 4
const SNAP_DIST := 50.0
const VP_W := 750.0
const VP_H := 1334.0
const TRAY_SCALE := 0.55

var pieces: Array[Dictionary] = []
var slot_occupied: Array[int] = []
var dragging_idx := -1
var drag_offset := Vector2.ZERO
var solved_count := 0
var board_pos := Vector2.ZERO
var cell_w := 0.0
var cell_h := 0.0
var grid_w := 0.0
var grid_h := 0.0
var slot_positions: Array[Vector2] = []
var _time := 0.0
var _total := 0

@onready var board: Node2D = $Board
@onready var bg: TextureRect = $BG
@onready var progress_label: Label = $BottomBar/Progress
@onready var percent_label: Label = $BottomBar/Percent


func _ready() -> void:
	UIStyle.small_neon_button($TopBar/BackBtn)

	var path := "res://assets/sprites/puzzle/%s/full.png" % puzzle_id
	var tex := load(path) as Texture2D
	if not tex:
		GameManager.change_scene("res://scenes/puzzle/puzzle_list.tscn")
		return

	var img := tex.get_image()
	var iw := img.get_width()
	var ih := img.get_height()
	_total = GRID * GRID

	var max_w := VP_W - 40.0
	var max_h := 580.0
	var scale_fit := minf(max_w / iw, max_h / ih)
	grid_w = floorf(iw * scale_fit)
	grid_h = floorf(ih * scale_fit)
	cell_w = floorf(grid_w / GRID)
	cell_h = floorf(grid_h / GRID)
	grid_w = cell_w * GRID
	grid_h = cell_h * GRID

	board_pos = Vector2(floorf((VP_W - grid_w) / 2.0), 95.0)
	board.position = board_pos

	for i in _total:
		slot_positions.append(Vector2((i % GRID) * cell_w, (i / GRID) * cell_h))
		slot_occupied.append(-1)

	_draw_grid()
	_create_pieces(img, iw / GRID, ih / GRID)
	_draw_reference(tex)
	_update_hud()


func _draw_grid() -> void:
	for row in GRID:
		for col in GRID:
			var rect := ColorRect.new()
			rect.position = Vector2(col * cell_w + 1, row * cell_h + 1)
			rect.size = Vector2(cell_w - 2, cell_h - 2)
			rect.color = Color(0.04, 0.02, 0.08, 0.5)
			rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			board.add_child(rect)

	var frame := ReferenceRect.new()
	frame.position = Vector2(-1, -1)
	frame.size = Vector2(grid_w + 2, grid_h + 2)
	frame.border_color = Color(0, 1, 1, 0.2)
	frame.border_width = 2.0
	frame.editor_only = false
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(frame)


func _create_pieces(img: Image, src_w: int, src_h: int) -> void:
	var tray_top := grid_h + 20.0
	var thumb_w := cell_w * TRAY_SCALE
	var thumb_h := cell_h * TRAY_SCALE
	var pad := 8.0
	var cols := 5
	var total_w := cols * thumb_w + (cols - 1) * pad
	var start_x := (grid_w - total_w) / 2.0

	var order := range(_total)
	order.shuffle()

	for i in _total:
		var orig_idx: int = order[i]
		var row := orig_idx / GRID
		var col := orig_idx % GRID
		var region := Rect2i(col * src_w, row * src_h, src_w, src_h)
		var piece_img := img.get_region(region)
		var piece_tex := ImageTexture.create_from_image(piece_img)

		var sprite := Sprite2D.new()
		sprite.texture = piece_tex
		sprite.centered = false
		sprite.scale = Vector2(cell_w / src_w, cell_h / src_h) * TRAY_SCALE

		var tray_row := i / cols
		var tray_col := i % cols
		var tx := start_x + tray_col * (thumb_w + pad)
		var ty := tray_top + tray_row * (thumb_h + pad)
		sprite.position = Vector2(tx, ty)
		sprite.z_index = 1

		board.add_child(sprite)
		pieces.append({
			"sprite": sprite,
			"idx": orig_idx,
			"solved": false,
			"in_tray": true,
			"full_scale": Vector2(cell_w / src_w, cell_h / src_h),
			"tray_scale": Vector2(cell_w / src_w, cell_h / src_h) * TRAY_SCALE,
			"tray_pos": Vector2(tx, ty),
		})


func _draw_reference(tex: Texture2D) -> void:
	var ref := Sprite2D.new()
	ref.texture = tex
	ref.centered = false
	var rw := 70.0
	var rh := rw * (grid_h / grid_w)
	ref.scale = Vector2(rw / tex.get_width(), rh / tex.get_height())
	ref.position = Vector2(grid_w - rw - 2, -rh - 6)
	ref.modulate = Color(1, 1, 1, 0.4)
	ref.z_index = 0
	board.add_child(ref)


func _update_hud() -> void:
	progress_label.text = "%d / %d" % [solved_count, _total]
	percent_label.text = "%d%%" % [int(float(solved_count) / float(_total) * 100.0)]


func _process(delta: float) -> void:
	_time += delta
	bg.position.x = sin(_time * 0.3) * 5.0
	bg.position.y = cos(_time * 0.2) * 4.0


func _input(event: InputEvent) -> void:
	var pos := Vector2.ZERO
	var is_press := false
	var is_release := false
	var is_move := false

	if event is InputEventScreenTouch:
		pos = event.position
		is_press = event.pressed
		is_release = not event.pressed
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.position
		is_press = event.pressed
		is_release = not event.pressed
	elif event is InputEventScreenDrag:
		pos = event.position
		is_move = true
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		pos = event.position
		is_move = true
	else:
		return

	var local := pos - board_pos

	if is_press and dragging_idx == -1:
		_try_grab(local)
	elif is_release and dragging_idx >= 0:
		_try_drop(local)
	elif is_move and dragging_idx >= 0:
		var p: Dictionary = pieces[dragging_idx]
		var spr: Sprite2D = p.sprite
		spr.position = local - drag_offset


func _get_piece_rect(i: int) -> Rect2:
	var p: Dictionary = pieces[i]
	var spr: Sprite2D = p.sprite
	var tex_size := Vector2(spr.texture.get_width(), spr.texture.get_height())
	var visual := tex_size * spr.scale
	return Rect2(spr.position, visual)


func _try_grab(local_pos: Vector2) -> void:
	for i in range(pieces.size() - 1, -1, -1):
		var p: Dictionary = pieces[i]
		if p.solved:
			continue
		var rect := _get_piece_rect(i)
		if rect.has_point(local_pos):
			dragging_idx = i
			var spr: Sprite2D = p.sprite
			var idx: int = p.idx
			for si in _total:
				if slot_occupied[si] == idx:
					slot_occupied[si] = -1

			spr.scale = p.full_scale
			p.in_tray = false
			spr.z_index = 10
			spr.modulate = Color(1.15, 1.15, 1.15, 0.9)
			drag_offset = local_pos - spr.position
			board.move_child(spr, -1)
			return


func _find_nearest_slot(center: Vector2) -> int:
	var best := -1
	var best_dist := 999999.0
	for i in _total:
		if slot_occupied[i] >= 0:
			continue
		var sc := slot_positions[i] + Vector2(cell_w / 2.0, cell_h / 2.0)
		var d := center.distance_to(sc)
		if d < best_dist:
			best_dist = d
			best = i
	if best_dist < SNAP_DIST:
		return best
	return -1


func _try_drop(local_pos: Vector2) -> void:
	if dragging_idx < 0:
		return
	var p: Dictionary = pieces[dragging_idx]
	var spr: Sprite2D = p.sprite
	var idx: int = p.idx
	spr.z_index = 1
	spr.modulate = Color.WHITE

	var vis_size := Vector2(spr.texture.get_width(), spr.texture.get_height()) * spr.scale
	var center := spr.position + vis_size / 2.0
	var slot := _find_nearest_slot(center)

	if slot >= 0:
		slot_occupied[slot] = idx
		var target := slot_positions[slot]
		var tw := create_tween().bind_node(spr)
		tw.tween_property(spr, "position", target, 0.1).set_ease(Tween.EASE_OUT)

		if slot == idx:
			p.solved = true
			solved_count += 1
			SoundManager.play_sfx("res://assets/sounds/puzzle_snap.mp3")
			_update_hud()
			spr.modulate = Color(1.5, 1.5, 1.5, 1)
			tw.chain().tween_property(spr, "modulate", Color.WHITE, 0.15)
			if solved_count >= _total:
				_puzzle_complete()
		else:
			spr.modulate = Color(1, 0.8, 0.8, 1)
			tw.chain().tween_property(spr, "modulate", Color.WHITE, 0.2)

	dragging_idx = -1


func _puzzle_complete() -> void:
	SoundManager.play_sfx("res://assets/sounds/puzzle_done.mp3")
	GameManager.complete_puzzle(puzzle_id)

	var done := Label.new()
	done.text = "COMPLETE!"
	done.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	done.add_theme_color_override("font_color", Color(0, 1, 1, 1))
	var font := load("res://assets/fonts/Orbitron-Bold.ttf")
	if font:
		done.add_theme_font_override("font", font)
	done.add_theme_font_size_override("font_size", 42)
	done.size = Vector2(grid_w, 60)
	done.position = Vector2(0, grid_h / 2.0 - 30)
	done.modulate.a = 0.0
	board.add_child(done)
	create_tween().tween_property(done, "modulate:a", 1.0, 0.3).set_delay(0.2)

	await get_tree().create_timer(2.5).timeout
	GameManager.change_scene("res://scenes/puzzle/puzzle_list.tscn")


func _on_back_pressed() -> void:
	SoundManager.play_sfx("res://assets/sounds/button.mp3")
	GameManager.change_scene("res://scenes/puzzle/puzzle_list.tscn")
