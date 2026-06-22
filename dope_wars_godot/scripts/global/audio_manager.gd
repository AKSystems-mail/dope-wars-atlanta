extends Node
## Audio manager autoload singleton.
## Handles SFX and music with preloaded cache.

var sfx_cache: Dictionary = {}
var music_player: AudioStreamPlayer

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -12
	add_child(music_player)

func preload_sfx(key: String, path: String) -> void:
	var stream := load(path) as AudioStream
	if stream:
		sfx_cache[key] = stream

func play_sfx(key: String) -> void:
	if not sfx_cache.has(key):
		return
	var player := AudioStreamPlayer2D.new()
	player.stream = sfx_cache[key]
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()

func play_music(stream: AudioStream, volume_db: float = -12) -> void:
	music_player.stop()
	music_player.stream = stream
	music_player.volume_db = volume_db
	music_player.play()

func stop_music() -> void:
	music_player.stop()
