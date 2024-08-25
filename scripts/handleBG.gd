extends Node

var bg_image_1440x900 = load("res://assets/Bg/Space Background1440x900.png")
var bg_image_1920x1080 = load("res://assets/Bg/Space Background1920x1080.png")
var bg_image_2560x1440 = load("res://assets/Bg/Space Background2560x1440.png")

func set_background(texture_rect: TextureRect):
	var resolution = DisplayServer.window_get_size()
	print("Current Resolution: ", resolution)

	var chosen_texture: Texture

	if resolution.x <= 1440 and resolution.y <= 900:
		chosen_texture = bg_image_1440x900
		print("Setting background to 1440x900")
	elif resolution.x <= 1920 and resolution.y <= 1080:
		chosen_texture = bg_image_1920x1080
		print("Setting background to 1920x1080")
	elif resolution.x <= 2560 and resolution.y <= 1440:
		chosen_texture = bg_image_2560x1440
		print("Setting background to 2560x1440")
	else:
		chosen_texture = bg_image_2560x1440
		print("Setting background to 2560x1440 (default)")

	# Apply the chosen texture to the TextureRect
	if chosen_texture:
		texture_rect.texture = chosen_texture
		print("Texture applied successfully.")
	else:
		print("Failed to apply texture, chosen texture is null.")
