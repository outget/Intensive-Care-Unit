extends Node3D

@export var msgs: VBoxContainer
@export var monitor_box: VBoxContainer
@export var monitor_hotspot: Node

var scenario_data: Dictionary
var current_node_id: String
var current_score: int
var vitals: Dictionary
var flags: Dictionary

var _node_generation: int = 0
var _active_global_rules: Dictionary = { }


func goto_node(node_id: String) -> void:
	current_node_id = node_id
	_node_generation += 1

	var active_node := _find_node(node_id)
	if active_node.is_empty():
		push_error("Critical: node '%s' not found in scenario" % node_id)
		return

	msgs.add_msg(active_node["text"], Message.MsgType.STEP)

	match active_node["type"]:
		"message":
			if "next_node_id" in active_node:
				goto_node(active_node["next_node_id"])
		"decision":
			if "timeout" in active_node:
				_start_timeout(active_node, _node_generation)
		"gate":
			# Documentation gates are resolved through the EHR module (not implemented yet).
			if "description" in active_node:
				msgs.add_msg(active_node["description"], Message.MsgType.SYSTEM)
			if "feedback_blocked" in active_node:
				msgs.add_msg(active_node["feedback_blocked"], Message.MsgType.WARNING)
		"end":
			_run_debrief(active_node)


func _find_node(node_id: String) -> Dictionary:
	for node in scenario_data.get("nodes", []):
		if node["id"] == node_id:
			return node
	return { }


func _on_hotspot_cliked(hotspot_id: String) -> void:
	var active_node := _find_node(current_node_id)
	if active_node.is_empty() or active_node["type"] != "decision":
		return

	for option in active_node["options"]:
		if option["target_hotspot"] == hotspot_id:
			_apply_effects(option.get("effects", { }))
			_node_generation += 1 # cancels any pending timeout for this node
			goto_node(option["next_node_id"])
			return

	msgs.add_msg("Άκυρη ενέργεια! Αυτό το αντικείμενο δεν βοηθάει αυτή τη στιγμή.", Message.MsgType.WARNING)


func _apply_effects(effects: Dictionary) -> void:
	if "score_delta" in effects:
		current_score += int(effects["score_delta"])

	if "flag_to_toggle" in effects:
		flags[effects["flag_to_toggle"]] = true

	if "vitals_update" in effects:
		for key in effects["vitals_update"]:
			vitals[key] = effects["vitals_update"][key]
		print_monitor()
		_evaluate_global_rules()

	if "toast" in effects:
		msgs.add_msg(effects["toast"], Message.MsgType.TOAST)


func _start_timeout(active_node: Dictionary, generation: int) -> void:
	var timeout: Dictionary = active_node["timeout"]
	await get_tree().create_timer(float(timeout["seconds"])).timeout

	# The player already made a choice or the flow advanced elsewhere.
	if generation != _node_generation:
		return

	_apply_effects(timeout.get("on_timeout_effects", { }))
	goto_node(timeout["next_node_id"])


func _evaluate_global_rules() -> void:
	var global_rules: Array = scenario_data.get("rules", { }).get("global_rules", [])
	for rule in global_rules:
		var rule_id: String = rule["id"]
		var met := _condition_met(rule["condition"])

		if met and not _active_global_rules.has(rule_id):
			_active_global_rules[rule_id] = true
			_apply_rule_effects(rule["effects"], true)
		elif not met and _active_global_rules.has(rule_id):
			_active_global_rules.erase(rule_id)
			_apply_rule_effects(rule["effects"], false)


func _condition_met(condition: Dictionary) -> bool:
	var value = vitals.get(condition.get("target_vital", ""))
	if value == null:
		return false
	if "less_than" in condition:
		return float(value) < float(condition["less_than"])
	if "greater_than" in condition:
		return float(value) > float(condition["greater_than"])
	return false


func _apply_rule_effects(effects: Array, active: bool) -> void:
	for effect in effects:
		match effect["type"]:
			"ui_visual":
				if effect.get("target") == "hs_monitor" and monitor_hotspot and monitor_hotspot.has_method("set_alarm"):
					monitor_hotspot.set_alarm(active)
			"ui_toast":
				if active:
					msgs.add_msg(effect["message"], Message.MsgType.WARNING)


func _run_debrief(active_node: Dictionary) -> void:
	var cfg: Dictionary = active_node.get("debrief_config", { })
	if cfg.get("show_score", false):
		msgs.add_msg("Τελικό σκορ: %d / 100" % current_score, Message.MsgType.SYSTEM)
	if cfg.get("highlight_missed_docs", false):
		var missed: Array = []
		for flag_name in flags:
			if not flags[flag_name]:
				missed.append(flag_name)
		if missed.is_empty():
			msgs.add_msg("Όλα τα βήματα τεκμηρίωσης ολοκληρώθηκαν.", Message.MsgType.SUCCESS)
		else:
			msgs.add_msg("Παραλείψεις τεκμηρίωσης: " + ", ".join(missed), Message.MsgType.WARNING)


func load_from_json() -> void:
	var file := FileAccess.open("res://json/scenario.json", FileAccess.READ)
	if file == null:
		push_error("Could not open scenario JSON")
		return

	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("Scenario JSON parse error: %s (line %d)" % [json.get_error_message(), json.get_error_line()])
		return

	scenario_data = json.data
	var initial: Dictionary = scenario_data["initial_state"]
	current_score = int(initial["current_score"])
	vitals = initial["vitals"].duplicate()
	flags = initial["flags"].duplicate()


func _fmt_vital(value) -> String:
	if value is float and value == floor(value):
		return str(int(value))
	return str(value)


func print_monitor() -> void:
	monitor_box.find_child("HR").text = "HR: " + _fmt_vital(vitals["hr"])
	monitor_box.find_child("SPO2").text = "SpO2: " + _fmt_vital(vitals["spo2"])
	monitor_box.find_child("RR").text = "Resp. rate: " + _fmt_vital(vitals["rr"])
	monitor_box.find_child("BP").text = "BP: " + _fmt_vital(vitals["bp"])
	monitor_box.find_child("TEMP").text = "Temp: " + _fmt_vital(vitals["temp"])


func print_scenario_info() -> void:
	await get_tree().create_timer(0.2).timeout
	var meta: Dictionary = scenario_data["scenario_meta"]
	msgs.add_msg("Φόρτωση σεναρίου: " + str(meta["id"]), Message.MsgType.SYSTEM)
	msgs.add_msg("Τίτλος: " + str(meta["title"]), Message.MsgType.SYSTEM)
	msgs.add_msg("Περιγραφή: " + str(meta["description"]), Message.MsgType.SYSTEM)
	msgs.add_msg("Δυσκολία: " + str(meta["difficulty"]), Message.MsgType.SYSTEM)
	msgs.add_msg("Διάρκεια: " + str(meta["estimated_duration_minutes"]) + " min", Message.MsgType.SYSTEM)
	msgs.add_msg("Η προσομοίωση θα ξεκινήσει σε 10 δευτερόλεπτα", Message.MsgType.SYSTEM)


func _ready() -> void:
	if SignalBus.has_signal("hotspot_clicked"):
		SignalBus.hotspot_clicked.connect(_on_hotspot_cliked)

	load_from_json()
	print_scenario_info()
	print_monitor()
	_evaluate_global_rules()
	await get_tree().create_timer(10).timeout
	goto_node("n1_start")
