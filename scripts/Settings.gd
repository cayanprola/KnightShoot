extends Control

@onready var settings_panel = $SettingsPanel

func _ready():
	if $TextureRect:
		BackgroundManager.set_background($TextureRect)
	settings_panel.connect("return_to_parent", Callable(self, "_on_SettingsPanel_returned"))
	
	# Ensure the panel is visible
	settings_panel.show()
	

func _on_SettingsPanel_returned():
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")
	perm_upgrades.save_game()
