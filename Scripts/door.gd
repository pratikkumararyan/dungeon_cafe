extends Area2D

@export var target: Node = null
@export var cost_silvers = 0
@export var cost_gold = 0

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" and (PlayerStats.gold_keys >= cost_gold and PlayerStats.silver_keys >= cost_silvers):
		body.global_position = target.global_position

		PlayerStats.gold_keys -= cost_gold
		PlayerStats.silver_keys -= cost_silvers

		cost_gold = 0
		cost_silvers = 0
