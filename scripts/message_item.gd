extends RichTextLabel

enum MsgType {STEP, TOAST, WARNING, SUCCESS, SYSTEM}

func setup(msg: String, type: MsgType) -> void:
	bbcode_enabled = true
	fit_content = true
	mouse_filter = MOUSE_FILTER_IGNORE
	modulate.a = 0.0
	
	var type_name: String = MsgType.keys()[type]
	
	match type:
		MsgType.STEP:
			append_text("[color=yellow][fade start=0 length=14][b][" + type_name + "]:[/b][/fade] " + msg + "[/color]")
		MsgType.WARNING:
			append_text("[color=crimson][shake rate=20.0 level=5 bl=1][b][" + type_name + "]:[/b] " + msg + "[/shake][/color]")
		MsgType.SUCCESS:
			append_text("[color=chartreuse][pulse freq=1.0 color=#ffffff44 ease=-2.0][b][" + type_name + "]:[/b] " + msg + "[/pulse][/color]")
		MsgType.TOAST:
			append_text("[color=goldenrod][i][" + type_name + "]:[/i] " + msg + "[/color]")
		MsgType.SYSTEM:
			append_text("[" + type_name + "]: " + msg)

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	tween.tween_interval(15.0)
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)
	
