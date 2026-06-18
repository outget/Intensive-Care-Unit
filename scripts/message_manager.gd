class_name Message extends VBoxContainer

# Preload our individual row scene template into memory
const MESSAGE_ITEM_SCENE = preload("res://scenes/message_item.tscn")

# Forward the Enum definition to stay backwards-compatible with your main script calls
enum MsgType {STEP, TOAST, WARNING, SUCCESS, SYSTEM}

func _ready() -> void:
	# Clear out any editor placeholder nodes inside the container on start
	for child in get_children():
		child.queue_free()

func add_msg(msg: String, type: MsgType) -> void:
	# 1. Instantiate a fresh, independent label row
	var new_item = MESSAGE_ITEM_SCENE.instantiate()
	
	# 2. Add it as a child to this VBoxContainer layout node
	add_child(new_item)
	
	# 3. Fire its local initialization data constructor script
	new_item.setup(msg, type)
