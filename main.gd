extends Node2D

# --- Nodes ---
@onready var islaGrandeRect: TextureRect = $"../IslaGrandeRect"
@onready var petiteIslandRect: TextureRect = $"../PetiteIslandRect"

@onready var applyButton: Button = $"../LineButtonContainer/ApplyButton"
@onready var discardButton: Button = $"../LineButtonContainer/DiscardButton"

@onready var islaGrandeCitiesRoot: Node2D = $"../IslaGrandeCities"
@onready var petiteIslandCitiesRoot: Node2D = $"../PetiteIslandCities"

@onready var islaGrandeScoresRoot: Node2D = $"../IslaGrandeScores"
@onready var petiteIslandScoresRoot: Node2D = $"../PetiteIslandScores"

@onready var modeButton: Button = $"../Panel/ModeContainer/ToggleMode"
@onready var modeLabel: Label = $"../Panel/ModeContainer/Label"

@onready var cityApplyButton: Button = $"../CityButtonContainer/ApplyCitiesButton"
@onready var scoreApplyButton: Button = $"../ScoreButtonContainer/ApplyScoresButton"

@onready var islaGrandeClickablesRoot = $"../IslaGrandeClickables"
@onready var petiteIslandClickablesRoot = $"../PetiteIslandClickables"

@onready var mapToggleButton: Button = $"../MapToggleButton"

# --- Drawing settings ---
@export var canDraw: bool = true
@export var lineColor: Color = Color.BLACK
@export var lineWidth: float = 15.0

# --- Modes ---
enum Mode { NONE, DRAW, SET_CITIES, SET_SCORES }
var currentMode: Mode = Mode.NONE

# --- Maps ---
enum Map { ISLA_GRANDE, PETITE_ISLAND }
var currentMap: Map = Map.ISLA_GRANDE

# --- Line storage ---
var permanentLines: Array = []
var tempPoints: Array = []
var lineInProgress: bool = false

# --- Ready ---
func _ready():
	# Hide buttons initially
	applyButton.visible = false
	discardButton.visible = false
	cityApplyButton.visible = false
	scoreApplyButton.visible = false

	# Reset city & score edit
	for node in islaGrandeCitiesRoot.get_children():
		_exit_city_or_score_edit_for_node(node)
	for node in petiteIslandCitiesRoot.get_children():
		_exit_city_or_score_edit_for_node(node)
	for node in islaGrandeScoresRoot.get_children():
		_exit_city_or_score_edit_for_node(node)
	for node in petiteIslandScoresRoot.get_children():
		_exit_city_or_score_edit_for_node(node)

	# Connect signals
	applyButton.pressed.connect(_on_apply_pressed)
	discardButton.pressed.connect(_on_discard_pressed)
	cityApplyButton.pressed.connect(_on_city_apply_pressed)
	scoreApplyButton.pressed.connect(_on_score_apply_pressed)
	modeButton.pressed.connect(_on_mode_button_pressed)
	mapToggleButton.pressed.connect(_on_map_toggle_pressed)

	_update_mode_ui()
	_update_map_visibility()


# ---------------- MAP TOGGLE ----------------
func _on_map_toggle_pressed():
	# Switch map
	currentMap = (currentMap + 1) % Map.size()

	# Clear all selections for clickables in both maps
	_clear_all_clickable_selection(islaGrandeClickablesRoot)
	_clear_all_clickable_selection(petiteIslandClickablesRoot)

	# Update visibility
	_update_map_visibility()

	# Reset lines & UI buttons
	_clear_game_state_lines_and_ui()


func _update_map_visibility():
	if currentMap == Map.ISLA_GRANDE:
		islaGrandeRect.visible = true
		islaGrandeCitiesRoot.visible = true
		islaGrandeScoresRoot.visible = true
		islaGrandeClickablesRoot.visible = true

		petiteIslandRect.visible = false
		petiteIslandCitiesRoot.visible = false
		petiteIslandScoresRoot.visible = false
		petiteIslandClickablesRoot.visible = false

		mapToggleButton.text = "Switch to Petite Island"
	else:
		islaGrandeRect.visible = false
		islaGrandeCitiesRoot.visible = false
		islaGrandeScoresRoot.visible = false
		islaGrandeClickablesRoot.visible = false

		petiteIslandRect.visible = true
		petiteIslandCitiesRoot.visible = true
		petiteIslandScoresRoot.visible = true
		petiteIslandClickablesRoot.visible = true

		mapToggleButton.text = "Switch to Isla Grande"

	queue_redraw()


# Reset only lines/UI/buttons, not Clickable selection
func _clear_game_state_lines_and_ui():
	permanentLines.clear()
	tempPoints.clear()
	lineInProgress = false

	applyButton.visible = false
	discardButton.visible = false
	cityApplyButton.visible = false
	scoreApplyButton.visible = false

	currentMode = Mode.NONE
	_exit_city_edit()
	_exit_score_edit()
	_update_mode_ui()

	_disable_active_clickables()
	queue_redraw()


# ---------------- HELPERS ----------------
func _clear_all_clickable_selection(root: Node):
	for group in root.get_children():
		for c in group.get_children():
			if c.has_method("selected"):
				c.selected = false
				c.queue_redraw()


# ---------------- MODE BUTTON ----------------
func _on_mode_button_pressed():
	currentMode = (currentMode + 1) % Mode.size()
	_update_mode_ui()


