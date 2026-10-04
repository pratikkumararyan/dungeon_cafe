@tool
extends CharacterBody2D

enum State { IDLE, CHASE, ATTACK, HIT, DEAD }

# Consts
const KNOCKBACK_TIME := 0.5

# Exported stats
@export var health := 100
@export var speed := 30.0
@export var attackRange := 100.0
@export var attackCooldown := 2.0
@export var attackDamage := 10
@export var KNOCKBACK_DISTANCE := 50.0
@export var ATTACK_RAY_COUNT := 100
@export var ATTACK_SPREAD_DEGREES := 140.0

# Exported detection ranges (editable per instance)
@export var innerRangeRadius := 150.0:
	set(value):
		innerRangeRadius = value
		if is_node_ready():
			_applyRanges()

@export var outerRangeRadius := 250.0:
	set(value):
		outerRangeRadius = value
		if is_node_ready():
			_applyRanges()

# State
var state := State.IDLE
var last_direction: Vector2 = Vector2.DOWN
var target: Node2D = null
var canAttack := true
var attackId := 0
var knockbackTween: Tween
var knockbackVelocity := Vector2.ZERO

# Nodes
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var inner_radi: CollisionShape2D = $innerRange/radi
@onready var outer_radi: CollisionShape2D = $outerRange/radi

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	inner_radi.shape = inner_radi.shape.duplicate()
	outer_radi.shape = outer_radi.shape.duplicate()
	_applyRanges()

func _applyRanges() -> void:
	inner_radi.shape.radius = innerRangeRadius
	outer_radi.shape.radius = outerRangeRadius

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	queue_redraw()
	
	if state == State.HIT or state == State.DEAD:
		move_and_collide(knockbackVelocity * delta)

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

func _draw() -> void:
	if state != State.ATTACK:
		return

	var spreadRadians = deg_to_rad(ATTACK_SPREAD_DEGREES)

	for i in ATTACK_RAY_COUNT:
		var t = float(i) / (ATTACK_RAY_COUNT - 1)
		var angle = lerp(-spreadRadians / 2.0, spreadRadians / 2.0, t)
		var rayDirection = last_direction.rotated(angle)
		draw_line(Vector2.ZERO, rayDirection * (attackRange / 2), Color.GHOST_WHITE, 1.0)

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
		var rayEnd = global_position + rayDirection * attackRange

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
	knockbackVelocity = knockback_direction * KNOCKBACK_DISTANCE * 4.0 / KNOCKBACK_TIME
	knockbackTween = create_tween()
	knockbackTween.set_ease(Tween.EASE_OUT)
	knockbackTween.set_trans(Tween.TRANS_CUBIC)
	knockbackTween.tween_property(self, "knockbackVelocity", Vector2.ZERO, KNOCKBACK_TIME)

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
