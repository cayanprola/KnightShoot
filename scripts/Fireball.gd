extends "res://scripts/BaseWeapon.gd"

@export var fireball_damage = 10
@export var fireball_speed = 300
@export var fireball_lifetime = 3.0  # Fireball lasts 3 seconds
var fireball_direction = Vector2(1, 0)  # Default direction is right

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D  # Ensure this node exists in your fireball scene
@onready var lifetime_timer: Timer = Timer.new()

func _ready():
	add_to_group("weapons")
	connect("body_entered", Callable(self, "_on_body_entered"))
	
	# Start the animation when the fireball is ready
	animated_sprite.play("Shoot")

	# Set up the lifetime timer
	lifetime_timer.wait_time = fireball_lifetime
	lifetime_timer.one_shot = true
	lifetime_timer.connect("timeout", Callable(self, "_on_lifetime_timeout"))
	add_child(lifetime_timer)
	lifetime_timer.start()

func _physics_process(delta):
	# Move the fireball in the assigned direction
	global_position += fireball_direction * fireball_speed * delta
	if is_outside_screen():
		remove_weapon()

	# Rotate the fireball to face the direction it's moving
	rotation = fireball_direction.angle()

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		body.take_damage(fireball_damage)
		remove_weapon()

func _on_lifetime_timeout():
	remove_weapon()
