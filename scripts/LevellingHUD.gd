extends CanvasLayer

signal option_selected(option: Dictionary)
signal skip_selected()

@export var max_skips = 3
@onready var options_container = $Control/PanelContainer/VBoxContainer/OptionsContainer
@onready var skip_button = $Control/PanelContainer/Control/MarginContainer/VBoxContainer/Skip
@onready var level_up_label = $Control/PanelContainer/VBoxContainer/MarginContainer/LevelUpLabel
@onready var skips_remaining_label = $Control/PanelContainer/Control/MarginContainer/VBoxContainer/RemainingLabel
@onready var game = get_tree().get_root().get_node("Game")
var skips_remaining = max_skips
var available_options = []

func _ready():
	hide()
	skip_button.connect("pressed", Callable(self, "_on_skip_button_pressed"))
	update_skip_label()

func show_hud(options: Array):
	available_options = options
	
	if game.player.all_upgrades_maxed_out():
		hide()
	else:
		populate_options()
		_pause_game_manually()
		show()

# Populate options with the description and the options
func populate_options():
	for child in options_container.get_children():
		child.queue_free()

	for option_data in available_options:
		if option_data.level < upgrade_manager.get_max_level(option_data.name):
			var option_item_scene = preload("res://scenes/OptionItem.tscn").instantiate() as Control
			option_item_scene.set_option_data(option_data)
			if not option_item_scene.is_connected("option_selected", Callable(self, "_on_option_selected")):
				option_item_scene.connect("option_selected", Callable(self, "_on_option_selected"))
			options_container.add_child(option_item_scene)

func _on_option_selected(option_data):
	emit_signal("option_selected", option_data)
	
	hide()
	_resume_game_manually()

func _on_skip_button_pressed():
	skips_remaining -= 1
	update_skip_label()

	if skips_remaining <= 0:
		skip_button.hide()
		skips_remaining_label.hide()

	emit_signal("skip_selected")
	
	hide()
	_resume_game_manually()

# New methods to pause/resume the game without triggering pause menu HUD
func _pause_game_manually():
	get_tree().paused = true
	GlobalTimer.pause_game_timer()
	GlobalTimer.pause_spawn()
	GlobalTimer.stop_fireball_timer()
	GlobalTimer.stop_shuriken_timer()

func _resume_game_manually():
	get_tree().paused = false
	GlobalTimer.resume_game_timer()
	GlobalTimer.resume_spawn()
	GlobalTimer.start_fireball_timer()
	GlobalTimer.start_shuriken_timer()

func update_skip_label():
	skips_remaining_label.text = "Skips remaining: %d" % skips_remaining
