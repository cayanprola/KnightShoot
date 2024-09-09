extends CanvasLayer

@onready var settings_panel: Control = $SettingsPanel
@onready var pause_control = $PauseControl 

func _ready():
	self.hide()
	settings_panel.hide()
	
	# Connect to SettingsPanel return signal
	settings_panel.connect("return_to_parent", Callable(self, "_on_SettingsPanel_returned"))

func show_pause_menu():
	self.show()
	get_tree().paused = true

func hide_pause_menu():
	self.hide()
	get_tree().paused = false
	var game = get_tree().get_root().get_node("Game")
	if game:
		game._resume_game()

func _on_Continue_pressed():
	hide_pause_menu()

func _on_Settings_pressed():
	# Hide the pause menu control and show SettingsPanel
	pause_control.hide()
	settings_panel.show()
	settings_panel.set_focus_mode(Control.FOCUS_ALL)
	settings_panel.grab_focus()

func _on_Quit_pressed():
	perm_upgrades.save_game()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")

func _on_SettingsPanel_returned():
	# Handle the return action from SettingsPanel
	settings_panel.hide()
	pause_control.show()
