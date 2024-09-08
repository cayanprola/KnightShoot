extends Node

var game_timer: Timer
var time_left: float = 600  # 10 minutes in seconds
var weapon_timers: Dictionary = {}
var shuriken_timer: Timer = null
var shuriken_active = false  # To track the shuriken's current state
var fireball_timer: Timer = null
var fireball_active = false  # To track the fireball's current state
var spawn_timer: Timer = null
var is_paused: bool = false

@export var potion_scene: PackedScene
@export var gold_coin_scene: PackedScene
@export var spawn_radius: float = 1200.0
@export var min_spawn_time: float = 20.0
@export var max_spawn_time: float = 60.0

signal fireball_timeout()
signal shuriken_timeout()

@onready var player = get_tree().get_root().get_node("Game/Player")

func _ready():
	shuriken_timer = Timer.new()
	shuriken_timer.wait_time = 5.0  # Set the interval for 5 seconds
	shuriken_timer.one_shot = false  # Make it repeat
	shuriken_timer.connect("timeout", Callable(self, "_on_ShurikenTimer_timeout"))
	add_child(shuriken_timer)  # Add the timer to the scene tree

	fireball_timer = Timer.new()
	fireball_timer.wait_time = 5.0  # Set the interval for 5 seconds (adjust as necessary)
	fireball_timer.one_shot = false  # Make it repeat
	fireball_timer.connect("timeout", Callable(self, "_on_FireballTimer_timeout"))
	add_child(fireball_timer)  # Add the timer to the scene tree
	
	spawn_timer = Timer.new()
	spawn_timer.one_shot = true
	spawn_timer.connect("timeout", Callable(self, "spawn_item_randomly"))
	add_child(spawn_timer)
	spawn_item_randomly()

func start_game_timer(duration: float):
	time_left = duration
	if game_timer:
		game_timer.queue_free()  # Remove any existing game timer
	game_timer = Timer.new()
	game_timer.one_shot = false
	game_timer.wait_time = 1.0  # Trigger every second
	game_timer.connect("timeout", Callable(self, "_on_game_timer_timeout"))
	add_child(game_timer)
	game_timer.start()
	print("Game timer started with time left:", time_left)

func _on_game_timer_timeout():
	time_left -= 1
	if time_left <= 0:
		time_left = 0
		var game_node = get_tree().get_root().get_node("Game")
		if game_node:
			game_node._end_game()
		game_timer.stop()

func start_weapon_timer(weapon_id: int, lifetime: float) -> void:
	if weapon_timers.has(weapon_id):
		return
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = lifetime
	weapon_timers[weapon_id] = timer
	add_child(timer)
	timer.connect("timeout", Callable(self, "_on_weapon_timer_timeout").bind(weapon_id))
	timer.start()

func _on_weapon_timer_timeout(weapon_id: int) -> void:
	if weapon_timers.has(weapon_id):
		weapon_timers[weapon_id].queue_free()
		weapon_timers.erase(weapon_id)
		for node in get_tree().get_nodes_in_group("weapons"):
			if node.get_instance_id() == weapon_id:
				if node.has_method("remove_weapon"):
					node.call("remove_weapon")
				break

func get_time_left() -> float:
	return time_left

func pause_game_timer():
	if game_timer:
		game_timer.stop()

func resume_game_timer():
	if game_timer:
		game_timer.start()

func start_shuriken_timer():
	if shuriken_timer:
		shuriken_timer.start()

func start_fireball_timer():
	if fireball_timer:
		fireball_timer.start()

func _on_FireballTimer_timeout():
	if fireball_active:
		fireball_active = false
	else:
		fireball_active = true
		emit_signal("fireball_timeout", fireball_active)  # Pass the state to the player

func _on_ShurikenTimer_timeout():
	shuriken_active = not shuriken_active  # Toggle the state of the shuriken
	emit_signal("shuriken_timeout", shuriken_active)  # Pass the state to the player

func stop_shuriken_timer():
	if shuriken_timer:
		shuriken_timer.stop()

func stop_fireball_timer():
	if fireball_timer:
		fireball_timer.stop()

func pause_spawn():
	is_paused = true
	if spawn_timer:
		spawn_timer.stop()

func resume_spawn():
	is_paused = false
	spawn_item_randomly()  # Start spawning items again

func spawn_item_randomly():
	if is_paused:
		return  # Don't spawn items if the game is paused

	var random_time = randf_range(min_spawn_time, max_spawn_time)
	spawn_timer.start(random_time)

	if is_paused:
		return  # Check again after the timer to see if we're still paused

	var item = _get_random_item()
	if item:
		var spawn_position = _get_random_position_around_player()
		item.global_position = spawn_position
		add_child(item)

func _get_random_item() -> Area2D:
	if not potion_scene or not gold_coin_scene:
		print("Scenes not assigned!")
		return null  # Return to prevent errors

	if randi() % 2 == 0:
		return potion_scene.instantiate() as Area2D
	else:
		return gold_coin_scene.instantiate() as Area2D

func _get_random_position_around_player() -> Vector2:
	if player == null:
		print("Player node not found!")
		return Vector2.ZERO  # Return a default position to prevent crashes

	var angle = randf() * PI * 2
	var distance = randf() * spawn_radius
	return player.global_position + Vector2(cos(angle), sin(angle)) * distance
