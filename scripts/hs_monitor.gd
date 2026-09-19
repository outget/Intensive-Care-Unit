extends Node3D

@export var hotspot_id: String
@export var model_root: Node3D
@export var outline_size: float = 1.03
@export var screen_ui: Node

var _outlines: Array[ShaderMaterial] = []
var _alarm: bool = false
var _hover: bool = false


func _ready() -> void:
	_outlines = HotspotOutline.attach(model_root if model_root else self, outline_size)
	set_process(false)
	_refresh()


func set_vitals(vitals: Dictionary) -> void:
	if screen_ui and screen_ui.has_method("update_vitals"):
		screen_ui.update_vitals(vitals)


func set_alarm(on: bool) -> void:
	if _alarm == on:
		return
	_alarm = on
	set_process(_alarm)
	if screen_ui and screen_ui.has_method("set_alarm"):
		screen_ui.set_alarm(on)
	_refresh()


func _process(_delta: float) -> void:
	var pulse: float = 0.4 + 0.6 * (0.5 + 0.5 * sin(Time.get_ticks_msec() / 150.0))
	HotspotOutline.set_param(_outlines, "color", Color(1.0, 0.0, 0.0, pulse))
	HotspotOutline.set_param(_outlines, "on", 1.0)


func _refresh() -> void:
	if _alarm:
		return
	if _hover:
		HotspotOutline.set_param(_outlines, "color", Color.WHITE)
		HotspotOutline.set_param(_outlines, "on", 1.0)
	else:
		HotspotOutline.set_param(_outlines, "on", 0.0)


func _on_monitor_area_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		SignalBus.hotspot_clicked.emit(hotspot_id)


func _on_monitor_area_mouse_entered() -> void:
	_hover = true
	_refresh()
	SignalBus.mouse_interactable.emit(name, true)


func _on_monitor_area_mouse_exited() -> void:
	_hover = false
	_refresh()
	SignalBus.mouse_interactable.emit(name, false)


func set_outline_visibility(vis: bool) -> void:
	_hover = vis
	_refresh()
