#player.gd
extends CharacterBody2D

const SPEED = 140.0
const JUMP_VELOCITY = -280.0
const GRAVITY = 800.0
const COYOTE_TIME = 0.08
const MAX_KNOCKBACK = 300
var last_on_floor_time: float = 0.0

enum PlayerState { IDLE, RUN, JUMP, HIT, DEAD }
var state = PlayerState.IDLE

var health
var invincible = false
var invincible_duration = 0.3

#var is_dead = false
#var is_jumping = false
#var is_hit = false

var direction = 0
var delay_frames = 0

@onready var animated_player = $AnimatedSprite2D
@onready var timer = $Timer
@onready var slime = %Slime
@onready var camera = $Camera2D

@onready var label = $Label

func _physics_process(delta: float) -> void:	
	# trọng lực
	if not is_on_floor():
		velocity += get_gravity() * (delta * 1.2)

	play_state()

	if state == PlayerState.DEAD:
		move_and_slide()
		return

	# nhảy
	if is_on_floor():
		last_on_floor_time = COYOTE_TIME
	else:
		last_on_floor_time = max(last_on_floor_time - delta, 0)
	if Input.is_action_just_pressed("jump") and last_on_floor_time > 0 and state != PlayerState.DEAD:
		velocity.y = JUMP_VELOCITY
		last_on_floor_time = 0  # reset ngay sau khi nhảy

		await TimeUtil.delay_frames(5)
		state = PlayerState.JUMP

	# di chuyển
	direction = Input.get_axis("move_left", "move_right")
	if state != PlayerState.HIT and is_on_floor():
		if direction != 0:
			state = PlayerState.RUN 
		if direction == 0:
			state = PlayerState.IDLE
	# animation
	# lật animation theo hướng di chuyển
	if direction > 0:
		animated_player.flip_h = false
	elif direction < 0:
		animated_player.flip_h = true

	# Tốc dộ di chuyển
	if state not in [PlayerState.HIT, PlayerState.DEAD]:
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	
	player_status() # debug
	move_and_slide()
	
func _ready():
	health = GameManager.player_hp
	#print("Groups của Player:", get_groups())
	
func take_damage(damage: DamageData):
	# play sound ngay khi hit
	$HurtSound.play()
	# nếu đang bất tử hoặc chết → không nhận damage
	if invincible or state == PlayerState.DEAD:
		return

	# đánh dấu đang hit
	state = PlayerState.HIT
	invincible = true  # bật bất tử tạm thời

	# tính sát thương
	health -= calculated_damage(damage.amount, damage.type)
	#player_status()
	
	# tính knockback
	knockback(damage.source_position, damage.knockback_force, damage.source_velocity)

	if health <= 0:
		die()

	else:
		# Tạo trạng thái bất tử tạm thời
		await get_tree().create_timer(invincible_duration).timeout
		invincible = false
		if state == PlayerState.HIT:
			await TimeUtil.wait_until_on_floor(self)
			state = PlayerState.IDLE  #trở về trạng thái idle sau khi hit


# hàm này tính toán sát thương nhận vào
func calculated_damage(amount: int, type: DamageData.Type) -> float:
	var final_damage = float(amount)
	
	if type == DamageData.Type.PHYSICAL:
		final_damage *= 0.8
	elif type == DamageData.Type.FIRE:
		final_damage *= 1.2 
	elif type == DamageData.Type.ICE:
		final_damage *= 1.1
	elif type == DamageData.Type.LIGTHNING:
		final_damage *= 1.1
	elif type == DamageData.Type.POISON:
		final_damage *= 1.1
	else:
		pass
	return final_damage


func knockback(source_position: Vector2, knockback_force: float, source_velocity: Vector2):
	var dir = (global_position - source_position).normalized() # hướng slime -> player
	var speed = source_velocity.length()
	print(speed)
	# Hệ số knockback dựa trên tốc độ
	var speed_scale = 1.0 + (speed / 100.0)  # chỉnh 100.0 để cân bằng 	
	var final_force = knockback_force * speed_scale
	
	final_force = clamp(final_force, 0, MAX_KNOCKBACK)
	velocity = dir * final_force
	velocity.y = -abs(clamp(final_force, 0, MAX_KNOCKBACK)) # thêm lực bật lên

	print("knockback force: " + str(final_force) + "\n") #debug
	#print("velocity after knockback:", velocity) #debug

func die():
	state = PlayerState.DEAD  
	
	# Xóa va chạm để rơi xuyên map
	var col = get_node_or_null("PlayerHurtbox")
	if col:
		col.queue_free()

	# Áp vận tốc bật ra ngoài
	var death_bounce_y = -250
	velocity = Vector2(velocity.x, death_bounce_y)  

	timer.start(1.0)


func _on_timer_timeout():
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()


func player_status(): # debug
	label.text = "HP: " + str(health) + "\n" + "state: " + str(state)

func play_state():
	var anim = ""
	match state:
		PlayerState.IDLE: anim = "Idle"
		PlayerState.RUN: anim = "run"
		PlayerState.JUMP: anim = "jump"
		PlayerState.DEAD: anim = "dead"
		PlayerState.HIT: anim = "hit"

	if animated_player.animation != anim:
		animated_player.play(anim)
# effect buildup
