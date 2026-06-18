extends CanvasLayer


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/icu.tscn")

func _on_info_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/info.tscn")
