extends Node2D

@export var min_spawn_radius = 150
@export var max_spawn_radius = 900
@export var spawn_interval = 1.0
@export var min_mobs_on_screen = 20  # Minimum number of mobs on the screen
@export var max_mobs_on_screen = 25  # Maximum number of mobs on the screen
@export var spawn_interval_adjustment = 0.1  # Amount by which the spawn interval can be adjusted

@onready var player = get_node("/root/Game/Player")
var mobs = []
var mobs_spawned = 0
var spawn_timer: Timer = Timer.new()
var wave_data = null

func _ready():
	spawn_timer.one_shot = false
	add_child(spawn_timer)

func start_wave(data):
	wave_data = data
	mobs_spawned = 0
	spawn_timer.wait_time = data.spawn_interval
	spawn_timer.start()
	spawn_timer.connect("timeout", Callable(self, "_spawn_mob"))
	print("Wave started with mob types: ", data.mobs)

func stop_wave():
	spawn_timer.stop()
	spawn_timer.disconnect("timeout", Callable(self, "_spawn_mob"))  # Manually disconnect the signal
	mobs.clear()
	wave_data = null
	print("Wave stopped!")

func _spawn_mob():
	if wave_data and mobs_spawned < wave_data.max_wave_mobs and mobs.size() < wave_data.max_mobs:
		# Check if the number of mobs is below the minimum threshold
		if mobs.size() < min_mobs_on_screen:
			# Adjust spawn interval to increase spawn rate
			spawn_timer.wait_time = max(0.1, spawn_timer.wait_time - spawn_interval_adjustment)
		elif mobs.size() >= max_mobs_on_screen:
			# Reset spawn interval to default
			spawn_timer.wait_time = wave_data.spawn_interval
		
		var mob_scene = wave_data.mobs[randi() % wave_data.mobs.size()]
		var mob = mob_scene.instantiate()
		mob.health = wave_data.mob_health[mob_scene]  # Assign health to the mob

		# Calculate spawn position
		var spawn_position = _get_random_spawn_position()
		mob.global_position = spawn_position
		add_child(mob)
		mobs.append(mob)
		mobs_spawned += 1

		mob.connect("tree_exited", Callable(self, "on_mob_deleted"))
	else:
		spawn_timer.stop()
		spawn_timer.disconnect("timeout", Callable(self, "_spawn_mob"))  # Manually disconnect when done

func _get_random_spawn_position() -> Vector2:
	var player_position = player.global_position
	var random_angle = randf() * TAU
	var random_distance = min_spawn_radius + randf() * (max_spawn_radius - min_spawn_radius)
	return player_position + Vector2(cos(random_angle), sin(random_angle)) * random_distance

func on_mob_deleted(mob):
	mobs.erase(mob)
	print("Mob deleted, active mobs: ", mobs.size())
	
	# Check if we need to increase spawn rate when a mob is deleted
	if mobs.size() < min_mobs_on_screen:
		spawn_timer.start()  # Ensure the timer is running to keep spawning mobs
