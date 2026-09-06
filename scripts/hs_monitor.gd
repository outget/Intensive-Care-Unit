extends Node3D

@export var hotspot_id: String
@export var mesh: MeshInstance3D
var outline_material: ShaderMaterial
var _alarm: bool = false


func _ready() -> void:
	if mesh.material_overlay:
		outline_material = mesh.material_overlay as ShaderMaterial
	set_process(false)
	set_outline_visibility(false)


func set_alarm(on: bool) -> void:
	_alarm = on
	if not outline_material:
		return
	if on:
		outline_material.set_shader_parameter("color", Color(1, 0, 0, 1))
		set_process(true)
	else:
		set_process(false)
		outline_material.set_shader_parameter("color", Color(1, 1, 1, 1))
		outline_material.set_shader_parameter("on", 0)


func _process(_delta: float) -> void:
	if _alarm and outline_material:
		outline_material.set_shader_parameter("on", 0.5 + 0.5 * sin(Time.get_ticks_msec() / 120.0))


func _on_monitor_area_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			handle_hotspot_click()


func handle_hotspot_click() -> void:
	print("Monitor got clicked!")
	SignalBus.hotspot_clicked.emit(hotspot_id)


func _on_monitor_area_mouse_entered() -> void:
	set_outline_visibility(true)
	SignalBus.mouse_interactable.emit(self.name, true)


func _on_monitor_area_mouse_exited() -> void:
	set_outline_visibility(false)
	SignalBus.mouse_interactable.emit(self.name, false)


func set_outline_visibility(vis: bool) -> void:
	if outline_material:
		if vis:
			outline_material.set_shader_parameter("on", 1)
		else:
			outline_material.set_shader_parameter("on", 0)
