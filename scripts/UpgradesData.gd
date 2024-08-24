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

# Path to save the file
var save_path = "user://save_game.json"

func _ready():
	load_game()  # Load the game when the script is ready

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

		var json = JSON.new()
		var save_data = json.parse_string(file_content)

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
		else:
			print("Error: Save data is not a dictionary.")
	else:
		print("Error opening save file.")
