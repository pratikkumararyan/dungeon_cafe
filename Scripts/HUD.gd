extends Control

@onready var silver_key: Control = $"Silver Key/Count"
@onready var gold_key: Control = $"Gold Key/Count"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	silver_key.text = str(PlayerStats.silver_keys)
	gold_key.text = str(PlayerStats.gold_keys)
