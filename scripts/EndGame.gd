extends CanvasLayer

@onready var collected_gold = $Control/PanelContainer/VBoxContainer/MarginContainer/RunGold
@onready var play_again = $Control/PanelContainer/VBoxContainer/PlayAgain
@onready var upgrades = $Control/PanelContainer/VBoxContainer/Upgrades
@onready var quit = $Control/PanelContainer/VBoxContainer/Quit
@onready var game = get_tree().get_root().get_node("Game")

func _ready():
	play_again.connect("pressed", Callable(self, "_on_PlayAgain_pressed"))
	upgrades.connect("pressed", Callable(self, "_on_Upgrades_pressed"))
	quit.connect("pressed", Callable(self, "_on_Quit_pressed"))
	self.hide()

func show_endgame_menu():
	self.show()
	get_tree().paused = true

func _on_PlayAgain_pressed():
	get_tree().paused = false  # Ensure the game is unpaused before changing scenes	
	perm_upgrades.save_game()
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_Upgrades_pressed():
	get_tree().paused = false  # Ensure the game is unpaused before changing scenes
	perm_upgrades.save_game()
	get_tree().change_scene_to_file("res://scenes/Upgrades.tscn")

func _on_Quit_pressed():
	get_tree().paused = false  # Ensure the game is unpaused before changing scenes
	perm_upgrades.save_game()
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")
