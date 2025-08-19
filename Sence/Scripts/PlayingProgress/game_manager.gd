#game_manager.gd
extends Node

var player_hp = 100
var player_max_hp = 100
var current_level = 1
var score = 0

@onready var score_label = $ScoreLabel

func add_point	():
	score += 1
	score_label.text = "You collected " + str(score) + " coins"
