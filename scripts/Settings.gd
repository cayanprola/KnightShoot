extends Control

@onready var return_button = $ReturnButton

# Declare variables for storing resolutions and screen modes
var resolutions = [
	Vector2i(1440, 900),  # WXGA+
	Vector2i(1600, 900),  # HD+
	Vector2i(1680, 1050), # WSXGA+
	Vector2i(1920, 1080), # Full HD
	Vector2i(1920, 1200), # WUXGA
	Vector2i(2048, 1152), # QWXGA
	Vector2i(2560, 1440), # QHD
	Vector2i(2560, 1600), # WQXGA
	Vector2i(3200, 1800), # QHD+
	Vector2i(3440, 1440), # UWQHD (Ultra-Wide)
	Vector2i(3840, 2160), # 4K UHD
]
var screen_modes = ["Fullscreen", "Windowed"]

# Reference to UI elements
@onready var resolution_option = $PanelContainer/VBoxContainer/HBoxContainer3/ResolutionOption
@onready var volume_slider = $PanelContainer/VBoxContainer/HBoxContainer/VolumeSlider
@onready var screen_mode_option = $PanelContainer/VBoxContainer/HBoxContainer2/ModeOption
@onready var apply_button = $PanelContainer/VBoxContainer/MarginContainer/ApplyButton

func _ready():
	return_button.connect("pressed", Callable(self, "_on_BackButton_pressed"))
	
	# Populate resolution options
	for res in resolutions:
		resolution_option.add_item(str(res.x) + " x " + str(res.y))

	# Populate screen mode options
	for mode in screen_modes:
		screen_mode_option.add_item(mode)
	
	# Connect signals
	apply_button.connect("pressed", Callable(self, "_on_ApplyButton_pressed"))
	screen_mode_option.connect("item_selected", Callable(self, "_on_ScreenModeOption_selected"))

	# Set initial values
	resolution_option.select(3) # default to 1920x1080
	volume_slider.value = 50 # default volume
	screen_mode_option.select(0) # default to Exclusive Fullscreen
	
	_update_resolution_option_state()  # Update the state based on the default screen mode

func _on_ApplyButton_pressed():
	_apply_resolution()
	_apply_volume()
	_apply_screen_mode()

func _apply_resolution():
	var selected_index = resolution_option.get_selected_id()
	var selected_resolution = resolutions[selected_index]
	print("Applying resolution: ", selected_resolution)
	DisplayServer.window_set_size(selected_resolution)

func _apply_volume():
	var volume_value = volume_slider.value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume_value / 100.0 * -80.0) # assuming a volume range from 0 to -80 dB

func _apply_screen_mode():
	var selected_index = screen_mode_option.get_selected_id()
	print("Applying screen mode: ", screen_modes[selected_index])
	match selected_index:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	_update_resolution_option_state()  # Update resolution option state after applying screen mode

func _update_resolution_option_state():
	# Disable resolution option if the screen mode is not Windowed
	var selected_index = screen_mode_option.get_selected_id()
	if selected_index == 1:  # Windowed mode
		resolution_option.disabled = false
	else:
		resolution_option.disabled = true

func _on_ScreenModeOption_selected(index):
	_update_resolution_option_state()  # Update resolution option state when screen mode changes

func _adjust_viewport_with_black_bars():
	var selected_index = resolution_option.get_selected_id()
	var selected_resolution = resolutions[selected_index]
	
	var display_size = DisplayServer.window_get_size() # Get the current display size
	
	var target_aspect_ratio = float(selected_resolution.x) / selected_resolution.y
	var display_aspect_ratio = float(display_size.x) / display_size.y
	
	if target_aspect_ratio > display_aspect_ratio:
		# Pillarbox: Black bars on the sides
		var new_width = display_size.x
		var new_height = int(new_width / target_aspect_ratio)
		var y_offset = (display_size.y - new_height) / 2
		DisplayServer.window_set_size(Vector2i(new_width, new_height))
		DisplayServer.window_set_position(Vector2i(0, y_offset))
	elif target_aspect_ratio < display_aspect_ratio:
		# Letterbox: Black bars on top and bottom
		var new_height = display_size.y
		var new_width = int(new_height * target_aspect_ratio)
		var x_offset = (display_size.x - new_width) / 2
		DisplayServer.window_set_size(Vector2i(new_width, new_height))
		DisplayServer.window_set_position(Vector2i(x_offset, 0))
	else:
		# No need for black bars, aspect ratio matches
		DisplayServer.window_set_size(selected_resolution)
		DisplayServer.window_set_position(Vector2i(0, 0))

func _on_BackButton_pressed():
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")
	perm_upgrades.save_game()
