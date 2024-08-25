extends CharacterBody2D

@onready var player: CharacterBody2D = null
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@export var death_animation_duration = 0.5
@export var gem_scene: PackedScene
@export var mob_damage = 15

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
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * 120

		# Apply a small random offset to avoid mobs clustering in a single line
		var jitter = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 10
		velocity += jitter

		move_and_slide()
	else:
		print("Player node not found!")

func _on_body_entered(body):
	if body.is_in_group("weapons"):
		body.take_damage(mob_damage)

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
	is_hit = false
