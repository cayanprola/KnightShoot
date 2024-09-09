extends Control

signal option_selected(option_data)
var option_data

func _ready():
	connect("gui_input", Callable(self, "_on_gui_input"))

func _on_gui_input(event):
	if option_data.level >= upgrade_manager.get_max_level(option_data.name):
		return  # Do not allow selection if the upgrade is maxed out
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("option_selected", option_data)

# Set values for each levelling option
func set_option_data(data):
	option_data = data
	$TextureRect/HBoxContainer/VBoxContainer/MarginContainer2/VBoxContainer/Name.text = data.name
	$TextureRect/HBoxContainer/MarginContainer/TextureRect/Icon.texture = data.icon
	$TextureRect/HBoxContainer/VBoxContainer/MarginContainer2/VBoxContainer/CurrentLevel.text = "Level " + str(data.level + 1)
	$TextureRect/HBoxContainer/VBoxContainer/MarginContainer/Description.text = upgrade_manager.get_description(data.name, data.level)
