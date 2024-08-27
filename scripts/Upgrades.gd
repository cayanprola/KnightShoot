extends Control

@onready var gold_label = $TopPanel/HBoxContainer/GoldLabel
@onready var return_button = $ReturnButton
@onready var refund_button = $RefundButton
@onready var coin_texture_rect = $TopPanel/HBoxContainer/TextureRect
@onready var description_panel = $VBoxContainer/HoverPanel/DescriptionPanel
@onready var upgrade_name_label = description_panel.get_node("Control/VBoxContainer/UpgradeName")
@onready var upgrade_description = description_panel.get_node("Control/UpgradeDescription")
@onready var upgrade_price = description_panel.get_node("Control/BuyButton/UpgradePrice")
@onready var buy_button = description_panel.get_node("Control/BuyButton")
@onready var upgrade_icon = description_panel.get_node("Control/VBoxContainer/Icon")
@onready var coin_text = description_panel.get_node("Control/BuyButton/CoinTexture")

var current_upgrade_name = ""

# Dictionary to hold the icons for each upgrade
var upgrade_icons = {
	"max_health": preload("res://assets/Icons/HealthBG.png"),
	"health_regen": preload("res://assets/Icons/HealthRegenBG.png"),
	"armor": preload("res://assets/Icons/ArmorBG.png"),
	"damage": preload("res://assets/Icons/DamageBG.png"),
	"attack_speed": preload("res://assets/Icons/AttackSpeedBG.png"),
	"attack_size": preload("res://assets/Icons/AttackSizeBG.png"),
	"move_speed": preload("res://assets/Icons/MoveSpeedBG.png"),
	"revive": preload("res://assets/Icons/ReviveBG.png"),
}

func _ready():
	BackgroundManager.set_background($TextureRect)
	
	# Initially hide the description panel
	description_panel.hide()

	# Load the game data (ensure this is done before updating the HUD)
	perm_upgrades.load_game()

	# Update the HUD to reflect the loaded data
	update_upgrade_display("max_health", perm_upgrades.max_health)
	update_upgrade_display("health_regen", perm_upgrades.health_regen)
	update_upgrade_display("armor", perm_upgrades.armor)
	update_upgrade_display("damage", perm_upgrades.damage)
	update_upgrade_display("attack_speed", perm_upgrades.attack_speed)
	update_upgrade_display("attack_size", perm_upgrades.attack_size)
	update_upgrade_display("move_speed", perm_upgrades.move_speed)
	update_upgrade_display("revive", perm_upgrades.revive)

	# Update initial gold display
	update_gold_display()

	# Connect click signals for each upgrade panel
	connect_upgrade_panel_signals()

	# Connect buttons
	refund_button.connect("pressed", Callable(self, "_on_refund_button_pressed"))
	return_button.connect("pressed", Callable(self, "_on_BackButton_pressed"))
	buy_button.connect("pressed", Callable(self, "_on_buy_button_pressed"))

func connect_upgrade_panel_signals():
	# Connect click signals for each upgrade panel
	connect_click_signals($VBoxContainer/FlowContainer/HealthPanel, "max_health")
	connect_click_signals($VBoxContainer/FlowContainer/HealthRegenPanel, "health_regen")
	connect_click_signals($VBoxContainer/FlowContainer/ArmorPanel, "armor")
	connect_click_signals($VBoxContainer/FlowContainer/DamagePanel, "damage")
	connect_click_signals($VBoxContainer/FlowContainer/AtkSpeedPanel, "attack_speed")
	connect_click_signals($VBoxContainer/FlowContainer/AttackSizePanel, "attack_size")
	connect_click_signals($VBoxContainer/FlowContainer/MoveSpeedPanel, "move_speed")
	connect_click_signals($VBoxContainer/FlowContainer/RevivePanel, "revive")

func connect_click_signals(panel: Control, upgrade_name: String):
	panel.get_node("Control").connect("gui_input", Callable(self, "_on_upgrade_panel_clicked").bind(upgrade_name))

func _on_upgrade_panel_clicked(event: InputEvent, upgrade_name: String):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Show the description panel and update the name, description, price, and icon
			current_upgrade_name = upgrade_name
			upgrade_name_label.text = get_upgrade_display_name(upgrade_name)
			upgrade_description.text = get_upgrade_description(upgrade_name)
			
			var price = get_upgrade_price(upgrade_name)
			if price == -1:
				upgrade_price.text = "Maxed"
				coin_text.hide()  # Hide the coin text if the upgrade is maxed out
			else:
				upgrade_price.text = str(price)
				coin_text.show()  # Show the coin text if the upgrade is not maxed out
			
			upgrade_icon.texture = upgrade_icons[upgrade_name]
			description_panel.show()

func _on_buy_button_pressed():
	if current_upgrade_name:
		var price = get_upgrade_price(current_upgrade_name)
		if price != -1:
			buy_upgrade(current_upgrade_name, price)
			# Update UI after purchase
			var new_price = get_upgrade_price(current_upgrade_name)
			if new_price == -1:
				upgrade_price.text = "Maxed"
				coin_text.hide()
			else:
				upgrade_price.text = str(new_price)
				coin_text.show()
		update_gold_display()

