# Camera2D.gd
extends Camera2D

var max_offset: float = 50
var y_offset: float = 0
var smoothing: float = 1.2
var current_tween: Tween = null
var tween: Tween
@onready var player = get_parent() as Node2D

func _ready():
	if player == null:
		return

func _process(delta: float) -> void:
	if player == null:
		return	
	var direction = 0
	if "direction" in player:
		direction = player.direction

	var desired_pos = player.global_position + Vector2(direction * max_offset, y_offset)
	move_camera(desired_pos)
	

func move_camera(target_pos: Vector2):
	if current_tween != null:
		current_tween.kill()  # dừng tween cũ
	current_tween = create_tween()
	current_tween.tween_property(self, "global_position", target_pos, smoothing).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
