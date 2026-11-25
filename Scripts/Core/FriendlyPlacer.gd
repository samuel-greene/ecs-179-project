extends Node2D

const FRIENDLY_V1 = preload("res://Scenes/Friendlies/Friend_v1.tscn")

var number_friendlies := 0
var placing := false
var preview: Node2D

@onready var friendly_counter = $"../FriendlyCounter"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	start_placing()

func start_placing() -> void:
	number_friendlies = GameData.friendly_count
	friendly_counter.show()
	friendly_counter.text = "Friendlies Remaining: " + str(number_friendlies)
	
	if number_friendlies <= 0:
		return
	
	get_tree().paused = true
	placing = true
	
	create_preview()
	

func _process(_delta: float) -> void:
	if placing and is_instance_valid(preview):
		preview.global_position = get_global_mouse_position()
		
	
func _input(event: InputEvent) -> void:
	if not placing:
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			place_friendly()
			UISounds.play("friendly_spawn", 0.05)
			

func place_friendly() -> void:
	var friendly = FRIENDLY_V1.instantiate()
	
	get_tree().current_scene.add_child(friendly)
	friendly.global_position = get_global_mouse_position()
	
	number_friendlies = number_friendlies - 1
	friendly_counter.text = "Friendlies Remaining: " + str(number_friendlies)
	
	if number_friendlies > 0:
		preview.queue_free()
		create_preview()
	else:
		placing = false
		preview.queue_free()
		preview = null
		get_tree().paused = false
		friendly_counter.hide()
		
func create_preview() -> void:
	preview = FRIENDLY_V1.instantiate()
	preview.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(preview)
	
	preview.modulate.a = 0.5
	
