extends Area2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

const DAMAGE_FRAMES = [0, 1, 3]

func _ready() -> void:
	animated_sprite_2d.frame_changed.connect(_on_frame_changed)

func _on_frame_changed() -> void:
	if animated_sprite_2d.frame in DAMAGE_FRAMES:
		DamageOverlappingPlayer()

func DamageOverlappingPlayer() -> void:
	for body in get_overlapping_bodies():
		if body.name == "Player":
			body.takeDamage(1)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" and animated_sprite_2d.frame in DAMAGE_FRAMES:
		body.takeDamage(1)
