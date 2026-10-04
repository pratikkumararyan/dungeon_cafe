extends Area2D

@export var isGold: bool = false
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var playerInRange: bool = false

func _ready() -> void:
	if isGold:
		animated_sprite_2d.play("goldKey")

func _process(delta: float) -> void:
	pass
	
func _on_range_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		playerInRange =  true
		if isGold:
			PlayerStats.gold_keys += 1
		else:
			PlayerStats.silver_keys += 1
		queue_free()

func _on_range_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		playerInRange =  false
