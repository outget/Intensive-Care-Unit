extends Node3D

@export var msgs: VBoxContainer
var scenario_data: Dictionary
var current_node_id: String
var current_score: int
var vitals: Dictionary
var flags: Dictionary

func load_from_json():
	var file = FileAccess.open("res://json/scenario.json", FileAccess.READ)
	var content = file.get_as_text()
	var json = JSON.new()
	
	var error = json.parse(content)
	
	if error == OK:
		scenario_data = json.data
	
	if scenario_data:
		current_score = scenario_data["initial_state"]["current_score"]
		vitals = scenario_data["initial_state"]["vitals"]
		flags = scenario_data["initial_state"]["flags"]
		

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_from_json()
	await get_tree().create_timer(1).timeout
	msgs.add_msg("test", Message.MsgType.SYSTEM)
	await get_tree().create_timer(1).timeout
	msgs.add_msg("test", Message.MsgType.STEP)	
	await get_tree().create_timer(1).timeout
	msgs.add_msg("test", Message.MsgType.WARNING)
	await get_tree().create_timer(1).timeout	
	msgs.add_msg("test", Message.MsgType.SUCCESS)	
	await get_tree().create_timer(1).timeout
	msgs.add_msg("test", Message.MsgType.TOAST)	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
