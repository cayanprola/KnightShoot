extends CharacterBody2D

@onready var player: CharacterBody2D = null
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@export var death_animation_duration = 0.5
@export var gem_scene: PackedScene
@export var mob_damage = 15
@export var knockback_strength = 100  # Strength of knockback applied when hit
@export var separation_radius = 50  # Distance to consider for avoidance

var health = 10
var is_dead = false
var is_hit = false

func _ready():
	player = get_node("/root/Game/Player")
	if not player:
		print("Player node not found!")
	else:
		add_to_group("enemies")
	collision_shape.set_deferred("disabled", false)  # Ensure collision is enabled
	
	# Start playing the Walk animation by default
	animated_sprite.play("Walk")

func _physics_process(delta):
	if is_dead:
		return

	if player:
		# Calculate direction towards the player
		var direction = global_position.direction_to(player.global_position)
		
		# Apply a small random offset to avoid mobs clustering in a single line
		var jitter = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 10
		velocity = direction * 120 + jitter

		# Apply a simple avoidance mechanism
		velocity += _simple_avoidance()

		move_and_slide()

		# Ensure hit animation returns to walk animation if it was played
		if not is_hit and not animated_sprite.is_playing():
			animated_sprite.play("Walk")
	else:
		print("Player node not found!")

func _simple_avoidance() -> Vector2:
	var mobs = get_tree().get_nodes_in_group("enemies")
	var avoidance = Vector2.ZERO

	for mob in mobs:
		if mob != self:
			var distance = global_position.distance_to(mob.global_position)
			if distance < separation_radius:  # Only consider nearby mobs
				avoidance += (global_position - mob.global_position).normalized() / distance

	# Normalize and scale the avoidance vector to keep it effective but lightweight
	return avoidance.normalized() * 50  # Adjust the scale factor as needed

func take_damage(amount, knockback_vector = Vector2.ZERO):
	if is_dead:
		return
	
	health -= amount
	
	if health > 0:
		_play_hit_animation()  # Play hit animation if the mob is still alive
		_apply_knockback(knockback_vector)  # Apply knockback when hit
	else:
		kill_mob()

func _apply_knockback(knockback_vector: Vector2):
	if knockback_vector.length() > 0:
		velocity += knockback_vector.normalized() * knockback_strength

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
	await animated_sprite.animation_finished  # Wait for the hit animation to finish
	is_hit = false
	animated_sprite.play("Walk")
