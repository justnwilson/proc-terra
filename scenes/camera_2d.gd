extends Camera2D

@export var zoom_speed: float = 1.0

func _process(delta: float) -> void:
	var input_zoom = Input.get_axis("zoom_out", "zoom_in")
	if input_zoom:
		var new_zoom = clampf(zoom.x + (delta * input_zoom * zoom_speed), 0.1, 2.0)
		zoom = Vector2(new_zoom, new_zoom)
