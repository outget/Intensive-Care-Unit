extends Node3D

@export var msgs: VBoxContainer
@export var monitor_box: VBoxContainer

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

func print_monitor() -> void:
	monitor_box.find_child("HR").text = "HR: " + str(vitals["hr"])
	monitor_box.find_child("SPO2").text = "SpO2: " + str(vitals["spo2"])
	monitor_box.find_child("RR").text = "Resp. rate: " + str(vitals["rr"])
	monitor_box.find_child("BP").text ="BP: " + str(vitals["bp"])
	monitor_box.find_child("TEMP").text = "Temp: " + str(vitals["temp"])

func print_scenario_info() -> void:
	await get_tree().create_timer(0.2).timeout
	msgs.add_msg("Loaded scenario: " + scenario_data["scenario_meta"]["id"], Message.MsgType.SYSTEM)
	msgs.add_msg("Title: " + scenario_data["scenario_meta"]["title"], Message.MsgType.SYSTEM)
	msgs.add_msg("Description: " + scenario_data["scenario_meta"]["description"], Message.MsgType.SYSTEM)
	msgs.add_msg("Difficulty: " + scenario_data["scenario_meta"]["difficulty"], Message.MsgType.SYSTEM)
	msgs.add_msg("Duration: " + str(scenario_data["scenario_meta"]["estimated_duration_minutes"]) + " min", Message.MsgType.SYSTEM)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_from_json()
	print_scenario_info()
	print_monitor()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
