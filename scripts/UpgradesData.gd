extends Node

# Player's permanent upgrades and their max levels
var max_health = 0
var max_health_max = 5

var health_regen = 0
var health_regen_max = 5

var armor = 0
var armor_max = 5

var damage = 0
var damage_max = 5

var attack_speed = 0
var attack_speed_max = 5

var attack_size = 0
var attack_size_max = 5

var move_speed = 0
var move_speed_max = 5

var revive = 0
var revive_max = 1

var gold = 0

# Settings variables
var resolution_index = 3  # Default to 1920x1080
var screen_mode_index = 0  # Default to Fullscreen
var volume = 50  # Default volume

# Path to save the file
var save_path = "user://save_game.json"

# Resolutions and screen modes for reference
var resolutions = [
	Vector2i(1440, 900),
	Vector2i(1600, 900),
	Vector2i(1680, 1050),
	Vector2i(1920, 1080),
	Vector2i(1920, 1200),
	Vector2i(2048, 1152),
	Vector2i(2560, 1440),
]
var screen_modes = ["Fullscreen", "Windowed"]

func _ready():
	load_game()  # Load the game when the script is ready
	apply_settings()  # Apply the loaded settings

func save_game():
	var save_data = {
		"max_health": max_health,
		"health_regen": health_regen,
		"armor": armor,
		"damage": damage,
		"attack_speed": attack_speed,
		"attack_size": attack_size,
		"move_speed": move_speed,
		"revive": revive,
		"gold": gold,
		"resolution_index": resolution_index,
		"screen_mode_index": screen_mode_index,
		"volume": volume,
	}
	
	var file = FileAccess.open(save_path, FileAccess.ModeFlags.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("Game saved!")
	else:
		print("Error saving game!")

func load_game():
	print("Attempting to load game...")  # Debug print to indicate the function is called
	var file = FileAccess.open(save_path, FileAccess.ModeFlags.READ)
	if file:
		print("File opened successfully.")  # Debug print to confirm file opening
		var file_content = file.get_as_text()
		print("File content: ", file_content)  # Print the raw file content to see what is in the file

		var save_data = JSON.parse_string(file_content)

		file.close()

		# Ensure that save_data is a dictionary
		if typeof(save_data) == TYPE_DICTIONARY:
			print("Save data parsed successfully.")  # Debug print to confirm JSON parsing
			max_health = save_data.get("max_health", 0)
			health_regen = save_data.get("health_regen", 0)
			armor = save_data.get("armor", 0)
			damage = save_data.get("damage", 0)
			attack_speed = save_data.get("attack_speed", 0)
			attack_size = save_data.get("attack_size", 0)
			move_speed = save_data.get("move_speed", 0)
			revive = save_data.get("revive", 0)
			gold = save_data.get("gold", 0)
			resolution_index = save_data.get("resolution_index", 3)
			screen_mode_index = save_data.get("screen_mode_index", 0)
			volume = save_data.get("volume", 50)
		else:
			print("Error: Save data is not a dictionary.")
	else:
		print("Error opening save file.")

func apply_settings():
	# Apply screen mode first
	match screen_mode_index:
		0:  # Fullscreen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			print("Set to Exclusive Fullscreen mode")
		1:  # Windowed
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			print("Set to Windowed mode")

	# Apply resolution after setting the screen mode
	var selected_resolution = resolutions[resolution_index]
	DisplayServer.window_set_size(selected_resolution)
	print("Resolution set to: ", selected_resolution)

	# Apply volume
	var db_value = lerp(-80.0, 0.0, volume / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db_value)

	# Print current window size and mode for debugging
	var current_size = DisplayServer.window_get_size()
	var current_mode = DisplayServer.window_get_mode()
	print("Current window size: ", current_size)
	print("Current window mode: ", current_mode)
