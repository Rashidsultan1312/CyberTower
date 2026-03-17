class_name PowerUpData

const ALL := {
	"slowdown": {
		"name": "Slowdown",
		"desc": "Speed 40% for 5s",
		"type": "manual",
		"price": 30,
		"icon_path": "res://assets/sprites/ui/slowdown.png",
		"color": Color(0.3, 0.8, 1),
	},
	"widen": {
		"name": "Widener",
		"desc": "+60px block width",
		"type": "manual",
		"price": 50,
		"icon_path": "res://assets/sprites/ui/widen.png",
		"color": Color(0.2, 1, 0.4),
	},
	"shield": {
		"name": "Shield",
		"desc": "Survives 1 miss",
		"type": "auto",
		"price": 40,
		"icon_path": "res://assets/sprites/ui/shield.png",
		"color": Color(1, 0.8, 0.2),
	},
	"magnet": {
		"name": "Magnet",
		"desc": "3 auto-perfects",
		"type": "manual",
		"price": 80,
		"icon_path": "res://assets/sprites/ui/magnet.png",
		"color": Color(1, 0.3, 0.5),
	},
	"x2coins": {
		"name": "x2 Coins",
		"desc": "Double coins per game",
		"type": "passive",
		"price": 60,
		"icon_path": "res://assets/sprites/ui/x2coins.png",
		"color": Color(1, 0.85, 0),
	},
}


static func info(pu_id: String) -> Dictionary:
	return ALL.get(pu_id, {})


static func get_all_ids() -> Array:
	return ALL.keys()
