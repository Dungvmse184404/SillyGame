# damage_data.gd
class_name DamageData
extends RefCounted
enum Type {PHYSICAL, POISON, LIGTHNING, FIRE, ICE }

var amount: float = 0.0
var  type: Type = Type.PHYSICAL
var knockback_force: int = 0
var source_position: Vector2 = Vector2.ZERO
var source_velocity: Vector2 = Vector2.ZERO
