extends Area2D

@export var xp_value = 10  # XP value for gems

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.add_experience(xp_value)
		queue_free()
