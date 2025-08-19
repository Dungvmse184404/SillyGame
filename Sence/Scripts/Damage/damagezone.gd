# damagezone.gd
extends Area2D

func _on_body_entered(body: CharacterBody2D) -> void:
	var hit_entity = get_parent() #<-- lấy thông tin người gây sát thương

	if hit_entity and hit_entity.has_method("get_damage_data") and body.has_method("take_damage"):
		var damage_data = hit_entity.get_damage_data()
		body.take_damage(damage_data)
