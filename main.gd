extends Node2D

# --- Nodes ---
@onready var mapRect: TextureRect = $"../MapRect"
@onready var citiesRoot: Node2D = $"../CitiesRoot"
@onready var scoresRoot: Node2D = $"../ScoresRoot"
@onready var clickablesRoot: Node2D = $"../ClickablesRoot"

@onready var undoButton: Button = $"../LineButtonContainer/UndoButton"
@onready var deckButton: Button = $"../Deck"

# --- Drawing settings ---
@export var canDraw := true
@export var lineColor: Color = Color.BLACK
@export var lineWidth := 15.0

# --- Line storage ---
var permanentLines: Array = []
var startPoint: Vector2
var previewEndPoint: Vector2
var isDrawing := false


func _ready():
	_assign_city_labels_from_order()

	# Score fields always editable
	for node in scoresRoot.get_children():
		var label: Label = node.get_node("Label")
		var line_edit: LineEdit = node.get_node("LineEdit")
		label.visible = false
		line_edit.visible = true
		deckButton.visible = Global.isHost

	undoButton.pressed.connect(_on_undo_pressed)


# ---------------- CITY ORDER ----------------
func _assign_city_labels_from_order():
	var order: String = Global.cityOrder

	for i in range(min(order.length(), citiesRoot.get_child_count())):
		var city = citiesRoot.get_child(i)
		var label: Label = city.get_node("Label")
		label.text = order[i].to_upper()


# ---------------- INPUT / DRAWING ----------------
func _input(event):
	if not canDraw:
		return

	var pos: Vector2

	# Mouse or touch events
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		pos = event.position
	elif event is InputEventMouseMotion or event is InputEventScreenDrag:
		pos = event.position
	else:
		return

	# Block UI clicks
	for b in [undoButton, deckButton]:
		if b.get_global_rect().has_point(pos):
			return

	# Press / release
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT) \
	or (event is InputEventScreenTouch):
		if event.pressed:
			if mapRect.get_global_rect().has_point(pos):
				startPoint = to_local(pos)
				previewEndPoint = startPoint
				isDrawing = true
		else:
			if isDrawing:
				var endPoint = to_local(pos)
				var distance = startPoint.distance_to(endPoint)

				# Only store meaningful lines
				if distance >= 20.0:
					permanentLines.append([startPoint, endPoint])

				isDrawing = false
				queue_redraw()

	# Drag preview
	if (event is InputEventMouseMotion or event is InputEventScreenDrag) and isDrawing:
		if mapRect.get_global_rect().has_point(pos):
			previewEndPoint = to_local(pos)
			queue_redraw()


# ---------------- UNDO ----------------
func _on_undo_pressed():
	if permanentLines.size() > 0:
		permanentLines.pop_back()

	isDrawing = false
	queue_redraw()


# ---------------- DRAW ----------------
func _draw():
	for line in permanentLines:
		draw_line(line[0], line[1], lineColor, lineWidth)

	if isDrawing:
		draw_line(startPoint, previewEndPoint, lineColor, lineWidth)
