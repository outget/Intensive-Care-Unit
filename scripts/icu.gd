extends Node3D

@export var msgs: VBoxContainer
@export var monitor_box: VBoxContainer
@export var monitor_hotspot: Node
@export var ehr_panel: Node
@export var debrief_panel: Node

var scenario_data: Dictionary
var current_node_id: String
var current_score: int
var vitals: Dictionary
var flags: Dictionary

var ehr_data: Dictionary = { }
var vitals_history: Array = []
var action_log: Array = []
var _last_report: Dictionary = { }

var _node_generation: int = 0
var _active_global_rules: Dictionary = { }
var _log_events: Array = []
var _start_ticks: int = 0
# Highest score reachable (initial + best choice at every decision + every gate).
var _max_score: int = 100


func _log(event: String, data: Dictionary = { }) -> void:
	if not _log_events.is_empty() and not _log_events.has(event):
		return
	action_log.append(
		{
			"t": (Time.get_ticks_msec() - _start_ticks) / 1000.0,
			"event": event,
			"node": current_node_id,
			"data": data,
		},
	)


func goto_node(node_id: String) -> void:
	current_node_id = node_id
	_node_generation += 1

	var active_node := _find_node(node_id)
	if active_node.is_empty():
		push_error("Critical: node '%s' not found in scenario" % node_id)
		return

	_log("NODE_ENTER", { "type": active_node.get("type", "") })
	msgs.add_msg(active_node["text"], Message.MsgType.STEP)

	match active_node["type"]:
		"message":
			if "next_node_id" in active_node:
				goto_node(active_node["next_node_id"])
		"decision":
			if "timeout" in active_node:
				_start_timeout(active_node, _node_generation)
		"gate":
			_enter_gate(active_node)
		"end":
			_run_debrief(active_node)


func _find_node(node_id: String) -> Dictionary:
	for node in scenario_data.get("nodes", []):
		if node["id"] == node_id:
			return node
	return { }


func _on_hotspot_cliked(hotspot_id: String) -> void:
	_log("HOTSPOT_INTERACTION", { "hotspot": hotspot_id })

	var active_node := _find_node(current_node_id)
	if active_node.is_empty() or active_node["type"] != "decision":
		return

	for option in active_node["options"]:
		if option["target_hotspot"] == hotspot_id:
			_log("OPTION_SELECTED", { "option": option.get("id", ""), "label": option.get("label", "") })
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
		_record_vitals()
		_evaluate_global_rules()

	if "toast" in effects:
		msgs.add_msg(effects["toast"], Message.MsgType.TOAST)


func _enter_gate(node: Dictionary) -> void:
	if "description" in node:
		msgs.add_msg(node["description"], Message.MsgType.SYSTEM)
	if not _try_pass_gate(node) and "feedback_blocked" in node:
		msgs.add_msg(node["feedback_blocked"], Message.MsgType.WARNING)


func _try_pass_gate(node: Dictionary) -> bool:
	var reqs: Dictionary = node.get("gate_requirements", { })
	if not ehr_has_fields(reqs.get("required_forms", [])):
		return false
	if "feedback_success" in node:
		msgs.add_msg(node["feedback_success"], Message.MsgType.SUCCESS)
	_apply_effects(node.get("effects_on_pass", { }))
	_node_generation += 1
	goto_node(node["next_node_id"])
	return true


func ehr_has_fields(required_forms: Array) -> bool:
	for req in required_forms:
		var form_id: String = req["form_id"]
		for field in req["fields"]:
			if not ehr_data.has(form_id) \
					or not ehr_data[form_id].has(field) \
					or str(ehr_data[form_id][field]).strip_edges() == "":
				return false
	return true


func _on_ehr_updated(new_data: Dictionary) -> void:
	for form_id in new_data:
		for field in new_data[form_id]:
			if not ehr_data.has(form_id):
				ehr_data[form_id] = { }
			ehr_data[form_id][field] = new_data[form_id][field]
	_log("EHR_SUBMIT", { "data": new_data })
	msgs.add_msg("Καταχώρηση στο EHR.", Message.MsgType.SYSTEM)

	var node := _find_node(current_node_id)
	if not node.is_empty() and node.get("type") == "gate":
		_try_pass_gate(node)


