extends Area2D

@onready var timer = $Timer

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("die"):
		body.die()
		$TouchSound.play()
	if body.is_in_group("Player"):
		timer.start(0.8)
	
func _on_timer_timeout() -> void:
	#Engine.time_scale = 0.8
	get_tree().reload_current_scene()
