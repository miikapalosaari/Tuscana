extends Control

@onready var playerSelect: LineEdit = $VBoxContainer/Player/LineEdit
@onready var randomSeedSelect: LineEdit = $VBoxContainer/RandomSeed/LineEdit
@onready var mapSelect: LineEdit = $VBoxContainer/Map/LineEdit

# playerSelect (1 - 8) player index
# randomSeedSelect 10 digit number
# mapSelect (1 - 2) map index

var cityOrders : Array[String] = [
	"ACBDCDEBAE",
	"BEDCBADECA",
	"BDCAEBEDCA",
	"EBDBACAECD",
	"CAECBADEBD",
	"ADCBDACEBE",
	"DBACECDAEB",
	"ECAEBDABDC",
	"EADBCEBDAC",
	"CEBAEDCDAB",
	"DADBAECECB",
	"DCEADCBAEB",
	"BACBDCEAED"
]

var scenePaths: Array[String] = [
	"res://IslaPetit.tscn",
	"res://IslaGrande.tscn",
	"res://IslaBahia.tscn",
	"res://IslaHabita.tscn"
]

var selectedScene: String = ""
var selectedRandomSeed: int = 0;
var selectedPlayerIndex: int = 0;

func _on_play_button_pressed() -> void:
	selectedPlayerIndex = playerSelect.text.to_int()
	selectedRandomSeed = randomSeedSelect.text.to_int()
	var mapIndex = mapSelect.text.to_int() - 1

	selectedScene = scenePaths[mapIndex]

	randomCityOrder()

	get_tree().change_scene_to_file(selectedScene)


func randomCityOrder() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = selectedRandomSeed  # käytä käyttäjän syöttämää seed-arvoa

	var randomIndex = rng.randi_range(0, cityOrders.size() - 1)
	var randomCityStr = cityOrders[randomIndex]
	print("randCityStr: ", randomCityStr)

	# normalisoi pelaajaindeksi (1–8 -> 0–7)
	var p = selectedPlayerIndex - 1

	# jaa merkkijono kahteen osaan
	var left = randomCityStr.substr(0, p)
	var right = randomCityStr.substr(p, randomCityStr.length() - p)

	# siirrä pelaajan kohta alkuun
	var newCityStr = right + left
	
	print("playerIndex: ", selectedPlayerIndex)
	print("newCityStr: ", newCityStr)

	Global.cityOrder = newCityStr
