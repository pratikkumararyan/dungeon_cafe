extends CharacterBody2D


const SPEED = 150.0
const JUMP_VELOCITY = -400.0

var last_direction: Vector2 = Vector2.DOWN
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	_process_movement()
	move_and_slide()
	
func _process_movement():
	var direction := Input.get_vector("pLeft", "pRight", "pForward", "pBackward")
	if direction != Vector2.ZERO:
		velocity = direction * SPEED
		last_direction = direction
	else:
		velocity = Vector2.ZERO
	_process_animation(last_direction)
	
func _process_animation(direction: Vector2):
	if velocity != Vector2.ZERO:
		play_animation("run", direction)
	else:
		play_animation("idle", direction)

func play_animation(prefix: String, dir: Vector2) -> void:
	if dir.x != 0:
		animated_sprite_2d.flip_h = dir.x < 0 
		animated_sprite_2d.play(prefix + "Right")
	elif dir.y < 0:
		animated_sprite_2d.play(prefix + "Forward")
	elif dir.y > 0:
		animated_sprite_2d.play(prefix + "Backward")
