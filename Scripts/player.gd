extends CharacterBody2D

const SPEED = 150.0
const JUMP_VELOCITY = -400.0

var last_direction: Vector2 = Vector2.DOWN
var attacking := false

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_range: Area2D = $AttackRange

var rangeBase: Vector2

func _ready() -> void:
	rangeBase = attack_range.position

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("pAttack1") and $Cooldown.is_stopped() and not attacking:
		_attack()
	_process_movement()
	move_and_slide()

func _attack() -> void:
	attacking = true
	play_animation("attack", last_direction)
	$Cooldown.start()
	await animated_sprite_2d.animation_finished
	attacking = false

func _process_movement():
	if attacking:
		velocity = Vector2.ZERO
		return
		
	var direction := Input.get_vector("pLeft", "pRight", "pForward", "pBackward")

	if direction != Vector2.ZERO:
		velocity = direction * SPEED
		last_direction = direction
	else:
		velocity = Vector2.ZERO
	
	if not attacking:
		_process_animation(last_direction)
	
	updateRangeOffset()

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

func updateRangeOffset() -> void:
	var x := rangeBase.x
	var y := rangeBase.y

	if last_direction.x != 0:
		attack_range.position = Vector2(-x * signf(last_direction.x), y)
	elif last_direction.y < 0:
		attack_range.position = Vector2(y - 2.5, x)
	else:
		attack_range.position = Vector2(-y - 3.5, -x)

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation.begins_with("attack"):
		attacking = false
