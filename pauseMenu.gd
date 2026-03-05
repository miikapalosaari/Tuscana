extends Control

@onready var pauseMenuToggle: Button = $TogglePauseMenuButton
@onready var pauseMenuButtonsContainer = $VBoxContainer

func _ready():
	pauseMenuButtonsContainer.visible = false

func _on_toggle_pause_menu_button_pressed() -> void:
	pauseMenuButtonsContainer.visible = not pauseMenuButtonsContainer.visible


func _on_back_to_main_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://MainMenu.tscn")


func _on_return_button_pressed() -> void:
	pauseMenuButtonsContainer.visible = false
