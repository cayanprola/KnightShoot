extends Area2D

var atk_speed = 1
var level = 0
var atk_size = Vector2(1, 1)
var viewport_global_position = Vector2()

func _ready():
	#connect("body_entered", Callable(self, "_on_body_entered"))
	#add_to_group("weapons")
	pass

func _physics_process(delta):
	if is_outside_screen():
		remove_weapon()

func update_viewport(camera_position):
	viewport_global_position = camera_position

func is_outside_screen() -> bool:
	var viewport = get_viewport()
	var viewport_size = viewport.get_visible_rect().size
	var viewport_rect = Rect2(viewport_global_position - viewport_size / 2, viewport_size)
	return not viewport_rect.has_point(global_position)

#func _on_body_entered(body):
	#if body.is_in_group("enemies"):
		#body.take_damage(damage)
		#remove_weapon()

func remove_weapon():
	queue_free()
