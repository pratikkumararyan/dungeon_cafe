extends CharacterBody2D

@export var health := 100
const KNOCKBACK_DISTANCE := 40.0

var last_direction: Vector2 = Vector2.DOWN
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var dead := false

func _process(delta: float) -> void:
	if velocity != Vector2.ZERO:
		if abs(velocity.x) > abs(velocity.y):
			last_direction = Vector2(sign(velocity.x), 0)
		else:
			last_direction = Vector2(0, sign(velocity.y))

	if health <= 0:
		dead = true
		_playAnimation("die")
		await animated_sprite_2d.animation_finished
		queue_free()			

func takeDamage(amount: int, attacker_position: Vector2) -> void:
	if !dead:
		health -= amount
		
		var knockback_direction = (global_position - attacker_position).normalized()
		var target_position = global_position + knockback_direction * KNOCKBACK_DISTANCE
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(self, "global_position", target_position, 0.5)
		
		$"Blood Particle Effect/CPUParticles2D".emitting = true
		_playAnimation("hit")
		
		# print("Damage taken: ", amount)
		# print("Health left: ", health)

func _playAnimation(name: String) -> void:
	match last_direction:
			Vector2.UP: animated_sprite_2d.play(name + "Forward")
			Vector2.DOWN: animated_sprite_2d.play(name + "Backward")
			Vector2.LEFT: animated_sprite_2d.play(name + "Left")
			Vector2.RIGHT: animated_sprite_2d.play(name + "Right")
