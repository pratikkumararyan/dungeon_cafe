extends CharacterBody2D

@export var health := 100

var last_direction: Vector2 = Vector2.DOWN
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _process(delta: float) -> void:
	if velocity != Vector2.ZERO:
		if abs(velocity.x) > abs(velocity.y):
			last_direction = Vector2(sign(velocity.x), 0)
		else:
			last_direction = Vector2(0, sign(velocity.y))

	if health <= 0:
		match last_direction:
			Vector2.UP: animated_sprite_2d.play("dieForward")
			Vector2.DOWN: animated_sprite_2d.play("dieBackward")
			Vector2.LEFT: animated_sprite_2d.play("dieLeft")
			Vector2.RIGHT: animated_sprite_2d.play("dieRight")
			

func takeDamage(amount: int) -> void:
	health -= amount
	print("Damage taken: ", amount)
	print("Health left: ", health)
