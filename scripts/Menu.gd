extends Control

func _ready():
	perm_upgrades.load_game()
	BackgroundManager.set_background($TextureRect)
	$StartButton.connect("pressed", Callable(self, "_on_Start_pressed"))
	$UpgradesButton.connect("pressed", Callable(self, "_on_Upgrades_pressed"))
	$OptionsButton.connect("pressed", Callable(self, "_on_Options_pressed"))
	$ExitButton.connect("pressed", Callable(self, "_on_Exit_pressed"))

func _on_Start_pressed():
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_Upgrades_pressed():
	get_tree().change_scene_to_file("res://scenes/Upgrades.tscn")

func _on_Options_pressed():
	get_tree().change_scene_to_file("res://scenes/Settings.tscn")

func _on_Exit_pressed():
	perm_upgrades.save_game()  # Save the game before exiting
	get_tree().quit()
