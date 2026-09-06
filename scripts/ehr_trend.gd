extends Control

# SpO2 values over time, newest last.
var _series: Array = []

const LO := 70.0
const HI := 100.0
const DANGER := 90.0

func set_history(history: Array) -> void:
	_series = history.map(func(v): return float(v.get("spo2", 0.0)))
	queue_redraw()

func _draw() -> void:
	# Danger threshold line.
	var y_danger := _y(DANGER)
	draw_line(Vector2(0, y_danger), Vector2(size.x, y_danger), Color(1, 0.4, 0.4, 0.5), 1.0)

	if _series.size() < 2:
		return

	var points: PackedVector2Array = []
	for i in _series.size():
		var x := size.x * i / float(_series.size() - 1)
		points.append(Vector2(x, _y(_series[i])))
	draw_polyline(points, Color(0.4, 1.0, 0.6), 2.0)

func _y(value: float) -> float:
	return size.y * (1.0 - (clampf(value, LO, HI) - LO) / (HI - LO))
