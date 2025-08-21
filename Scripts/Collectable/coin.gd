# coin.gd
extends Area2D

@onready var game_manager = %GameManager
@onready var animation_player = $AnimationPlayer

#var vertical_move = 32 #px
#var vertical_move_duration =  0.3 #s
#
#var vanishing_duration = 0.5 #s

func _on_body_entered(body: Node2D) -> void:
	game_manager.add_point()
	animation_player.play("pickup")


#func pickup_animation():
	## Tạo tween
	#var tween = create_tween()
	#tween.set_parallel(true)
#
	## 1. Nảy lên (di chuyển coin lên 16 pixel trong 0.3s)
	#tween.tween_property(self, "position:y", position.y - vertical_move, vertical_move_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
#
	## 2. Mờ dần (alpha -> 0 trong 0.5s)
	#tween.tween_property(self, "modulate:a", 0.0, vanishing_duration)
#
	## 3. Sau khi tween xong thì xóa node
	#tween.finished.connect(func(): queue_free())
