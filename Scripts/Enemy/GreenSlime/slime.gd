# Slime.gd
extends CharacterBody2D

enum SlimeState { IDLE, CHASING, ATTACK, HURT, DEAD, SPAWN }
enum SlimeEnemy { Player, Ally, Dummy }
enum AttackType { JUMP, DIRECT, POISON }

# khai báo
var direction = 1

#var speed = 0
#var chasing_speed = 0
#const DEFAULT_SPEED = 0

var speed = 20
var chasing_speed = 80
const DEFAULT_SPEED = 20

const JUMP_VELOCITY = -200 
var jump_speed_x = 0.5
const MAX_DX = 90
const MAX_DY = 30

var debug_properties: Array[String] = [
	"state",
	"forget_timer.time_left",
	"attack_timer.time_left"
]

#thông export của slime qua cho ATTACK
@export var damage_amount = 10
@export var damage_type = DamageData.Type.PHYSICAL
@export var knockback_force = 60
#@export var source_position = null 
@export var source_velocity = velocity

@onready var forget_timer = $ForgetTimer
var forgot_time = 3.0

@onready var track_timer = $TrackTimer
var track_delay = 0.2

@onready var attack_timer = $AttackTimer
var ATTACK_COOLDOWN = 1.6

var attack_delay = 0.3
var attack_velocity = null
var landing_delay = 0.6
const GRAVITY = 800
var state = SlimeState.IDLE 
var player = null # Tham chiếu đến người chơi
var target = null
var attack_type = null

@onready var animated_player = $AnimatedSprite2D
@onready var view_range = $ViewRange
@onready var VIEW_RANGE: float
@onready var jump_attack_range = view_range.target_position.length() * 0.70
@onready var direct_attack_range = view_range.target_position.length() * 0.00
#@onready var poision_attack_range = view_range.target_position.length() * 0.90

@onready var hitbox_left = $Damagezone/SlimeHitboxLeft
@onready var hitbox_right = $Damagezone/SlimeHitboxRight
@onready var ray_cast_right = $RayCastRight
@onready var ray_cast_left = $RayCastLeft
@onready var animation_direction = $AnimatedSprite2D

@onready var rich_label = $RichTextLabel
@onready var label = $Label

var saw_player = false
var can_attack = true

var frame_counter = 0 
#---------------------------------------

func _ready():
	VIEW_RANGE = view_range.target_position.length()
	

func _physics_process(delta: float) -> void:
	#get_status_text()
	# Áp dụng trọng lực
	if not is_on_floor():
		velocity.y += GRAVITY * (delta * 1)

	play_animation()
	# Đổi hướng nếu chạm tường hoặc raycast báo có vật cản
	await TimeUtil.skip_frames(30, func(): ray_cast_director())

	await TimeUtil.skip_frames(5, func(): ray_cast_view_range())

	if not saw_player:
		ray_cast_director()
	elif saw_player and is_instance_valid(player):
		if track_timer.is_stopped():
			track_timer.start(track_delay)

	if state != SlimeState.ATTACK:
		velocity.x = direction * speed

	source_velocity = velocity
	move_and_slide()


# Phát hiện người chơi (trục x)
func ray_cast_view_range():
	if view_range.is_colliding():
		var collider = view_range.get_collider()
		if collider and collider.is_in_group("slime_enemies"):
			if target != collider:
				target = collider
				player = target
			saw_player = true
			forget_timer.start(forgot_time) # restart mỗi lần thấy player
			if state == SlimeState.ATTACK:
				return
			# quyết định attack hay chase dựa trên distance / attack_type
			attack_type = choose_attack_type(target)
			if attack_type != null:
				if can_attack and state != SlimeState.ATTACK:
					state = SlimeState.ATTACK
					match attack_type:
						AttackType.JUMP:
							jump_attack(target)
						AttackType.DIRECT:
							poison_attack()
			else:
				if state != SlimeState.CHASING and state != SlimeState.ATTACK:
					state = SlimeState.CHASING
		return
	if state != SlimeState.IDLE and not saw_player:
		state = SlimeState.IDLE

func direct_attack():
	print("direct_attack")
	attack_timer.start(ATTACK_COOLDOWN)

func poison_attack():
	print("poison_attack")
	attack_timer.start(ATTACK_COOLDOWN)


