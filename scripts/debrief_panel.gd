extends CanvasLayer

@export var score_label: Label
@export var checklist: VBoxContainer
@export var path_list: VBoxContainer
@export var status_label: Label


func _ready() -> void:
	hide()
	status_label.text = ""


func show_report(report: Dictionary, cfg: Dictionary) -> void:
	score_label.visible = cfg.get("show_score", true)
	score_label.text = "Σκορ: %d / 100" % int(report.get("score", 0))

	for c in checklist.get_children():
		c.queue_free()
	var flags: Dictionary = report.get("flags", { })
	var highlight: bool = cfg.get("highlight_missed_docs", true)
	for flag_name in flags:
		var done: bool = flags[flag_name]
		var row := Label.new()
		row.text = ("[✔] " if done else "[ ] ") + _pretty(flag_name)
		if highlight:
			row.modulate = Color(0.55, 1.0, 0.65) if done else Color(1.0, 0.55, 0.55)
		checklist.add_child(row)

	for c in path_list.get_children():
		c.queue_free()
	if cfg.get("show_decision_path", true):
		var path: Array = report.get("decision_path", [])
		if path.is_empty():
			var l := Label.new()
			l.text = "(καμία επιλογή)"
			path_list.add_child(l)
		for i in path.size():
			var l := Label.new()
			l.text = "%d. %s" % [i + 1, path[i]]
			path_list.add_child(l)

	show()


func _pretty(s: String) -> String:
	return s.capitalize()


func _on_export_pressed() -> void:
	SignalBus.debrief_export_requested.emit()
	status_label.text = "Το ημερολόγιο εξήχθη ξανά."


func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()


func close() -> void:
	hide()


func _on_close_pressed() -> void:
	close()
