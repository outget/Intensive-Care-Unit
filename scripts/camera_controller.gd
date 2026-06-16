extends Camera3D

@export_range(0, 180) var max_angle: float = 45.0
@export_range(0.0, 1.0) var deadzone_percentage: float = 0.3
@export var move_speed: float = 1.5

var mouse_pos: Vector2
var base_y_rotation: float

func _ready() -> void:
	await get_tree().process_frame
	mouse_pos = get_viewport().get_visible_rect().size / 2.0
	base_y_rotation = global_transform.basis.get_euler().y

func _process(delta: float) -> void:
	var viewport = get_viewport()
	var screen_size = viewport.get_visible_rect().size
	var screen_center = screen_size / 2.0

	var distance_x = mouse_pos.x - screen_center.x
	var normalized_horizontal_distance = abs(distance_x / screen_center.x)

	if normalized_horizontal_distance < deadzone_percentage:
		return

	var ray_normal = project_ray_normal(mouse_pos)
	var target_position = global_position + ray_normal
	target_position.y = global_position.y

	var target_transform = global_transform.looking_at(target_position, Vector3.UP)
	var target_y_rotation = target_transform.basis.get_euler().y

	var angle_diff = angle_difference(base_y_rotation, target_y_rotation)
	var max_radians = deg_to_rad(max_angle)
	var clamped_difference = clamp(angle_diff, -max_radians, max_radians)

	var target_clamped_rotation = base_y_rotation + clamped_difference

	rotation.y = move_toward(rotation.y, target_clamped_rotation, move_speed * delta)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_pos = get_viewport().get_mouse_position()
