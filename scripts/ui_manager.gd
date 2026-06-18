extends CanvasLayer

@export var tooltips_label: Label
var is_hover: bool
var mouse_pos: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.mouse_interactable.connect(on_mouse_interactable)
	tooltips_label.visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_pos = get_viewport().get_mouse_position()

func _process(_delta: float) -> void:
	if is_hover:
		tooltips_label.position = mouse_pos + Vector2(20,20)

func on_mouse_interactable(interactable: String, on: bool) -> void:
	if on:
		is_hover = true
		tooltips_label.text = "Interact with " + interactable
		tooltips_label.visible = true
	else:
		is_hover = false
		tooltips_label.visible = false
