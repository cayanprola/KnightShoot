extends "res://scripts/BaseWeapon.gd"

@export var knife_damage = 10
@export var knife_speed = 400
@export var knife_direction = Vector2(1, 0)  # Default direction is right
var has_bounced = false  # Track if the knife has already bounced

func _ready():
	add_to_group("weapons")
	connect("body_entered", Callable(self, "_on_body_entered"))
	rotate_knife_to_direction()
	GlobalTimer.start_weapon_timer(get_instance_id(), 3.5)  # Set a 3.5 second timer for the knife lifetime

func _physics_process(delta):
	global_position += knife_direction * knife_speed * delta

	# Check if the knife is outside the screen and needs to bounce
	if is_outside_screen() and not has_bounced:
		_bounce()
		has_bounced = true  # Mark as bounced so it doesn't bounce again

func _bounce():
	var viewport = get_viewport()
	var viewport_size = viewport.get_visible_rect().size
	var viewport_rect = Rect2(viewport_global_position - viewport_size / 2, viewport_size)
	
	if global_position.x <= viewport_rect.position.x or global_position.x >= viewport_rect.position.x + viewport_rect.size.x:
		knife_direction.x = -knife_direction.x  # Reverse direction on x-axis

	if global_position.y <= viewport_rect.position.y or global_position.y >= viewport_rect.position.y + viewport_rect.size.y:
		knife_direction.y = -knife_direction.y  # Reverse direction on y-axis

	knife_direction = knife_direction.normalized()
	rotate_knife_to_direction()  # Adjust the rotation after bounce

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		body.take_damage(knife_damage)

func rotate_knife_to_direction():
	rotation = knife_direction.angle()
