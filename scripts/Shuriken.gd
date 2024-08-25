extends "res://scripts/BaseWeapon.gd"

@export var shuriken_damage = 10
@export var shuriken_rotation_speed = PI
@export var shuriken_angle = 0
@export var orbit_radius = 120

func _ready():
	add_to_group("weapons")
	connect("body_entered", Callable(self, "_on_body_entered"))

func _physics_process(delta):
	shuriken_angle += shuriken_rotation_speed * delta
	var orbit_position = Vector2(orbit_radius, 0).rotated(shuriken_angle)
	position = orbit_position  # Just set the position relative to its parent
	if is_outside_screen():
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		body.take_damage(shuriken_damage)
		print("Dealing damage with shuriken: ", shuriken_damage, " to mob with health: ", body.health)

