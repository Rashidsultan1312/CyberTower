extends Node

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_cache := {}
const MAX_SFX := 8


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)
	for i in MAX_SFX:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_players.append(p)
	call_deferred("apply_volumes")


func play_sfx(path: String) -> void:
	if not GameManager.settings.sound:
		return
	var stream: AudioStream = _sfx_cache.get(path)
	if not stream:
		if not ResourceLoader.exists(path):
			return
		stream = load(path)
		_sfx_cache[path] = stream
	for p in _sfx_players:
		if not p.playing:
			p.stream = stream
			p.play()
			return


func play_music(path: String) -> void:
	if not GameManager.settings.music:
		_music_player.stop()
		return
	if not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path)
	if _music_player.stream == stream and _music_player.playing:
		return
	if stream is AudioStreamMP3:
		stream.loop = true
	elif stream is AudioStreamOggVorbis:
		stream.loop = true
	_music_player.stream = stream
	_music_player.play()


func stop_music() -> void:
	_music_player.stop()


func update_music_state() -> void:
	if not GameManager.settings.music:
		_music_player.stop()
	elif _music_player.stream and not _music_player.playing:
		_music_player.play()


func update_sfx_state() -> void:
	if not GameManager.settings.sound:
		for p in _sfx_players:
			p.stop()


func set_sfx_volume(vol: float) -> void:
	var bus_idx := AudioServer.get_bus_index("SFX")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(vol))


func set_music_volume(vol: float) -> void:
	var bus_idx := AudioServer.get_bus_index("Music")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(vol))


func apply_volumes() -> void:
	set_sfx_volume(GameManager.settings.sfx_volume)
	set_music_volume(GameManager.settings.music_volume)
