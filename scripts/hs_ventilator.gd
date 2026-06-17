extends Node3D

@export var mesh: MeshInstance3D
@export var tooltip: Label

var outline_material: ShaderMaterial

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if mesh.material_overlay:
		outline_material = mesh.material_overlay as ShaderMaterial
	set_outline_visibility(false)

func _on_area_3d_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			handle_hotspot_click()

func handle_hotspot_click() -> void:
	print("Ventilator got clicked!")

func _on_area_3d_mouse_entered() -> void:
	set_outline_visibility(true)
	SignalBus.mouse_interactable.emit(self.name, true)

func _on_area_3d_mouse_exited() -> void:
	set_outline_visibility(false)
	SignalBus.mouse_interactable.emit(self.name, false)

	
func set_outline_visibility(vis: bool) -> void:
	if outline_material:
		if vis:
			outline_material.set_shader_parameter("on", 1)
		else:
			outline_material.set_shader_parameter("on", 0)
