
extends Control

@onready var settings_panel = $SettingsPanel  # Adjust the path if necessary

func _ready():
	if $TextureRect:
		BackgroundManager.set_background($TextureRect)
	# Connect to the SettingsPanel's return signal
	settings_panel.connect("return_to_parent", Callable(self, "_on_SettingsPanel_returned"))
	
	# Initially, ensure the SettingsPanel is visible (since we're in the Settings menu)
	settings_panel.show()
	
	# If there are other UI elements in the Settings menu, handle their visibility as needed

func _on_SettingsPanel_returned():
	# Handle the return action from the SettingsPanel
	# For the main Settings menu, this could mean closing the Settings menu or performing another action
	# For simplicity, let's assume we just want to close the Settings menu and return to the main menu
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")
	perm_upgrades.save_game()
