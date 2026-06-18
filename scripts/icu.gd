extends Node3D

@export var msgs: VBoxContainer
@export var monitor_box: VBoxContainer

var scenario_data: Dictionary
var current_node_id: String
var current_score: int
var vitals: Dictionary
var flags: Dictionary

func goto_node(node_id: String) -> void:
	current_node_id = node_id
	var active_node: Dictionary = {}
	
	for node in scenario_data["nodes"]:
		if node["id"] == node_id:
			active_node = node
			break
	
	if active_node.is_empty():
		print("Critical: No starting node in json")
		return
	
	msgs.add_msg(active_node["text"], Message.MsgType.STEP)
		
	if active_node["type"] == "message":
		if "next_node_id" in active_node:
			goto_node(active_node["next_node_id"])
		
	elif active_node["type"] == "decision":
		if "time_limit_seconds" in active_node:
			handle_node_timeout(active_node)
			
func _on_hotspot_cliked(hotspot_id: String) -> void:
	var active_node: Dictionary = {}
	
	for node in scenario_data["nodes"]:
		if node["id"] == current_node_id:
			active_node = node
			break
	
	if active_node.is_empty() or active_node["type"] != "decision":
		return
		
	for option in active_node["options"]:
		if option["target_hotspot"] == hotspot_id:
			var effects = option["effects"]
			
			if "score_delta" in effects:
				current_score += effects["score_delta"]
				
			if "vitals_update" in effects:
				for key in effects["vitals_update"]:
					if key in vitals:
						vitals[key] = effects["vitals_update"][key]
				print_monitor()
				
			if "toast" in effects:
				msgs.add_msg(effects["toast"], Message.MsgType.TOAST)
				
			goto_node(option["next_node_id"])
			return
			
	msgs.add_msg("Άκυρη ενέργεια! Αυτό το αντικείμενο δεν βοηθάει αυτή τη στιγμή.", Message.MsgType.WARNING)
	

func handle_node_timeout(active_node: Dictionary):
	pass

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
	msgs.add_msg("Φόρτωση σεναρίου: " + scenario_data["scenario_meta"]["id"], Message.MsgType.SYSTEM)
	msgs.add_msg("Τίτλος: " + scenario_data["scenario_meta"]["title"], Message.MsgType.SYSTEM)
	msgs.add_msg("Περιγραφή: " + scenario_data["scenario_meta"]["description"], Message.MsgType.SYSTEM)
	msgs.add_msg("Δυσκολία: " + scenario_data["scenario_meta"]["difficulty"], Message.MsgType.SYSTEM)
	msgs.add_msg("Διάρκεια: " + str(scenario_data["scenario_meta"]["estimated_duration_minutes"]) + " min", Message.MsgType.SYSTEM)
	msgs.add_msg("Η προσομόιωση θα ξεκινήσει σε 10 δευτερόλεπτα", Message.MsgType.SYSTEM)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if SignalBus.has_signal("hotspot_clicked"):
		SignalBus.hotspot_clicked.connect(_on_hotspot_cliked)
	
	load_from_json()
	print_scenario_info()
	print_monitor()
	await get_tree().create_timer(10).timeout
	goto_node("n1_start")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
