extends Node

## Manages all audio playback in the game including SFX, music, and ambience.
##
## Uses object pooling for 2d audio players to avoid excessive node creation.
## Connects to EventBus for gameplay-triggered sounds (item pickups, keypad presses, etc).

@export_group("Logging")
## Enable logging for this system
@export var enable_logging: bool = true
## Enable logging for child nodes
@export var enable_children_logging: bool = true
var _log_category: String = "AudioManager"

# Volume controls (0.0 to 1.0)
var _master_volume: float = 1.0
var _sfx_volume: float = 1.0
var _music_volume: float = 1.0
var _ambience_volume: float = 1.0

# Audio player pools
var _2d_audio_pool: Array[AudioStreamPlayer2D] = []
var _active_2d_players: Array[AudioStreamPlayer2D] = []
var _2d_audio_player: AudioStreamPlayer
var _music_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer

# Pool configuration
const MAX_2D_POOL_SIZE = 10
const POOL_INITIAL_SIZE = 3

func _ready() -> void:
	initialize()

func initialize() -> void:
	_setup_audio_players()
	_initialize_2d_pool()
	_connect_to_eventbus()

func _connect_to_eventbus() -> void:
	print_debug("AudioManager Connecting to EventBus..")
	EventBus.play_dial_click.connect(_on_play_dial_click)
	EventBus.play_success_sound.connect(_on_play_success_sound)

func _setup_audio_players() -> void:
	# Create 2D audio players
	_2d_audio_player = AudioStreamPlayer.new()
	_2d_audio_player.name = "SFX_2D_Player"
	add_child(_2d_audio_player)

	_music_player = AudioStreamPlayer.new()
	_music_player.name = "Music_Player"
	add_child(_music_player)

	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.name = "Ambience_Player"
	add_child(_ambience_player)

func _initialize_2d_pool() -> void:
	# Pre-create initial pool of 2D audio players
	for i in range(POOL_INITIAL_SIZE):
		var player = _create_2d_player()
		_2d_audio_pool.append(player)

func _create_2d_player() -> AudioStreamPlayer2D:
	var player = AudioStreamPlayer2D.new()
	player.name = "SFX_2D_Player_Pool"
	add_child(player)
	player.finished.connect(_on_2d_player_finished.bind(player))
	return player

func _on_2d_player_finished(player: AudioStreamPlayer2D) -> void:
	_return_2d_player(player)

# Volume control methods
func set_master_volume(volume: float) -> void:
	_master_volume = clampf(volume, 0.0, 1.0)
	_update_all_volumes()

func get_master_volume() -> float:
	return _master_volume

func set_sfx_volume(volume: float) -> void:
	_sfx_volume = clampf(volume, 0.0, 1.0)
	_update_sfx_volumes()

func get_sfx_volume() -> float:
	return _sfx_volume

func set_music_volume(volume: float) -> void:
	_music_volume = clampf(volume, 0.0, 1.0)
	_update_music_volume()

func get_music_volume() -> float:
	return _music_volume

func set_ambience_volume(volume: float) -> void:
	_ambience_volume = clampf(volume, 0.0, 1.0)
	_update_ambience_volume()

func get_ambience_volume() -> float:
	return _ambience_volume

func _update_all_volumes() -> void:
	_update_sfx_volumes()
	_update_music_volume()
	_update_ambience_volume()

func _update_sfx_volumes() -> void:
	var final_volume = _master_volume * _sfx_volume
	_2d_audio_player.volume_db = linear_to_db(final_volume)

	# Update all active 2D players
	for player in _active_2d_players:
		player.volume_db = linear_to_db(final_volume)

	# Update pool players
	for player in _2d_audio_pool:
		player.volume_db = linear_to_db(final_volume)

func _update_music_volume() -> void:
	var final_volume = _master_volume * _music_volume
	_music_player.volume_db = linear_to_db(final_volume)

func _update_ambience_volume() -> void:
	var final_volume = _master_volume * _ambience_volume
	_ambience_player.volume_db = linear_to_db(final_volume)

# Audio playback methods
func play_sfx_2d(stream: AudioStream, pitch_scale: float = 1.0) -> void:
	var player = _get_available_2d_player()
	if player:
		player.stream = stream
		player.pitch_scale = pitch_scale
		player.play()

func play_music(stream: AudioStream, fade_in: bool = false) -> void:
	_music_player.stream = stream
	_music_player.play()

func play_ambience(stream: AudioStream, fade_in: bool = false) -> void:
	_ambience_player.stream = stream
	_ambience_player.play()

# Audio player pool management
func _get_available_2d_player() -> AudioStreamPlayer2D:
	var player: AudioStreamPlayer2D

	if _2d_audio_pool.size() > 0:
		player = _2d_audio_pool.pop_back()
	elif _active_2d_players.size() < MAX_2D_POOL_SIZE:
		player = _create_2d_player()
	else:
		# Pool exhausted, reuse oldest active player
		player = _active_2d_players[0]
		_active_2d_players.erase(player)
		player.stop()

	_active_2d_players.append(player)
	# Update volume for this player
	var final_volume = _master_volume * _sfx_volume
	player.volume_db = linear_to_db(final_volume)

	return player

func _return_2d_player(player: AudioStreamPlayer2D) -> void:
	if player in _active_2d_players:
		_active_2d_players.erase(player)
		player.stream = null
		_2d_audio_pool.append(player)

func _on_play_dial_click() -> void:
	# Calculate pitch scale
	var pitch_scale := randf_range(0.8, 0.7)
	var dialStream = load(GameEnums.DIAL_CLICK)
	set_sfx_volume(0.5)
	play_sfx_2d(dialStream, pitch_scale)

func _on_play_success_sound(success) -> void:
	var successStream = load(GameEnums.SUCCESS)
	var failStream = load(GameEnums.FAILURE)
	var streamToPlay = successStream if success else failStream
	play_sfx_2d(streamToPlay)
