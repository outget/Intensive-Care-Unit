extends Node

var selected_scenario_path: String = "res://json/scenario.json"

signal mouse_interactable(name: String, on: bool)

signal hotspot_clicked(hotspot_id: String)

signal ehr_updated(ehr_data: Dictionary)

signal ehr_panel_toggled(open: bool)

signal debrief_export_requested()