func get_upgrade_display_name(upgrade_name: String) -> String:
	# Return a more readable name for the upgrade
	match upgrade_name:
		"max_health":
			return "Max Health"
		"health_regen":
			return "Health Regen"
		"armor":
			return "Armor"
		"damage":
			return "Damage"
		"attack_speed":
			return "Attack Speed"
		"attack_size":
			return "Attack Size"
		"move_speed":
			return "Move Speed"
		"revive":
			return "Revive"
		_:
			return "Unknown Upgrade"

func get_upgrade_description(upgrade_name: String) -> String:
	# Return the description based on the upgrade name
	match upgrade_name:
		"max_health":
			return "Increase maximum health."
		"health_regen":
			return "Increase health regeneration rate."
		"armor":
			return "Reduces damage taken."
		"damage":
			return "Increase damage on enemies."
		"attack_speed":
			return "Increases rate of attacks."
		"attack_size":
			return "Increases the size of attacks."
		"move_speed":
			return "Increases movement speed."
		"revive":
			return "Adds one revive."
		_:
			return "Unknown upgrade."

func get_upgrade_price(upgrade_name: String) -> int:
	# Get the current level of the upgrade
	var current_level = perm_upgrades.get(upgrade_name)
	var max_level = perm_upgrades.get(upgrade_name + "_max")
	
	# If the current level is already maxed out, return -1
	if current_level >= max_level:
		return -1
	
	# Define base prices and scaling factors
	var base_prices = {
		"max_health": 100,
		"health_regen": 100,
		"armor": 150,
		"damage": 120,
		"attack_speed": 130,
		"attack_size": 140,
		"move_speed": 110,
		"revive": 500
	}
	
	var scaling_factors = {
		"max_health": 1.2,
		"health_regen": 1.5,
		"armor": 1.2,
		"damage": 1.3,
		"attack_speed": 1.2,
		"attack_size": 1.3,
		"move_speed": 1.3,
	}
	
	# Calculate price based on level
	var base_price = base_prices.get(upgrade_name, 100)  # Default to 100 if not found
	var scaling_factor = scaling_factors.get(upgrade_name, 1.2)  # Default to 1.2 if not found
	var price = int(base_price * pow(scaling_factor, current_level))
	
	return price

func buy_upgrade(upgrade_type: String, cost: int):
	var current_level = perm_upgrades.get(upgrade_type)
	var max_level = perm_upgrades.get(upgrade_type + "_max")
	
	if current_level < max_level and perm_upgrades.gold >= cost:
		perm_upgrades.gold -= cost
		perm_upgrades.set(upgrade_type, current_level + 1)
		update_gold_display()
		update_upgrade_display(upgrade_type, current_level + 1)
		apply_upgrades_to_player()
	else:
		print("Cannot upgrade: Either max level reached or insufficient gold.")

func update_upgrade_display(upgrade_type: String, level: int):
	var label = null
	match upgrade_type:
		"max_health":
			label = $VBoxContainer/FlowContainer/HealthPanel/Control/QuantityLabel
		"health_regen":
			label = $VBoxContainer/FlowContainer/HealthRegenPanel/Control/QuantityLabel
		"armor":
			label = $VBoxContainer/FlowContainer/ArmorPanel/Control/QuantityLabel
		"damage":
			label = $VBoxContainer/FlowContainer/DamagePanel/Control/QuantityLabel
		"attack_speed":
			label = $VBoxContainer/FlowContainer/AtkSpeedPanel/Control/QuantityLabel
		"attack_size":
			label = $VBoxContainer/FlowContainer/AttackSizePanel/Control/QuantityLabel
		"move_speed":
			label = $VBoxContainer/FlowContainer/MoveSpeedPanel/Control/QuantityLabel
		"revive":
			label = $VBoxContainer/FlowContainer/RevivePanel/Control/QuantityLabel
	
	if label:
		label.text = str(level) + "/" + str(perm_upgrades.get(upgrade_type + "_max"))

func apply_upgrades_to_player():
	var player = get_tree().get_root().get_node("Menu/Game/Player")
	if player:
		player.apply_permanent_upgrades()
	# Else the print statement is suppressed to prevent console clutter

func _on_BackButton_pressed():
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")
	perm_upgrades.save_game()

func update_gold_display():
	gold_label.text = str(perm_upgrades.gold)

func _on_refund_button_pressed():
	var refund_amount = perm_upgrades.refund_upgrades()
	print("Refunded: ", refund_amount, " gold.")
	update_gold_display()
	reset_upgrade_display()
	apply_upgrades_to_player()

func reset_upgrade_display():
	var upgrade_names = ["max_health", "health_regen", "armor", "damage", "attack_speed", "attack_size", "move_speed", "revive"]
	
	for upgrade_name in upgrade_names:
		update_upgrade_display(upgrade_name, 0)

	# Update the description panel if it's visible
	if description_panel.visible:
		if current_upgrade_name != "":
			# Get the price of the currently selected upgrade
			var price = get_upgrade_price(current_upgrade_name)
			if price == -1:
				upgrade_price.text = "Maxed"
				coin_text.hide()
			else:
				upgrade_price.text = str(price)
				coin_text.show()
