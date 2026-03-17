extends Node

signal mission_completed(mission: Dictionary)
signal missions_updated

const MAX_ACTIVE := 3

const MISSION_POOL := [
	{"id": "score_30", "desc": "Score 30 points", "type": "score", "target": 30, "reward_coins": 30, "reward_crystals": 0, "reward_pu": ""},
	{"id": "score_50", "desc": "Score 50 points", "type": "score", "target": 50, "reward_coins": 50, "reward_crystals": 0, "reward_pu": ""},
	{"id": "score_100", "desc": "Score 100 points", "type": "score", "target": 100, "reward_coins": 80, "reward_crystals": 1, "reward_pu": ""},
	{"id": "perfects_3", "desc": "3 perfects in a row", "type": "combo", "target": 3, "reward_coins": 30, "reward_crystals": 0, "reward_pu": ""},
	{"id": "perfects_5", "desc": "5 perfects in a row", "type": "combo", "target": 5, "reward_coins": 0, "reward_crystals": 1, "reward_pu": ""},
	{"id": "perfects_10", "desc": "10 perfects in a row", "type": "combo", "target": 10, "reward_coins": 0, "reward_crystals": 2, "reward_pu": ""},
	{"id": "zone_2", "desc": "Reach Neon District", "type": "zone", "target": 1, "reward_coins": 30, "reward_crystals": 0, "reward_pu": ""},
	{"id": "zone_3", "desc": "Reach Chrome Bridge", "type": "zone", "target": 2, "reward_coins": 30, "reward_crystals": 0, "reward_pu": "shield"},
	{"id": "zone_4", "desc": "Reach Megacorp", "type": "zone", "target": 3, "reward_coins": 50, "reward_crystals": 1, "reward_pu": ""},
	{"id": "play_3", "desc": "Play 3 games", "type": "games", "target": 3, "reward_coins": 40, "reward_crystals": 0, "reward_pu": ""},
	{"id": "play_5", "desc": "Play 5 games", "type": "games", "target": 5, "reward_coins": 60, "reward_crystals": 0, "reward_pu": ""},
	{"id": "coins_100", "desc": "Earn 100 coins", "type": "coins", "target": 100, "reward_coins": 50, "reward_crystals": 0, "reward_pu": ""},
	{"id": "use_pu", "desc": "Use a powerup", "type": "use_powerup", "target": 1, "reward_coins": 20, "reward_crystals": 0, "reward_pu": "slowdown"},
	{"id": "total_perfects_20", "desc": "Get 20 perfects", "type": "total_perfects", "target": 20, "reward_coins": 0, "reward_crystals": 1, "reward_pu": ""},
	{"id": "total_perfects_50", "desc": "Get 50 perfects", "type": "total_perfects", "target": 50, "reward_coins": 0, "reward_crystals": 2, "reward_pu": ""},
]

var _session_coins := 0
var _session_games_start := 0
var _session_perfects_start := 0


func _ready() -> void:
	GameManager.block_placed.connect(_on_block_placed)
	GameManager.game_ended.connect(_on_game_ended)
	GameManager.zone_reached.connect(_on_zone_reached)
	_ensure_missions()


func _ensure_missions() -> void:
	while GameManager.active_missions.size() < MAX_ACTIVE:
		var new_m: Dictionary = _pick_new_mission()
		if new_m.is_empty():
			break
		GameManager.active_missions.append({"id": new_m.id, "progress": 0})
	GameManager.save_game()


func _pick_new_mission() -> Dictionary:
	var active_ids: Array[String] = []
	for m in GameManager.active_missions:
		active_ids.append(m.id)
	var available: Array[Dictionary] = []
	for m in MISSION_POOL:
		if m.id not in active_ids and m.id not in GameManager.completed_mission_ids:
			available.append(m)
	if available.is_empty():
		GameManager.completed_mission_ids.clear()
		for m in MISSION_POOL:
			if m.id not in active_ids:
				available.append(m)
	if available.is_empty():
		return {}
	return available[randi() % available.size()]


func _get_pool_mission(mission_id: String) -> Dictionary:
	for m in MISSION_POOL:
		if m.id == mission_id:
			return m
	return {}


func _on_block_placed(score: int, combo: int, _is_perfect: bool) -> void:
	_check_progress("score", score)
	_check_progress("combo", combo)


func _on_game_ended(score: int, coins: int, _zone: int) -> void:
	_session_coins += coins
	_check_progress("games", GameManager.games_played)
	_check_progress("coins", _session_coins)
	_check_progress("total_perfects", GameManager.total_perfects)


func _on_zone_reached(zone_idx: int) -> void:
	_check_progress("zone", zone_idx)


func _check_progress(type: String, value: int) -> void:
	var completed_any := false
	for i in range(GameManager.active_missions.size() - 1, -1, -1):
		var m: Dictionary = GameManager.active_missions[i]
		var pool_m: Dictionary = _get_pool_mission(m.id)
		if pool_m.is_empty() or pool_m.type != type:
			continue
		m.progress = maxi(m.progress, value)
		if m.progress >= pool_m.target:
			_complete_mission(i, pool_m)
			completed_any = true

	if completed_any:
		_ensure_missions()
		missions_updated.emit()


func _complete_mission(idx: int, pool_m: Dictionary) -> void:
	var m: Dictionary = GameManager.active_missions[idx]
	GameManager.completed_mission_ids.append(m.id)
	GameManager.active_missions.remove_at(idx)

	if pool_m.reward_coins > 0:
		GameManager.add_coins(pool_m.reward_coins)
	if pool_m.reward_crystals > 0:
		GameManager.add_crystals(pool_m.reward_crystals)
	if pool_m.reward_pu != "":
		GameManager.add_power_up(pool_m.reward_pu)

	mission_completed.emit(pool_m)


func get_active_with_pool() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for m in GameManager.active_missions:
		var pool_m: Dictionary = _get_pool_mission(m.id)
		if not pool_m.is_empty():
			var entry := pool_m.duplicate()
			entry["progress"] = m.progress
			result.append(entry)
	return result
