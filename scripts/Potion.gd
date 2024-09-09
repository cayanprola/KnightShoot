extends Area2D

@export var heal_amount: int = 25

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.health += heal_amount
		body.health = min(body.max_health, body.health)  # Ensure health doesnt exceed max health
		body.health_bar.set_health(body.health)
		queue_free()
