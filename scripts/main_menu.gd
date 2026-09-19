extends CanvasLayer

@export var scenario_list: ItemList

const SCENARIO_DIR := "res://json"

var _scenario_paths: Array[String] = []


func _ready() -> void:
	_populate_scenarios()


func _populate_scenarios() -> void:
	scenario_list.clear()
	_scenario_paths.clear()

	var dir := DirAccess.open(SCENARIO_DIR)
	if dir == null:
		return

	var file_names: Array[String] = []
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			file_names.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	file_names.sort()

	for entry in file_names:
		var path := "%s/%s" % [SCENARIO_DIR, entry]
		var meta := _read_scenario_meta(path)
		if meta.is_empty():
			continue
		_scenario_paths.append(path)
		scenario_list.add_item("%s (%s)" % [meta.get("title", entry), meta.get("difficulty", "-")])

	if not _scenario_paths.is_empty():
		scenario_list.select(0)


func _read_scenario_meta(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return { }

	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return { }

	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		return { }
	return data.get("scenario_meta", { })


func _on_start_pressed() -> void:
	var selected := scenario_list.get_selected_items()
	if not selected.is_empty() and not _scenario_paths.is_empty():
		SignalBus.selected_scenario_path = _scenario_paths[selected[0]]
	get_tree().change_scene_to_file("res://scenes/icu.tscn")

func _on_info_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/info.tscn")
