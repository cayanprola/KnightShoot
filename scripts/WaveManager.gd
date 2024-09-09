extends Node

@export var waves = []
@onready var player = get_tree().get_root().get_node("Game/Player")
@onready var mob_spawner = $"../MobSpawner"

var current_wave_index = 0
var wave_timer: Timer = Timer.new()
var wave_in_progress = false

func _ready():
	wave_timer.one_shot = true
	add_child(wave_timer)

	# Define waves here
	waves = [
		{
			"mobs": [preload("res://scenes/FlyingEye.tscn")],
			"mob_health": { preload("res://scenes/FlyingEye.tscn"): 30 },
			"spawn_interval": 1,
			"max_wave_mobs": 250,
			"max_mobs": 230,
			"duration": 60
		},
		{
			"mobs": [preload("res://scenes/Crow.tscn")],
			"mob_health": { preload("res://scenes/Crow.tscn"): 60 },
			"spawn_interval": 0.5,
			"max_wave_mobs": 250,
			"max_mobs": 230,
			"duration": 60
		},
		{
			"mobs": [preload("res://scenes/Orc.tscn")],
			"mob_health": { preload("res://scenes/Orc.tscn"): 120 },
			"spawn_interval": 0.3,
			"max_wave_mobs": 300,
			"max_mobs": 230,
			"duration": 60
		},
		{
			"mobs": [preload("res://scenes/Necromancer.tscn")],
			"mob_health": { preload("res://scenes/Necromancer.tscn"): 160 },
			"spawn_interval": 0.5,
			"max_wave_mobs": 200,
			"max_mobs": 230,
			"duration": 60
		},
		{
			"mobs": [preload("res://scenes/FlyingEye.tscn")],
			"mob_health": { preload("res://scenes/FlyingEye.tscn"): 50 },
			"spawn_interval": 0.3,
			"max_wave_mobs": 400,
			"max_mobs": 230,
			"duration": 60
		},
		{
			"mobs": [preload("res://scenes/Skeleton.tscn")],
			"mob_health": { preload("res://scenes/Skeleton.tscn"): 160 },
			"spawn_interval": 0.4,
			"max_wave_mobs": 300,
			"max_mobs": 230,
			"duration": 60
		},
		{
			"mobs": [preload("res://scenes/Crow.tscn")],
			"mob_health": { preload("res://scenes/Crow.tscn"): 160 },
			"spawn_interval": 0.25,
			"max_wave_mobs": 500,
			"max_mobs": 230,
			"duration": 60
		},
		{
			"mobs": [preload("res://scenes/Mushroom.tscn")],
			"mob_health": { preload("res://scenes/Mushroom.tscn"): 120 },
			"spawn_interval": 0.25,
			"max_wave_mobs": 300,
			"max_mobs": 230,
			"duration": 60
		},
		{
			"mobs": [preload("res://scenes/Orc.tscn")],
			"mob_health": { preload("res://scenes/Orc.tscn"):120 },
			"spawn_interval": 0.2,
			"max_wave_mobs": 400,
			"max_mobs": 230,
			"duration": 60
		},
		{
			"mobs": [preload("res://scenes/OldGuardian.tscn")],
			"mob_health": { preload("res://scenes/OldGuardian.tscn"): 450 },
			"spawn_interval": 0.4,
			"max_wave_mobs": 300,
			"max_mobs": 230,
			"duration": 100
		},
	]

	start_next_wave()

# Stars the wave with the corect data if there are waves to be spawned
func start_next_wave():
	if current_wave_index < waves.size():
		var wave_data = waves[current_wave_index]
		wave_in_progress = true
		mob_spawner.start_wave(wave_data)
		wave_timer.start(wave_data.duration)
		wave_timer.connect("timeout", Callable(self, "_on_wave_timeout"))
		print("Wave ", current_wave_index + 1, " started!")
	else:
		print("All waves completed!")

func _on_wave_timeout():
	wave_in_progress = false
	current_wave_index += 1
	mob_spawner.stop_wave()
	wave_timer.disconnect("timeout", Callable(self, "_on_wave_timeout"))  # Disconnect the signal to avoid multiple connections
	if current_wave_index < waves.size():
		start_next_wave()
	else:
		print("All waves completed!")
