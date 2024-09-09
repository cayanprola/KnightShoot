extends Node2D

@export var max_health = 100
@onready var health_bar: TextureProgressBar = $TextureProgressBar

func _ready():
	health_bar.max_value = max_health

func set_health(health):
	health_bar.value = health

# Set max health for the bar
func set_max_health(new_max_health):
	max_health = new_max_health
	health_bar.max_value = max_health
