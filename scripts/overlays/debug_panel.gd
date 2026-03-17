extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var toggle_btn: Button = $ToggleBtn
@onready var fps_label: Label = $Panel/Scroll/VBox/FPSLabel
@onready var god_check: CheckButton = $Panel/Scroll/VBox/GodRow/GodCheck
var _fps_timer := 0.0


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = DebugManager.panel_open
	god_check.button_pressed = DebugManager.god_mode


func _process(delta: float) -> void:
	_fps_timer += delta
	if _fps_timer >= 0.5:
		_fps_timer = 0.0
		if panel.visible:
			fps_label.text = "FPS: %d" % Engine.get_frames_per_second()


func _on_toggle_pressed() -> void:
	DebugManager.toggle_panel()
	panel.visible = DebugManager.panel_open


func _on_god_toggled(on: bool) -> void:
	DebugManager.god_mode = on


func _on_add_coins_pressed() -> void:
	GameManager.add_coins(100)


func _on_add_crystals_pressed() -> void:
	GameManager.add_crystals(10)


func _on_add_powerups_pressed() -> void:
	for pu_id in PowerUpData.get_all_ids():
		GameManager.add_power_up(pu_id, 5)


func _on_reset_missions_pressed() -> void:
	GameManager.active_missions.clear()
	GameManager.completed_mission_ids.clear()
	GameManager.save_game()
	MissionManager._ensure_missions()


func _on_reset_ach_pressed() -> void:
	GameManager.completed_achievements.clear()
	GameManager.save_game()


func _on_unlock_all_pressed() -> void:
	for skin_id in GameManager.get_all_skins():
		if skin_id not in GameManager.unlocked_skins:
			GameManager.unlocked_skins.append(skin_id)
	for theme_id in GameManager.THEMES:
		if theme_id not in GameManager.unlocked_themes:
			GameManager.unlocked_themes.append(theme_id)
	GameManager.save_game()


func _on_complete_puzzles_pressed() -> void:
	var dir := DirAccess.open("res://assets/sprites/puzzle/")
	if dir:
		dir.list_dir_begin()
		var folder := dir.get_next()
		while folder != "":
			if dir.current_is_dir() and folder.begins_with("puzzle_"):
				GameManager.complete_puzzle(folder)
			folder = dir.get_next()


func _on_reset_save_pressed() -> void:
	GameManager.reset_save()
