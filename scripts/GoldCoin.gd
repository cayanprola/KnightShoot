extends Area2D

@export var min_gold: int = 20
@export var max_gold: int = 60
@onready var gold_audio : AudioStreamPlayer2D = $AudioStreamPlayer2D
signal gold_collected(amount: int)

func _ready():
	add_to_group("collectibles")
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body.is_in_group("player"):
		var gold_amount = randi_range(min_gold, max_gold)
		print("Gold Collected: ", gold_amount)
		gold_audio.play()
		body.emit_signal("gold_collected", gold_amount)  # Emit signal with the gold amount to the game
		queue_free()

