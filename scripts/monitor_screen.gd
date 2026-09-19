extends Control

@export var hr_value: Label
@export var spo2_value: Label
@export var rr_value: Label
@export var bp_value: Label
@export var temp_value: Label
@export var alarm_banner: Label


func _ready() -> void:
	if alarm_banner:
		alarm_banner.visible = false


func update_vitals(v: Dictionary) -> void:
	hr_value.text = _f(v.get("hr"))
	spo2_value.text = _f(v.get("spo2"))
	rr_value.text = _f(v.get("rr"))
	bp_value.text = str(v.get("bp", "--"))
	temp_value.text = _f(v.get("temp"))


func set_alarm(on: bool) -> void:
	if alarm_banner:
		alarm_banner.visible = on


func _f(x) -> String:
	if x == null:
		return "--"
	if x is float and x == floor(x):
		return str(int(x))
	return str(x)
