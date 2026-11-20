extends Node

const SOUNDS := {
	"hover": preload("res://Sounds/UI/hover.ogg"),
	"click": preload("res://Sounds/UI/click.ogg"),
	"tab": preload("res://Sounds/UI/tab.ogg"),
	"buy": preload("res://Sounds/UI/buy.ogg"),
	"error": preload("res://Sounds/UI/error.ogg"),
	"start": preload("res://Sounds/UI/start.ogg"),
}

const VOLUMES := {
	"hover": -8.0,
	"tab": -6.0,
}

const PITCHES := {
	"hover": 0.85,
}

const MENU_MUSIC := preload("res://Sounds/Music/menu_music.mp3")
const MUSIC_VOLUME := -14.0
const MUSIC_FADE_TIME := 0.5

const HOVER_BUS := "UI Hover"
const HOVER_CUTOFF_HZ := 1200.0
const PLAYER_COUNT := 8

var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0
var _music_player: AudioStreamPlayer
var _music_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_add_hover_bus()

	for i in PLAYER_COUNT:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)

	_music_player = AudioStreamPlayer.new()
	_music_player.stream = MENU_MUSIC
	add_child(_music_player)

	get_tree().node_added.connect(_on_node_added)
	_hook_up_existing(get_tree().root)

func play(sound_name: String, pitch_variation: float = 0.0) -> void:
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % PLAYER_COUNT

	player.stream = SOUNDS[sound_name]
	player.volume_db = VOLUMES.get(sound_name, 0.0)
	player.pitch_scale = PITCHES.get(sound_name, 1.0) + randf_range(-pitch_variation, pitch_variation)
	player.bus = HOVER_BUS if sound_name == "hover" else "Master"
	player.play()

func play_music() -> void:
	_kill_music_tween()
	if not _music_player.playing:
		_music_player.volume_db = -60.0
		_music_player.play()
	_music_tween = create_tween()
	_music_tween.tween_property(_music_player, "volume_db", MUSIC_VOLUME, MUSIC_FADE_TIME)

func stop_music() -> void:
	_kill_music_tween()
	_music_tween = create_tween()
	_music_tween.tween_property(_music_player, "volume_db", -60.0, MUSIC_FADE_TIME)
	_music_tween.tween_callback(_music_player.stop)

func _kill_music_tween() -> void:
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()

func _add_hover_bus() -> void:
	AudioServer.add_bus()
	var bus_index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus_index, HOVER_BUS)
	AudioServer.set_bus_send(bus_index, "Master")

	var low_pass := AudioEffectLowPassFilter.new()
	low_pass.cutoff_hz = HOVER_CUTOFF_HZ
	AudioServer.add_bus_effect(bus_index, low_pass)

func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		node.mouse_entered.connect(_on_button_hovered.bind(node))
		node.pressed.connect(_on_button_pressed.bind(node))

func _hook_up_existing(node: Node) -> void:
	_on_node_added(node)
	for child in node.get_children():
		_hook_up_existing(child)

func _on_button_hovered(button: BaseButton) -> void:
	if button.disabled or not button.get_meta("ui_hover_sound", true):
		return
	play("hover", 0.05)

func _on_button_pressed(button: BaseButton) -> void:
	var sound_name: String = button.get_meta("ui_sound", "click")
	if sound_name != "":
		play(sound_name)
