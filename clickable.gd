extends Node2D

@export var rect_size: Vector2 = Vector2(32, 32)
@export var border_color: Color = Color.RED
@export var border_width: float = 4.0
@export var enabled := true
@onready var label: Label = $Label

var selected := false

func _unhandled_input(event):
	if not enabled:
		return

	# PC: käsittele vain hiiren klikkaus
	if OS.has_feature("pc"):
		if not (event is InputEventMouseButton and event.pressed):
			return

	# Mobile: käsittele vain kosketus, EI hiiri-emulaatiota
	elif OS.has_feature("mobile"):
		if not (event is InputEventScreenTouch and event.pressed):
			return

	# Yhteinen logiikka
	var pos: Vector2 = get_viewport().get_mouse_position()
	var local_pos = to_local(pos)
	var rect = Rect2(-rect_size / 2, rect_size)

	if rect.has_point(local_pos):
		selected = !selected
		queue_redraw()


func _draw():
	if selected:
		var rect = Rect2(-rect_size / 2, rect_size)
		draw_rect(rect, border_color, false, border_width)
