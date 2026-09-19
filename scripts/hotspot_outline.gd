class_name HotspotOutline
extends RefCounted

const SHADER: Shader = preload("res://shaders/outline.gdshader")


static func attach(root: Node, size: float = 1.03) -> Array[ShaderMaterial]:
	var mats: Array[ShaderMaterial] = []
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		if not mi.visible:
			continue # let callers hide junk meshes (fake shadows, backdrops) before attaching
		var m := ShaderMaterial.new()
		m.shader = SHADER
		m.set_shader_parameter("color", Color.WHITE)
		m.set_shader_parameter("size", size)
		m.set_shader_parameter("on", 0.0)
		mi.material_overlay = m
		mats.append(m)
	return mats


static func set_visible(mats: Array, vis: bool) -> void:
	for m in mats:
		m.set_shader_parameter("on", 1.0 if vis else 0.0)


static func set_param(mats: Array, param: StringName, value: Variant) -> void:
	for m in mats:
		m.set_shader_parameter(param, value)
