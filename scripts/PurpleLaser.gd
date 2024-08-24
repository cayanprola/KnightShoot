extends "res://scripts/BaseWeapon.gd"

@export var laser_damage = 10
@export var laser_speed = 400
@export var laser_direction = Vector2(1, 0)  # Default direction is right

func _ready():
	add_to_group("weapons")
	connect("body_entered", Callable(self, "_on_body_entered"))

func _physics_process(delta):
	global_position += laser_direction * laser_speed * delta
	if is_outside_screen():
		remove_weapon()

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		body.take_damage(laser_damage)
