# PhysicUtil.gd
extends Node

func tween_to(target: Object, property: String, final_val, duration: float, trans:=Tween.TRANS_QUAD, ease:=Tween.EASE_OUT):
	var tween = get_tree().create_tween()
	tween.tween_property(target, property, final_val, duration) \
		.set_trans(trans) \
		.set_ease(ease)
	return tween
