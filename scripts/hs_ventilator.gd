extends Node3D

@export var hotspot_id: String
@export var model_root: Node3D
@export var outline_size: float = 1.03

var _outlines: Array[ShaderMaterial] = []

func _ready() -> void:
	_outlines = HotspotOutline.attach(model_root if model_root else self, outline_size)
	HotspotOutline.set_visible(_outlines, false)

func _on_area_3d_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		handle_hotspot_click()

func handle_hotspot_click() -> void:
	SignalBus.hotspot_clicked.emit(hotspot_id)

func _on_area_3d_mouse_entered() -> void:
	HotspotOutline.set_visible(_outlines, true)
	SignalBus.mouse_interactable.emit(name, true)

func _on_area_3d_mouse_exited() -> void:
	HotspotOutline.set_visible(_outlines, false)
	SignalBus.mouse_interactable.emit(name, false)

func set_outline_visibility(vis: bool) -> void:
	HotspotOutline.set_visible(_outlines, vis)
