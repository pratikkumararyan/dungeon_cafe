extends CharacterBody2D

enum State { IDLE, CHASE, HIT, DEAD }

@export var health := 100
@export var speed := 40.0
const KNOCKBACK_DISTANCE := 40.0

var state := State.IDLE
var last_direction: Vector2 = Vector2.DOWN
var target: Node2D = null
var knockbackTween: Tween
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _process(delta: float) -> void:
	if state == State.DEAD or state == State.HIT:
		return

	if target:
		var direction = global_position.direction_to(target.global_position)
		velocity = direction * speed
		move_and_slide()
		state = State.CHASE

		if abs(direction.x) > abs(direction.y):
			last_direction = Vector2(sign(direction.x), 0)
		else:
			last_direction = Vector2(0, sign(direction.y))

		_playAnimation("walk")
	else:
		velocity = Vector2.ZERO
		state = State.IDLE

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
