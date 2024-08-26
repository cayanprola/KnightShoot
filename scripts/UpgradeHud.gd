extends Control

@onready var weapon_icons = [
	$VBoxContainer/HBoxContainer2/MarginContainer/Border/WeaponIcon1,
	$VBoxContainer/HBoxContainer2/MarginContainer3/Border/WeaponIcon2,
	$VBoxContainer/HBoxContainer2/MarginContainer4/Border/WeaponIcon3,
	$VBoxContainer/HBoxContainer2/MarginContainer5/Border/WeaponIcon4
]

@onready var stat_icons = [
	$VBoxContainer/HBoxContainer/MarginContainer2/Border/StatIcon1,
	$VBoxContainer/HBoxContainer/MarginContainer3/Border/StatIcon2,
	$VBoxContainer/HBoxContainer/MarginContainer4/Border/StatIcon3,
	$VBoxContainer/HBoxContainer/MarginContainer5/Border/StatIcon4
]


func update_hud(selected_weapons: Array, selected_stats: Array):
	# Clear all icons first
	for icon in weapon_icons:
		icon.texture = null
	for icon in stat_icons:
		icon.texture = null

	# Keep track of used slots
	var weapon_slot_index = 0
	var stat_slot_index = 0

	# Update weapon icons
	for weapon in selected_weapons:
		if weapon_slot_index < weapon_icons.size():
			if weapon_icons[weapon_slot_index].texture == null:
				weapon_icons[weapon_slot_index].texture = weapon["icon"]
				weapon_slot_index += 1

	# Update stat icons
	for stat in selected_stats:
		if stat_slot_index < stat_icons.size():
			if stat_icons[stat_slot_index].texture == null:
				stat_icons[stat_slot_index].texture = stat["icon"]
				stat_slot_index += 1

