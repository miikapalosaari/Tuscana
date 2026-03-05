extends Node2D

# --- Nodes ---
@onready var mapRect: TextureRect = $"../MapRect"
@onready var citiesRoot: Node2D = $"../CitiesRoot"
@onready var scoresRoot: Node2D = $"../ScoresRoot"
@onready var clickablesRoot: Node2D = $"../ClickablesRoot"

@onready var undoButton: Button = $"../LineButtonContainer/UndoButton"
@onready var scoreApplyButton: Button = $"../ScoreButtonContainer/ApplyScoresButton"

@onready var modeButton: Button = $"../Panel/ModeContainer/ToggleMode"
@onready var modeLabel: Label = $"../Panel/ModeContainer/Label"

# --- Drawing settings ---
@export var canDraw := true
@export var lineColor: Color = Color.BLACK
@export var lineWidth := 15.0

# --- Modes ---
enum Mode { DRAW, SET_SCORES }
var currentMode: Mode = Mode.DRAW

# --- Line storage ---
var permanentLines: Array = []
var startPoint: Vector2
var previewEndPoint: Vector2
var isDrawing := false


func _ready():
	_assign_city_labels_from_order()

	for node in scoresRoot.get_children():
		_exit_edit(node)

	undoButton.pressed.connect(_on_undo_pressed)
	scoreApplyButton.pressed.connect(_on_score_apply_pressed)
	modeButton.pressed.connect(_on_mode_button_pressed)

	_update_mode_ui()


# ---------------- CITY ORDER ----------------
func _assign_city_labels_from_order():
	var order: String = Global.cityOrder

	for i in range(min(order.length(), citiesRoot.get_child_count())):
		var city = citiesRoot.get_child(i)
		var label: Label = city.get_node("Label")
		label.text = order[i].to_upper()


# ---------------- MODE ----------------
func _on_mode_button_pressed():
	currentMode = Mode.SET_SCORES if currentMode == Mode.DRAW else Mode.DRAW
	_update_mode_ui()


func _update_mode_ui():
	match currentMode:
		Mode.DRAW:
			modeLabel.text = "DRAW"
			_exit_score_edit()
			_disable_clickables()

			undoButton.visible = true
			scoreApplyButton.visible = false

		Mode.SET_SCORES:
			modeLabel.text = "SET SCORES"
			_enter_score_edit()
			_enable_clickables()

			undoButton.visible = false
			scoreApplyButton.visible = true


# ---------------- SCORE EDIT ----------------
func _enter_score_edit():
	for score in scoresRoot.get_children():
		_enter_edit(score)


func _exit_score_edit():
	for score in scoresRoot.get_children():
		_exit_edit(score)


func _enter_edit(node: Node):
	var label: Label = node.get_node("Label")
	var line_edit: LineEdit = node.get_node("LineEdit")
	line_edit.text = label.text
	line_edit.visible = true
	label.visible = false


func _exit_edit(node: Node):
	var label: Label = node.get_node("Label")
	var line_edit: LineEdit = node.get_node("LineEdit")
	label.visible = true
	line_edit.visible = false


func _on_score_apply_pressed():
	for score in scoresRoot.get_children():
		_apply_edit(score)

	# Switch back to DRAW mode after applying
	currentMode = Mode.DRAW
	_update_mode_ui()


func _apply_edit(node: Node):
	var label: Label = node.get_node("Label")
	var line_edit: LineEdit = node.get_node("LineEdit")
	label.text = line_edit.text
	_exit_edit(node)


# ---------------- CLICKABLES ----------------
func _disable_clickables():
	_set_clickables_enabled(false)


func _enable_clickables():
	_set_clickables_enabled(true)


func _set_clickables_enabled(value: bool):
	for group in clickablesRoot.get_children():
		for c in group.get_children():
			c.enabled = value
			c.queue_redraw()


# ---------------- INPUT / DRAWING ----------------
func _input(event):
	if currentMode != Mode.DRAW or not canDraw:
		return

	var pos: Vector2

	# Only mouse events have position
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		pos = event.position
	else:
		return

	# Block UI clicks
	for b in [undoButton, modeButton, scoreApplyButton]:
		if b.get_global_rect().has_point(pos):
			return

	# Mouse press / release
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if mapRect.get_global_rect().has_point(pos):
				startPoint = to_local(pos)
				previewEndPoint = startPoint
				isDrawing = true
		else:
			if isDrawing:
				var endPoint = to_local(pos)
				permanentLines.append([startPoint, endPoint])
				isDrawing = false
				queue_redraw()

	# Mouse drag preview
	if event is InputEventMouseMotion and isDrawing:
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
	# Permanent lines
	for line in permanentLines:
		draw_line(line[0], line[1], lineColor, lineWidth)

	# Preview line
	if isDrawing:
		draw_line(startPoint, previewEndPoint, lineColor, lineWidth)
