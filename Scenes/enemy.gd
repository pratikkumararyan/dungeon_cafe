extends CharacterBody2D

@export var health := 100

func takeDamage(amount: int) -> void:
	health -= amount
	print("Damage taken: ", amount)
	print("Health left: ", health)
