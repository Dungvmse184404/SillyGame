#orange.gd
extends Area2D

@onready var animation_player = $AnimationPlayer

func _on_body_entered(body: Node2D) -> void:
	#game_manager.add_point()
	print("ăn cam")
	animation_player.play("pickup")
