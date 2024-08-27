extends CharacterBody2D

@onready var player: CharacterBody2D = null
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@export var death_animation_duration = 0.5
@export var gem_scene: PackedScene
@export var mob_damage = 15
@export var knockback_strength = 100  # Strength of knockback applied when hit

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

		# Separate from other mobs to avoid getting stuck in a line
		velocity += _avoid_other_mobs()

		move_and_slide()
	else:
		print("Player node not found!")

func _avoid_other_mobs() -> Vector2:
	var separation = Vector2.ZERO
	var neighbor_count = 0
	var mobs = get_tree().get_nodes_in_group("enemies")
	
	for mob in mobs:
		if mob != self:
			var distance = global_position.distance_to(mob.global_position)
			if distance < 50:  # If another mob is within a certain distance
				var direction_away = global_position.direction_to(mob.global_position).normalized()
				separation -= direction_away  # Move away from the other mob
				neighbor_count += 1

	if neighbor_count > 0:
		separation = separation / neighbor_count
		separation = separation.normalized() * 100  # Strength of the separation force
	return separation

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
	is_hit = false

