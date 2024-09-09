extends CharacterBody2D

@onready var player: CharacterBody2D = null
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@export var death_animation_duration = 0.4
@export var gem_scene: PackedScene
@export var mob_damage = 15
@export var separation_radius = 50

var health = 10
var is_dead = false
var is_hit = false

func _ready():
	player = get_node("/root/Game/Player")
	if not player:
		print("Player node not found!")
	else:
		add_to_group("enemies")
		
	animated_sprite.play("Walk")

func _physics_process(delta):
	if is_dead:
		return

	if player:
		var direction = global_position.direction_to(player.global_position)
		
		# Apply a small random offset to avoid mobs clustering in a single line
		var jitter = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 10
		velocity = direction * 120 + jitter

		# Apply an avoidance mechanism
		velocity += _avoidance()

		move_and_slide()

		# Ensure hit animation returns to walk animation if it was played
		if not is_hit and not animated_sprite.is_playing():
			animated_sprite.play("Walk")
	else:
		print("Player node not found!")


func _avoidance() -> Vector2:
	var mobs = get_tree().get_nodes_in_group("enemies")
	var avoidance = Vector2.ZERO

	for mob in mobs:
		if mob != self:
			var distance = global_position.distance_to(mob.global_position)
			if distance < separation_radius:  # Only consider nearby mobs
				avoidance += (global_position - mob.global_position).normalized() / distance

	# Normalize and scale the avoidance vecto
	return avoidance.normalized() * 50

func take_damage(amount):
	if is_dead:
		return
	
	health -= amount
	
	if health > 0:
		_play_hit_animation()  # Play hit animation if the mob is still alive
	else:
		kill_mob()

func kill_mob():
	if is_dead:
		return

	is_dead = true
	animated_sprite.play("Death")
	collision_shape.set_deferred("disabled", true)  # Disable collision when mob dies
	await get_tree().create_timer(death_animation_duration).timeout
	_drop_gem()
	queue_free()

func _drop_gem():
	var gem = gem_scene.instantiate()
	gem.global_position = global_position
	get_parent().add_child(gem)

func _play_hit_animation():
	if is_hit or is_dead:
		return
	
	is_hit = true
	animated_sprite.play("Hit")
	await animated_sprite.animation_finished  # Wait for the hit animation to finish to play walk again
	is_hit = false
	animated_sprite.play("Walk")
