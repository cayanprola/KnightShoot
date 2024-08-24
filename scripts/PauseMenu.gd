extends CanvasLayer

func _ready():
	# Hide the pause menu initially
	self.hide()

func show_pause_menu():
	self.show()
	get_tree().paused = true

func hide_pause_menu():
	self.hide()
	get_tree().paused = false
	# Call the function to resume the game
	var game = get_tree().get_root().get_node("Game")
	if game:
		game._resume_game()

func _on_Continue_pressed():
	hide_pause_menu()

func _on_Quit_pressed():
	perm_upgrades.save_game()
	get_tree().paused = false  # Ensure the game is unpaused before changing scenes
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")  # Change to your main menu scene
