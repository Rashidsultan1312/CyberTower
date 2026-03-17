extends Camera2D

@export var follow_speed := 4.0
@export var bottom_margin := 0.4
var target_y := 0.0
var _shake_amount := 0.0
var _base_zoom := Vector2.ONE


func _process(delta: float) -> void:
	var vp_h := get_viewport_rect().size.y
	var goal_y := target_y + vp_h * bottom_margin - vp_h / 2.0
	position.y = lerpf(position.y, goal_y, follow_speed * delta)
	if _shake_amount > 0.1:
		offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake_amount
		_shake_amount = lerpf(_shake_amount, 0.0, 10.0 * delta)
	else:
		offset = Vector2.ZERO
		_shake_amount = 0.0


func shake(amount := 15.0) -> void:
	_shake_amount = amount


func zoom_pulse(strength := 0.08, duration := 0.3) -> void:
	var tw := create_tween()
	tw.tween_property(self, "zoom", _base_zoom * (1.0 + strength), duration * 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "zoom", _base_zoom, duration * 0.7).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func reset_to(base_y: float) -> void:
	var vp_h := get_viewport_rect().size.y
	target_y = base_y
	position.y = base_y + vp_h * bottom_margin - vp_h / 2.0
	offset = Vector2.ZERO
	_shake_amount = 0.0
	zoom = _base_zoom