func get_attack_velocity(target_pos: Vector2, target_velocity: Vector2, time_ahead: float, MAX_DX: float = 200, MAX_DY: float = 120) -> Vector2:
	if target == null:
		return Vector2.ZERO
	# dự đoán vị trí player
	var predicted_pos = target_pos + target_velocity * time_ahead
	var dx = predicted_pos.x - global_position.x
	var dy = predicted_pos.y - global_position.y
	
	dx = clamp(dx, -MAX_DX, MAX_DX)
	dy = clamp(dy, -MAX_DY, MAX_DY)
	
	var vx = dx / time_ahead
	var vy = (dy + 0.5 * GRAVITY * time_ahead * time_ahead) / time_ahead * -1

	return Vector2(vx, vy)


func jump_attack(target: Node):
	if not can_attack:
		return
		
	can_attack = false
	velocity = Vector2.ZERO
	animated_player.play("jump_attack")
	await get_tree().create_timer(attack_delay).timeout
	jump_hitbox_on()
	velocity = get_attack_velocity(target.global_position, target.velocity, jump_speed_x, MAX_DX, MAX_DY)
	
	attack_timer.start(ATTACK_COOLDOWN)

	await TimeUtil.wait_until_on_floor(self)
	landing()
	jump_hitbox_off()


func _on_attack_timer_timeout() -> void:
	attack_timer.stop()
	await TimeUtil.wait_until_on_floor(self)
	target = null
	can_attack = true
	state = SlimeState.CHASING
	

func choose_attack_type(target: Node):
	if target == null or !is_instance_valid(target):
		return null
	var distance = global_position.distance_to(target.global_position)
	
	if distance <= jump_attack_range and distance > direct_attack_range:
		return AttackType.JUMP
	#elif distance <= direct_attack_range:
		#return AttackType.DIRECT
	#elif distance <= poision_attack_range:
		#return AttackType.POISON


func play_animation():
	match state:
		SlimeState.IDLE:
			idle()
		SlimeState.CHASING:
			chasing()
		#SlimeState.ATTACK:
			#attack()
		SlimeState.HURT:
			hurt()

func landing():
	animated_player.play("landing")
	var tween := create_tween()
	tween.tween_property(self, "velocity", Vector2.ZERO, landing_delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	await animated_player.animation_finished
	state = SlimeState.CHASING


func chasing():
	speed = chasing_speed
	saw_player = true
	animated_player.play("chasing")



func hurt():
	#state = SlimeState.HURT	
	animated_player.play("hurt")
	print("slime take damage")

func idle():
	speed = DEFAULT_SPEED
	target = null
	can_attack = true
	saw_player = false
	animated_player.play("idle")


func ray_cast_director():
	if state == SlimeState.IDLE:
		if ray_cast_right.is_colliding():
			set_direction(-1)
		elif ray_cast_left.is_colliding():
			set_direction(1)

func set_direction(new_dir: int):
	if direction == new_dir:
		return
	direction = new_dir
	flip_animation(direction)
	
func flip_animation(direction: int):
	animation_direction.flip_h = (direction == -1)
	view_range.target_position.x = VIEW_RANGE * direction  # 100 là tầm nhìn X (ví dụ)

func get_damage_data() -> DamageData:
	var damage_data = DamageData.new()
	damage_data.amount = damage_amount
	damage_data.type = damage_type
	damage_data.source_position = global_position
	damage_data.knockback_force = knockback_force
	damage_data.source_velocity = source_velocity
	return damage_data


func jump_hitbox_on():
	if direction == 1:
		hitbox_right.disabled = false
	elif direction == -1:
		hitbox_left.disabled = false

func jump_hitbox_off():
	hitbox_left.disabled = true
	hitbox_right.disabled = true


func _on_forget_timer_timeout() -> void:
	forget_timer.stop()
	if target != null and not view_range.is_colliding():
		saw_player = false
		target = null
		state = SlimeState.IDLE
		return

	if view_range.is_colliding():
		var collider = view_range.get_collider()
		if collider == target:
			forget_timer.start(forgot_time)
			return

	# Nếu không trúng target nữa -> quên
	saw_player = false
	target = null
	state = SlimeState.IDLE


func _on_track_timer_timeout() -> void:
	track_timer.stop()
	if is_instance_valid(player):
		if player.global_position.x < global_position.x:
			set_direction(-1)
		else:
			set_direction(1)


func die():
	state = SlimeState.DEAD  
	
	# Xóa va chạm để rơi xuyên map
	var col = get_node_or_null("PlayerHurtbox")
	if col:
		col.queue_free()

	# Áp vận tốc bật ra ngoài
	var death_bounce_y = -250
	velocity = Vector2(velocity.x, death_bounce_y)  
