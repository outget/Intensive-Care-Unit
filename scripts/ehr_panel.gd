extends CanvasLayer

## Electronic Health Record panel.
## Dumb UI: builds its forms at runtime from scenario_data["ehr_config"],
## shows live vitals + an SpO2 trend, and emits SignalBus.ehr_updated on Save.
## All game logic (gates, scoring, logging) lives in icu.gd.

@export var vitals_grid: GridContainer
@export var trend_graph: Control
@export var tabs: TabContainer
@export var status_label: Label
@export var window_root: Control

# form_id -> { field_name -> input Control }
var _field_nodes: Dictionary = {}

func _ready() -> void:
	hide()
	status_label.text = ""
	SignalBus.hotspot_clicked.connect(_on_hotspot_clicked)

func _on_hotspot_clicked(hotspot_id: String) -> void:
	if hotspot_id == "hs_ehr":
		open()

# --- build (called once by icu.gd) ---------------------------------

func setup(ehr_config: Dictionary) -> void:
	for child in tabs.get_children():
		child.queue_free()
	_field_nodes.clear()

	var forms: Dictionary = ehr_config.get("forms", {})
	for form_id in forms:
		var form: Dictionary = forms[form_id]
		var page := VBoxContainer.new()
		page.name = str(form.get("title", form_id))
		page.add_theme_constant_override("separation", 8)
		_field_nodes[form_id] = {}

		for field in form.get("fields", []):
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 12)

			var label := Label.new()
			label.text = _pretty(field)
			label.custom_minimum_size.x = 170

			var input := _make_input(field)

			row.add_child(label)
			row.add_child(input)
			page.add_child(row)
			_field_nodes[form_id][field] = input

		tabs.add_child(page)
		tabs.set_tab_title(tabs.get_tab_count() - 1, page.name)

func _make_input(field: String) -> Control:
	var out: Control
	match field:
		"consciousness":
			out = _option(["", "Alert", "Voice", "Pain", "Unresponsive"])
		"skin_color":
			out = _option(["", "Φυσιολογικό", "Ωχρό", "Κυάνωση", "Ερυθρό"])
		"device":
			out = _option(["", "Ρινική κάνουλα", "Μάσκα Venturi", "Μάσκα με ασκό", "Αναπνευστήρας"])
		"recipient":
			out = _option(["", "Εφημερεύων ιατρός", "Εντατικολόγος", "Προϊστάμενος νοσηλευτής"])
		"outcome":
			out = _option(["", "Θα προσέλθει άμεσα", "Οδηγίες τηλεφωνικά", "Δεν απάντησε"])
		_:
			out = LineEdit.new()
	out.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return out

func _option(items: Array) -> OptionButton:
	var o := OptionButton.new()
	for item in items:
		o.add_item(item)
	return o

func _pretty(field: String) -> String:
	return field.capitalize()

# --- open / close -------------------------------------------------

func open() -> void:
	show()
	window_root.mouse_filter = Control.MOUSE_FILTER_STOP
	SignalBus.ehr_panel_toggled.emit(true)

func _on_close_pressed() -> void:
	hide()
	SignalBus.ehr_panel_toggled.emit(false)

# --- live data (pushed from icu.gd) ------------------------------

func update_vitals(vitals: Dictionary, history: Array) -> void:
	for key in ["hr", "spo2", "rr", "bp", "temp"]:
		var lbl := vitals_grid.find_child(key.to_upper(), true, false) as Label
		if lbl:
			lbl.text = _fmt(vitals.get(key, "-"))
	if trend_graph and trend_graph.has_method("set_history"):
		trend_graph.set_history(history)

func _fmt(value) -> String:
	if value is float and value == floor(value):
		return str(int(value))
	return str(value)

# --- save --------------------------------------------------------

func _on_save_pressed() -> void:
	var out: Dictionary = {}
	for form_id in _field_nodes:
		for field in _field_nodes[form_id]:
			var value := _read_value(_field_nodes[form_id][field])
			if value != "":
				if not out.has(form_id):
					out[form_id] = {}
				out[form_id][field] = value
	SignalBus.ehr_updated.emit(out)
	status_label.text = "✅ Η τεκμηρίωση αποθηκεύτηκε."

func _read_value(node: Control) -> String:
	if node is LineEdit:
		return node.text.strip_edges()
	if node is OptionButton:
		return node.get_item_text(node.selected).strip_edges() if node.selected >= 0 else ""
	return ""
