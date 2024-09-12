extends Control

var resolutions = [
	Vector2i(1440, 900),  # WXGA+
	Vector2i(1600, 900),  # HD+
	Vector2i(1680, 1050), # WSXGA+
	Vector2i(1920, 1080), # Full HD
	Vector2i(1920, 1200), # WUXGA
	Vector2i(2048, 1152), # QWXGA
	Vector2i(2560, 1440), # QHD
]
var screen_modes = ["Fullscreen", "Windowed"]

@onready var return_button = $PanelContainer/MarginContainer2/ReturnButton
@onready var resolution_option = $PanelContainer/VBoxContainer/HBoxContainer3/ResolutionOption
@onready var master_volume_slider = $PanelContainer/VBoxContainer/HBoxContainer/VolumeSlider
@onready var weapons_volume_slider = $PanelContainer/VBoxContainer/HBoxContainer4/VolumeSlider
@onready var music_volume_slider = $PanelContainer/VBoxContainer/HBoxContainer5/VolumeSlider
@onready var screen_mode_option = $PanelContainer/VBoxContainer/HBoxContainer2/ModeOption
@onready var apply_button = $PanelContainer/VBoxContainer/MarginContainer/ApplyButton

# Define a signal to notify the parent when returning
signal return_to_parent

func _ready():
	return_button.connect("pressed", Callable(self, "_on_ReturnButton_pressed"))
	apply_button.connect("pressed", Callable(self, "_on_ApplyButton_pressed"))
	screen_mode_option.connect("item_selected", Callable(self, "_on_ScreenModeOption_selected"))
	
	# Populate resolution options
	for res in resolutions:
		resolution_option.add_item(str(res.x) + " x " + str(res.y))
	
	# Populate screen mode options
	for mode in screen_modes:
		screen_mode_option.add_item(mode)
	
	# Load saved settings and set the UI to reflect current settings
	_load_settings()

	# Connect the resolution options index change to updating the state
	resolution_option.connect("item_selected", Callable(self, "_on_ResolutionOption_selected"))
	
	# Ensure the settings panel continues to process even when the game is paused
	self.process_mode = Node.PROCESS_MODE_ALWAYS

func _load_settings():
	# Load the settings from the saved game data
	var current_resolution = DisplayServer.window_get_size()
	var current_mode = DisplayServer.window_get_mode()
	
	# Find the index of the current resolution
	var resolution_index = resolutions.find(current_resolution)
	if resolution_index != -1:
		resolution_option.select(resolution_index)
	else:
		print("Current resolution not in predefined list.")
		resolution_option.select(perm_upgrades.resolution_index)

	# Set the current screen mode
	match current_mode:
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			screen_mode_option.select(0)  # Fullscreen
		DisplayServer.WINDOW_MODE_WINDOWED:
			screen_mode_option.select(1)  # Windowed
		_:
			screen_mode_option.select(perm_upgrades.screen_mode_index)
			print("Unknown screen mode.")
	
	# Load volume from saved data
	master_volume_slider.value = perm_upgrades.volume
	weapons_volume_slider.value = perm_upgrades.weapons_volume
	music_volume_slider.value = perm_upgrades.music_volume


func _on_ApplyButton_pressed():
	# Save the selected settings
	perm_upgrades.resolution_index = resolution_option.get_selected_id()
	perm_upgrades.volume = master_volume_slider.value
	perm_upgrades.weapons_volume = weapons_volume_slider.value
	perm_upgrades.music_volume = music_volume_slider.value
	perm_upgrades.screen_mode_index = screen_mode_option.get_selected_id()
	perm_upgrades.save_game()

	# Apply
	_apply_resolution()
	_apply_volume()
	_apply_screen_mode()

func _apply_resolution():
	var selected_index = resolution_option.get_selected_id()
	var selected_resolution = resolutions[selected_index]
	print("Applying resolution: ", selected_resolution)
	DisplayServer.window_set_size(selected_resolution)

func _apply_volume():
	var master_volume_value = master_volume_slider.value
	var db_value = lerp(-80.0, 20.0, master_volume_value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db_value)

	var weapons_volume_value = weapons_volume_slider.value
	var weapons_db_value = lerp(-40.0, 30.0, weapons_volume_value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("WeaponsBus"), weapons_db_value)
	
	var music_volume_value = music_volume_slider.value
	var music_db_value = lerp(-60.0, 20.0, music_volume_value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("MusicBus"), music_db_value)
	
	
func _apply_screen_mode():
	var selected_index = screen_mode_option.get_selected_id()
	print("Applying screen mode: ", screen_modes[selected_index])
	match selected_index:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_ReturnButton_pressed():
	# Emit a signal to notify the parent scene to handle the return action
	emit_signal("return_to_parent")
