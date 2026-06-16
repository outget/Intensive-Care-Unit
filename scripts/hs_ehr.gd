extends Node3D

@export var mesh: MeshInstance3D
@export var mesh_base: MeshInstance3D

var outline_material: ShaderMaterial
var base_outline_material: ShaderMaterial

func _ready() -> void:
	if mesh and mesh.material_overlay:
		mesh.material_overlay = mesh.material_overlay.duplicate()
		outline_material = mesh.material_overlay as ShaderMaterial

	if mesh_base and mesh_base.material_overlay:
		mesh_base.material_overlay = mesh_base.material_overlay.duplicate()
		base_outline_material = mesh_base.material_overlay as ShaderMaterial

	set_outline_visibility(false)

func _on_area_3d_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			handle_hotspot_click()

func handle_hotspot_click() -> void:
	print("EHR Terminal got clicked!")

func _on_area_3d_mouse_entered() -> void:
	set_outline_visibility(true)
func _on_area_3d_mouse_exited() -> void:
	set_outline_visibility(false)

func set_outline_visibility(vis: bool) -> void:
	var intensity = 1 if vis else 0

	if outline_material:
		outline_material.set_shader_parameter("on", intensity)

	if base_outline_material:
		base_outline_material.set_shader_parameter("on", intensity)
