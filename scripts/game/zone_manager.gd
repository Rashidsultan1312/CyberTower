class_name ZoneManager

const ZONES := [
	{
		"name": "LOW CITY",
		"start": 0, "end": 14,
		"speed_inc": 6.0,
		"start_width": 300.0,
		"tint": Color(0.0, 0.8, 1.0, 0.15),
		"special": "",
	},
	{
		"name": "NEON DISTRICT",
		"start": 15, "end": 29,
		"speed_inc": 7.0,
		"start_width": 300.0,
		"tint": Color(1.0, 0.2, 0.8, 0.15),
		"special": "glitch",
	},
	{
		"name": "CHROME BRIDGE",
		"start": 30, "end": 49,
		"speed_inc": 8.0,
		"start_width": 280.0,
		"tint": Color(0.7, 0.7, 0.8, 0.15),
		"special": "",
	},
	{
		"name": "MEGACORP",
		"start": 50, "end": 74,
		"speed_inc": 9.0,
		"start_width": 280.0,
		"tint": Color(1.0, 0.6, 0.0, 0.15),
		"special": "speed_burst",
	},
	{
		"name": "ORBIT",
		"start": 75, "end": 99,
		"speed_inc": 10.0,
		"start_width": 280.0,
		"tint": Color(0.3, 0.0, 1.0, 0.15),
		"special": "invisible",
	},
	{
		"name": "MATRIX",
		"start": 100, "end": 9999,
		"speed_inc": 10.0,
		"start_width": 280.0,
		"tint": Color(0.0, 1.0, 0.3, 0.15),
		"special": "random",
	},
]

const MAX_SPEED := 650.0


static func get_zone_index(score: int) -> int:
	for i in range(ZONES.size() - 1, -1, -1):
		if score >= ZONES[i].start:
			return i
	return 0


static func get_zone(score: int) -> Dictionary:
	return ZONES[get_zone_index(score)]


static func get_speed_increment(score: int) -> float:
	return get_zone(score).speed_inc


static func get_special(score: int) -> String:
	var zone: Dictionary = get_zone(score)
	if zone.special == "random":
		var specials := ["glitch", "speed_burst", "invisible", ""]
		return specials[randi() % specials.size()]
	return zone.special
