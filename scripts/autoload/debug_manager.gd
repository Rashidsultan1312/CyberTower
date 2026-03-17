extends Node

var god_mode := false
var panel_open := false
var _panel: Node


func _ready() -> void:
	if not OS.is_debug_build():
		return
	var scene := load("res://scenes/overlays/debug_panel.tscn")
	if scene:
		_panel = scene.instantiate()
		add_child(_panel)


func toggle_panel() -> void:
	panel_open = not panel_open
	if _panel:
		_panel.visible = panel_open
