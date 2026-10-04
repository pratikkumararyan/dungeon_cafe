extends CharacterBody2D

enum State { IDLE, CHASE, ATTACK, HIT, DEAD }

@export var health := 100
@export var speed := 30.0
@export var attackRange := 60.0
@export var attackCooldown := 2.0
@export var attackDamage := 10
const KNOCKBACK_DISTANCE := 50.0

const ATTACK_RAY_COUNT := 100
const ATTACK_SPREAD_DEGREES := 60.0
var ATTACK_RAY_LENGTH := 100.0

var state := State.IDLE
var last_direction: Vector2 = Vector2.DOWN
var target: Node2D = null
var canAttack := true
var knockbackTween: Tween
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var inner_radi: CollisionShape2D = $innerRange/radi

const DEBUG_DRAW_RAYS := true
var debugRayHits: Array[bool] = []

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

func _physics_process(delta: float) -> void:
	if state == State.DEAD or state == State.HIT or state == State.ATTACK:
		return

	if target:
		var direction = global_position.direction_to(target.global_position)

		if abs(direction.x) > abs(direction.y):
			last_direction = Vector2(sign(direction.x), 0)
		else:
			last_direction = Vector2(0, sign(direction.y))

		if global_position.distance_to(target.global_position) <= attackRange:
			velocity = Vector2.ZERO
			if canAttack:
				_attack()
			else:
				state = State.IDLE
				_playAnimation("idle")
			return

		velocity = direction * speed
		move_and_slide()
		state = State.CHASE
		_playAnimation("walk")
	else:
		velocity = Vector2.ZERO
		state = State.IDLE
		_playAnimation("idle")

var attackId := 0
func _attack() -> void:
	state = State.ATTACK
	canAttack = false
	attackId += 1
	var myId = attackId
	_playAnimation("attack")
	get_tree().create_timer(attackCooldown).timeout.connect(func(): canAttack = true)

	await animated_sprite_2d.animation_finished
	if myId != attackId or state != State.ATTACK:
		return

	if target and _isTargetInFront() and target.has_method("takeDamage"):
		target.takeDamage(attackDamage)

	state = State.IDLE

func _isTargetInFront() -> bool:
	var spaceState = get_world_2d().direct_space_state
	var spreadRadians = deg_to_rad(ATTACK_SPREAD_DEGREES)

	for i in ATTACK_RAY_COUNT:
		var t = float(i) / (ATTACK_RAY_COUNT - 1)
		var angle = lerp(-spreadRadians / 2.0, spreadRadians / 2.0, t)
		var rayDirection = last_direction.rotated(angle)
		var rayEnd = global_position + rayDirection * ATTACK_RAY_LENGTH

		var query = PhysicsRayQueryParameters2D.create(global_position, rayEnd)
		query.exclude = [get_rid()]
		var result = spaceState.intersect_ray(query)
		if result and result.collider == target:
			return true
	
	return false

func takeDamage(amount: int, attacker_position: Vector2) -> void:
	if state == State.DEAD:
		return

	health -= amount

	var knockback_direction = (global_position - attacker_position).normalized()
	var target_position = global_position + knockback_direction * KNOCKBACK_DISTANCE

	if knockbackTween:
		knockbackTween.kill()
	knockbackTween = create_tween()
	knockbackTween.set_ease(Tween.EASE_OUT)
	knockbackTween.set_trans(Tween.TRANS_CUBIC)
	knockbackTween.tween_property(self, "global_position", target_position, 0.5)

	$"Blood Particle Effect/CPUParticles2D".emitting = true

	if health <= 0:
		state = State.DEAD
		_playAnimation("die")
		await animated_sprite_2d.animation_finished
		queue_free()
		return

	state = State.HIT
	_playAnimation("hit")
	await knockbackTween.finished
	state = State.IDLE

func _playAnimation(name: String) -> void:
	match last_direction:
		Vector2.UP: animated_sprite_2d.play(name + "Forward")
		Vector2.DOWN: animated_sprite_2d.play(name + "Backward")
		Vector2.LEFT: animated_sprite_2d.play(name + "Left")
		Vector2.RIGHT: animated_sprite_2d.play(name + "Right")

func _on_inner_range_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		target = body
		#print ("Player found!")

func _on_outer_range_body_exited(body: Node2D) -> void:
	if body.name == "Player" and target != null:
		target = null
		#print ("Player lost!")
