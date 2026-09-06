extends Node

signal mouse_interactable(name: String, on: bool)

signal hotspot_clicked(hotspot_id: String)

# EHR panel -> scenario engine, fired on Save with { form_id: { field: value } }.
signal ehr_updated(ehr_data: Dictionary)

# EHR panel open/close, for anything that needs to react (camera, dimming, ...).
signal ehr_panel_toggled(open: bool)
