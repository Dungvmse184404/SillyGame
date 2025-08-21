#player.gd
extends CharacterBody2D

const SPEED = 90.0
const JUMP_VELOCITY = -280.0
const GRAVITY = 800.0
const MAX_KNOCKBACK = 300
const MAX_KNOCKBACK_SPEED = 350
var last_on_floor_time: float = 0.0

enum PlayerState { IDLE, RUN, JUMP, HIT, DEAD, ROLL, DASH, DODGE}
const LOCK_INPUT_STATES = [
	PlayerState.HIT,
	PlayerState.DEAD,
	PlayerState.ROLL,
	PlayerState.DASH,
	PlayerState.DODGE
]
const MANEUVER_STATES = [
	PlayerState.ROLL,
	PlayerState.DASH,
	PlayerState.DODGE
]
var state = PlayerState.IDLE
var debug_properties: Array[String] = [
	"health",
	"state",
	"invincible"
]

var health
var invincible = false
var hit_invincible_duration = 0.4
var dead_duration = 0.8

var roll_invincible_duration = 0.5
var roll_invincible_delay = 0.1
var roll_force := 280.0
var roll_tween_duration = 0.4
var roll_tween_min_speed = 60

var dash_force := 400.0
var dahs_invincible_duration = 0.5

var dodge_invincible_duration = 0.4
var dodge_force := 100.0
var dodge_velocity_y = -80

var coyote_timer: float = 0.0
var coyote_time: float = 2.0

var direction = 0
var delay_frames = 0

@onready var animated_player = $AnimatedSprite2D
@onready var timer = $DieAnimaionTimer
@onready var slime = %Slime
@onready var camera = $Camera2D

@onready var label = $Label

@onready var invincible_timer = $InvincibleTimer
func _ready():
	health = GameManager.player_hp

func _physics_process(delta: float) -> void:	
	# trọng lực
	update_coyote_time(delta, coyote_time)
	
	if not is_on_floor():
		velocity += get_gravity() * (delta * 1.2)

	play_state()

	if state == PlayerState.DEAD:
		move_and_slide()
		return

	# nhảy
	if Input.is_action_just_pressed("jump") and use_coyote(coyote_time) and state != PlayerState.DEAD:
		velocity.y = JUMP_VELOCITY
		coyote_timer = 0  # reset coyote
		await TimeUtil.delay_frames(2)
		state = PlayerState.JUMP

	if Input.is_action_just_pressed("roll") and state != PlayerState.DEAD:
		if is_on_floor() and direction != 0 and use_coyote(coyote_time):
			print("roll")
			roll()
		elif is_on_floor() and direction == 0 and use_coyote(coyote_time):
			print("dodge")
			dodge()
		#else:
			#print("dash")
			#dash()

	coyote_timer = 0

	# di chuyển
	direction = Input.get_axis("move_left", "move_right")
	if state not in LOCK_INPUT_STATES and is_on_floor():
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
	if state not in LOCK_INPUT_STATES:
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	
	move_and_slide()
	

func dodge():
	if state in LOCK_INPUT_STATES:
		return
	state = PlayerState.DODGE

	var dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT if animated_player.flip_h else Vector2.LEFT

	dir = dir.normalized()
	velocity = Vector2(dir.x * dodge_force, dodge_velocity_y)
	
	invincible = true
	await TimeUtil.wait_until_on_floor(self)
	invincible = false
	velocity = Vector2.ZERO
	state = PlayerState.IDLE
	#set_invincible(dodge_invincible_duration)


func roll():
	if state in LOCK_INPUT_STATES:
		return
	state = PlayerState.ROLL

	# hướng lăn
	var dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT if animated_player.flip_h else Vector2.LEFT

	dir = dir.normalized()

	velocity = Vector2(dir.x * roll_force, velocity.y)

	var tween = get_tree().create_tween()
	tween.tween_property(self, "velocity:x", (roll_tween_min_speed * direction), roll_tween_duration) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(roll_invincible_delay).timeout
	set_invincible(roll_invincible_duration)


func dash():
	if state in LOCK_INPUT_STATES:
		return
	state = PlayerState.DASH
	
	# hướng lăn
	var dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir == Vector2.ZERO:
		dir = Vector2.LEFT if animated_player.flip_h else Vector2.RIGHT # ngược lại roll

	dir = dir.normalized()

	velocity = Vector2(dir.x * dash_force, velocity.y)

	set_invincible(roll_invincible_duration + roll_invincible_delay)


func update_coyote_time(delta: float, duration: float) -> void:
	if is_on_floor():
		coyote_timer = duration
	else:
		coyote_timer = max(coyote_timer - delta, 0)

func use_coyote(duration: float) -> bool:
	return coyote_timer > 0 and coyote_timer <= duration



func take_damage(damage: DamageData):
	if invincible or state == PlayerState.DEAD:
		return
	$HurtSound.play()

	state = PlayerState.HIT
	set_invincible(hit_invincible_duration)

	# tính sát thương
	health -= calculated_damage(damage.amount, damage.type)

	# tính knockback
	knockback(damage.source_position, damage.knockback_force, damage.source_velocity)

	if health <= 0:
		die()

	else:
		if state == PlayerState.HIT:
			await TimeUtil.wait_until_on_floor(self)
			state = PlayerState.IDLE

func set_invincible(duration: float):
	invincible = true
	invincible_timer.start(duration)


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
	#print("knockback speed: " + str(speed))
	# Hệ số knockback dựa trên tốc độ
	var speed_scale = 1.0 + (speed / 100.0)  # chỉnh 100.0 để cân bằng 	
	var final_force = knockback_force * speed_scale
	
	final_force = clamp(final_force, 0, MAX_KNOCKBACK)
	velocity = dir * final_force
	velocity.y = -abs(clamp(final_force, 0, MAX_KNOCKBACK)) # thêm lực bật lên

	#print("knockback force: " + str(final_force) + "\n") #debug
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

	timer.start(dead_duration)


func _on_timer_timeout():
	#Engine.time_scale = 0.8
	get_tree().reload_current_scene()


func player_status(): # debug
	label.text = "HP: " + str(health) + "\n" + "state: " + str(state)
	if invincible:
		label.text = "is invincible"





func play_state():
	var anim = ""
	match state:
		PlayerState.IDLE: anim = "Idle"
		PlayerState.RUN: anim = "run"
		PlayerState.JUMP: anim = "jump"
		PlayerState.DEAD: anim = "dead"
		PlayerState.HIT: anim = "hit"
		PlayerState.ROLL: anim = "roll"
		PlayerState.DASH: anim = "dash"
		PlayerState.DODGE: anim = "dodge"

	if animated_player.animation != anim:
		animated_player.play(anim)
# effect buildup


func _on_invincible_timer_timeout() -> void:
	invincible_timer.stop()
	invincible = false
	state = PlayerState.IDLE