func _record_vitals() -> void:
	vitals_history.append(vitals.duplicate())
	_log("VITALS_CHANGE", { "vitals": vitals.duplicate() })
	if ehr_panel and ehr_panel.has_method("update_vitals"):
		ehr_panel.update_vitals(vitals, vitals_history)


func _start_timeout(active_node: Dictionary, generation: int) -> void:
	var timeout: Dictionary = active_node["timeout"]
	await get_tree().create_timer(float(timeout["seconds"])).timeout

	if generation != _node_generation:
		return

	_log("TIMEOUT", { })
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

	var missed: Array = []
	for flag_name in flags:
		if not flags[flag_name]:
			missed.append(flag_name)

	var decision_path: Array = []
	for entry in action_log:
		if entry["event"] == "OPTION_SELECTED":
			var d: Dictionary = entry["data"]
			decision_path.append(d.get("label", d.get("option", "")))

	var score_pct := clampi(roundi(100.0 * current_score / _max_score), 0, 100)

	_last_report = {
		"scenario_id": scenario_data.get("scenario_meta", { }).get("id", ""),
		"score": score_pct,
		"score_raw": current_score,
		"score_max": _max_score,
		"flags": flags,
		"missed_documentation": missed,
		"decision_path": decision_path,
		"ehr_data": ehr_data,
		"vitals_history": vitals_history,
		"action_log": action_log,
	}

	if cfg.get("export_log", false):
		_export_report()

	if debrief_panel and debrief_panel.has_method("show_report"):
		debrief_panel.show_report(_last_report, cfg)
	else:
		msgs.add_msg("Τελικό σκορ: %d / 100" % score_pct, Message.MsgType.SYSTEM)
		if missed.is_empty():
			msgs.add_msg("Όλα τα βήματα τεκμηρίωσης ολοκληρώθηκαν.", Message.MsgType.SUCCESS)
		else:
			msgs.add_msg("Παραλείψεις τεκμηρίωσης: " + ", ".join(missed), Message.MsgType.WARNING)


func _export_report() -> void:
	if _last_report.is_empty():
		return

	var stamp := Time.get_datetime_string_from_system().replace(":", "-")
	var base := "user://debrief_%s" % stamp

	var jf := FileAccess.open(base + ".json", FileAccess.WRITE)
	if jf:
		jf.store_string(JSON.stringify(_last_report, "\t"))
		jf.close()

	var cf := FileAccess.open(base + ".csv", FileAccess.WRITE)
	if cf:
		cf.store_line("t,event,node,data")
		for e in action_log:
			var flat := JSON.stringify(e["data"]).replace(",", ";").replace("\"", "'")
			cf.store_line("%s,%s,%s,%s" % [e["t"], e["event"], e["node"], flat])
		cf.close()

	msgs.add_msg("Ημερολόγιο: " + ProjectSettings.globalize_path(base + ".json"), Message.MsgType.SYSTEM)


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
	_log_events = scenario_data.get("logging", { }).get("log_events", [])
	_max_score = _compute_max_score()


func _compute_max_score() -> int:
	var total := int(scenario_data["initial_state"].get("current_score", 100))
	for node in scenario_data.get("nodes", []):
		match node.get("type"):
			"decision":
				var best := 0
				for opt in node.get("options", []):
					best = max(best, int(opt.get("effects", { }).get("score_delta", 0)))
				total += best
			"gate":
				total += int(node.get("effects_on_pass", { }).get("score_delta", 0))
	return max(total, 1)


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

	if monitor_hotspot and monitor_hotspot.has_method("set_vitals"):
		monitor_hotspot.set_vitals(vitals)


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
	_start_ticks = Time.get_ticks_msec()

	if SignalBus.has_signal("hotspot_clicked"):
		SignalBus.hotspot_clicked.connect(_on_hotspot_cliked)
	SignalBus.ehr_updated.connect(_on_ehr_updated)
	if SignalBus.has_signal("debrief_export_requested"):
		SignalBus.debrief_export_requested.connect(_export_report)

	load_from_json()

	if ehr_panel and ehr_panel.has_method("setup"):
		ehr_panel.setup(scenario_data.get("ehr_config", { }))

	print_scenario_info()
	print_monitor()
	_record_vitals()
	_evaluate_global_rules()
	await get_tree().create_timer(10).timeout
	goto_node("n1_start")
