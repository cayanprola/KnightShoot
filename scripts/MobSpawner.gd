extends Node2D

@export var min_spawn_radius: float = 150.0
@export var max_spawn_radius: float = 900.0
@onready var player: Node2D = get_node("/root/Game/Player") as Node2D
var spawn_timer: Timer = Timer.new()
var wave_data = null
var min_mobs_on_screen: int = 30
@export var max_mobs_on_screen: int = 120

func _ready():
	spawn_timer.one_shot = false
	add_child(spawn_timer)
	spawn_timer.connect("timeout", Callable(self, "_spawn_mob"))
	print("MobSpawner is ready and spawn timer added.")

func start_wave(data):
	wave_data = data
	spawn_timer.wait_time = wave_data.spawn_interval
	spawn_timer.start()
	print("Wave started with mob types: ", wave_data.mobs)
	print("Spawn interval set to: ", wave_data.spawn_interval)

func stop_wave():
	spawn_timer.stop()
	#get_tree().call_group("active_mobs", "queue_free")
	wave_data = null
	print("Wave stopped and all mobs cleared.")

#Spawn mobs dynamically 
func _spawn_mob():
	var active_mobs_count = get_tree().get_nodes_in_group("active_mobs").size()
	if active_mobs_count < max_mobs_on_screen:
		if active_mobs_count < min_mobs_on_screen:
			spawn_timer.wait_time = max(0.1, wave_data.spawn_interval / 2)  # Increase spawn rate to maitnain difficulty
		else:
			spawn_timer.wait_time = wave_data.spawn_interval

		var mob_scene = wave_data.mobs[randi() % wave_data.mobs.size()]
		var mob = mob_scene.instantiate()
		mob.health = wave_data.mob_health[mob_scene]
		var spawn_position = _get_random_spawn_position()
		mob.global_position = spawn_position
		add_child(mob)
		mob.add_to_group("active_mobs") #Groups usage for mobs tracking
		mob.connect("tree_exited", Callable(self, "on_mob_deleted"))
		print("Mob spawned with health: ", mob.health, " at position: ", spawn_position, 
			  " Total active mobs now: ", active_mobs_count)
	else:
		print("Max mob limit reached. No new mobs spawned.")

func on_mob_deleted(mob):
	print("Mob deleted, remaining active mobs: ", get_tree().get_nodes_in_group("active_mobs").size())

# Get a random spawn position in a radius around the player position
func _get_random_spawn_position() -> Vector2:
	var player_position = player.global_position
	var random_angle = randf() * TAU
	var random_distance = min_spawn_radius + randf() * (max_spawn_radius - min_spawn_radius)
	return player_position + Vector2(cos(random_angle), sin(random_angle)) * random_distance
