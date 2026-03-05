extends Button
# DECK

@onready var leftCard : TextureRect = $HBoxContainer/LeftCard
@onready var rightCard : TextureRect = $HBoxContainer/RightCard 

enum Terrain {
	EMPTY,
	FOREST,
	SAND,
	ROCK,
	WATER,
	JOKER
}

var textures := [
	preload("res://empty256.png"),
	preload("res://forest256.png"),
	preload("res://sand256.png"),
	preload("res://rock256.png"),
	preload("res://water256.png"),
	preload("res://joker256.png")
]

var deck : Array[int] = []
var pairs : Array = []
var pairIndex := 0

func build_deck():
	deck.clear()
	for i in 8:
		deck.append(Terrain.SAND)
	for i in 7:
		deck.append(Terrain.FOREST)
	for i in 6:
		deck.append(Terrain.ROCK)
	for i in 4:
		deck.append(Terrain.WATER)
	for i in 2:
		deck.append(Terrain.JOKER)
	deck.shuffle()

func make_pairs():
	pairs.clear()
	for i in range(0, 26, 2):
		pairs.append([deck[i], deck[i+1]])
	pairIndex = 0

func _ready():
	build_deck()
	make_pairs()
	leftCard.texture = textures[Terrain.EMPTY]
	rightCard.texture = textures[Terrain.EMPTY]


func _on_pressed() -> void:
	if pairIndex < pairs.size():
		var leftType = pairs[pairIndex][0]
		var rightType = pairs[pairIndex][1]

		leftCard.texture = textures[leftType]
		rightCard.texture = textures[rightType]

		pairIndex += 1
	else:
		# Show empty cards
		leftCard.texture = textures[Terrain.EMPTY]
		rightCard.texture = textures[Terrain.EMPTY]

		# Rebuild deck and reshuffle for next cycle
		build_deck()
		make_pairs()