func _update_mode_ui():
	applyButton.visible = false
	discardButton.visible = false
	cityApplyButton.visible = false
	scoreApplyButton.visible = false

	match currentMode:
		Mode.NONE:
			modeLabel.text = "NONE"
			_exit_city_edit()
			_exit_score_edit()
			_reset_temp_line()
			_disable_active_clickables()

		Mode.DRAW:
			modeLabel.text = "DRAW"
			_exit_city_edit()
			_exit_score_edit()
			_reset_temp_line()
			_disable_active_clickables()

		Mode.SET_CITIES:
			modeLabel.text = "SET CITIES"
			_enter_city_edit()
			_reset_temp_line()
			_disable_active_clickables()

		Mode.SET_SCORES:
			modeLabel.text = "SET SCORES"
			_exit_city_edit()
			_enter_score_edit()
			scoreApplyButton.visible = true
			_reset_temp_line()
			_enable_active_clickables()


# ---------------- CITY / SCORE EDIT ----------------
func _enter_city_edit():
	cityApplyButton.visible = true
	for city in _get_active_cities_root().get_children():
		var label: Label = city.get_node("Label")
		var line_edit: LineEdit = city.get_node("LineEdit")
		line_edit.text = label.text
		line_edit.visible = true
		label.visible = false

func _exit_city_edit():
	for city in _get_active_cities_root().get_children():
		_exit_city_or_score_edit_for_node(city)
	cityApplyButton.visible = false


func _enter_score_edit():
	scoreApplyButton.visible = true
	for score in _get_active_scores_root().get_children():
		var label: Label = score.get_node("Label")
		var line_edit: LineEdit = score.get_node("LineEdit")
		line_edit.text = label.text
		line_edit.visible = true
		label.visible = false

func _exit_score_edit():
	for score in _get_active_scores_root().get_children():
		_exit_city_or_score_edit_for_node(score)
	scoreApplyButton.visible = false


# Generic helper for City or Score nodes
func _exit_city_or_score_edit_for_node(node: Node):
	var label: Label = node.get_node("Label")
	var line_edit: LineEdit = node.get_node("LineEdit")
	label.visible = true
	line_edit.visible = false


func _on_city_apply_pressed():
	for city in _get_active_cities_root().get_children():
		var label: Label = city.get_node("Label")
		var line_edit: LineEdit = city.get_node("LineEdit")
		label.text = line_edit.text
		label.visible = true
		line_edit.visible = false
	cityApplyButton.visible = false


func _on_score_apply_pressed():
	for score in _get_active_scores_root().get_children():
		var label: Label = score.get_node("Label")
		var line_edit: LineEdit = score.get_node("LineEdit")
		label.text = line_edit.text
		label.visible = true
		line_edit.visible = false
	scoreApplyButton.visible = false


# ---------------- ACTIVE ROOT HELPERS ----------------
func _get_active_cities_root() -> Node2D:
	return islaGrandeCitiesRoot if currentMap == Map.ISLA_GRANDE else petiteIslandCitiesRoot

func _get_active_scores_root() -> Node2D:
	return islaGrandeScoresRoot if currentMap == Map.ISLA_GRANDE else petiteIslandScoresRoot

func _get_active_clickables_root() -> Node2D:
	return islaGrandeClickablesRoot if currentMap == Map.ISLA_GRANDE else petiteIslandClickablesRoot


# ---------------- CLICKABLES ----------------
func _disable_active_clickables():
	_set_clickables_enabled(_get_active_clickables_root(), false)

func _enable_active_clickables():
	_set_clickables_enabled(_get_active_clickables_root(), true)

func _set_clickables_enabled(root: Node, value: bool):
	for group in root.get_children():
		for c in group.get_children():
			c.enabled = value
			c.queue_redraw()


# ---------------- INPUT / DRAWING ----------------
func _input(event):
	if currentMode != Mode.DRAW or not canDraw:
		return

	var global_pos: Vector2

	# --- Mouse click ---
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		global_pos = event.position

	# --- Mobile touch ---
	elif event is InputEventScreenTouch and event.pressed:
		global_pos = event.position

	else:
		return

	# Block UI clicks
	for b in [applyButton, discardButton, modeButton, cityApplyButton, scoreApplyButton, mapToggleButton]:
		if b.get_global_rect().has_point(global_pos):
			return

	# Must be inside active map texture
	var active_rect = _get_active_texture()
	if not active_rect.get_global_rect().has_point(global_pos):
		return

	var local_pos: Vector2 = to_local(global_pos)

	if not lineInProgress:
		tempPoints = [local_pos]
		lineInProgress = true
		applyButton.visible = true
		discardButton.visible = true
	else:
		tempPoints.append(local_pos)

	queue_redraw()


# ---------------- LINE BUTTONS ----------------
func _on_apply_pressed():
	if lineInProgress and tempPoints.size() > 1:
		for i in range(tempPoints.size() - 1):
			permanentLines.append([tempPoints[i], tempPoints[i + 1]])
	_reset_temp_line()


func _on_discard_pressed():
	_reset_temp_line()


func _reset_temp_line():
	tempPoints.clear()
	lineInProgress = false
	applyButton.visible = false
	discardButton.visible = false
	queue_redraw()


# ---------------- DRAW ----------------
func _draw():
	for line in permanentLines:
		draw_line(line[0], line[1], lineColor, lineWidth)

	if lineInProgress and tempPoints.size() > 1:
		for i in range(tempPoints.size() - 1):
			draw_line(tempPoints[i], tempPoints[i + 1], lineColor, lineWidth)


func _get_active_texture() -> TextureRect:
	return islaGrandeRect if currentMap == Map.ISLA_GRANDE else petiteIslandRect
