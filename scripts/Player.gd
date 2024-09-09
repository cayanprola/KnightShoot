extends CharacterBody2D

@export var shuriken_scene: PackedScene
@export var purple_laser_scene: PackedScene
@export var fireball_scene: PackedScene
@export var knife_scene: PackedScene
@export var invincibility_time = 0.5
@export var max_health = 100
@export var health = max_health
@export var health_regen = 0.0
@export var armor = 0.0
@export var player_dmg = 0
@export var atk_speed = 1
@export var atk_size = 1
@export var move_speed = 255
@export var revive = 0

@export var experience = 0
@export var player_lvl = 1
@export var experience_next_lvl = 100

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var character_body: CharacterBody2D = self
@onready var area_2d: Area2D = $Area2D
@onready var health_bar: Node = $HealthBar

@onready var xp_bar = get_tree().get_root().get_node("Game/GameUI/Control/XPBarContainer/XPBar")
@onready var game = get_tree().get_root().get_node("Game")
@onready var upgrades_hud = get_tree().get_root().get_node("Game/GameUI/Control/UpgradesHud")

var shoot_timer = 0.0
var knife_timer = 0.0
var is_dead = false
var is_hit = false
var invincible = false

var purple_laser_level = 0
var shuriken_level = 0
var fireball_level = 0
var knife_level = 0
var health_level = 0
var health_regen_level = 0
var attack_speed_level = 0
var damage_level = 0
var move_speed_level = 0

var shurikens = []
var shuriken_angles = []
var shuriken_timer = 0.0
var shuriken_active = false
var shuriken_rotation_speed = PI
var shuriken_orbit_radius = 90
var fireball_timer = 0.0
var fireball_damage = 0
var fireball_speed = 0
var fireball_active = false
var fireball = []
var knife_speed = 0
var knife_damage = 0

@export var max_weapons = 4
@export var max_stats = 4
var selected_weapons = []
var selected_stats = []

var purple_laser_selected = false

signal level_up(options: Array)
signal gold_collected(amount: int)

func _ready():
	add_to_group("player")
	print(upgrades_hud)
	apply_permanent_upgrades()  # Apply permanent upgrades first
	health_bar.set_max_health(max_health)
	health = max_health
	health_bar.set_health(health)  # Set initial health in health bar
	xp_bar = get_tree().get_root().get_node("Game/GameUI/Control/XPBarContainer/XPBar")
	xp_bar.max_value = experience_next_lvl  # Set XP bar max value
	area_2d.connect("body_entered", Callable(self, "_on_Area2D_body_entered"))
	GlobalTimer.connect("shuriken_timeout", Callable(self, "_toggle_shuriken"))
	GlobalTimer.start_shuriken_timer()
	GlobalTimer.connect("fireball_timeout", Callable(self, "_toggle_fireball"))
	GlobalTimer.start_fireball_timer()

func _physics_process(delta):
	if is_dead:
		return
	
	_regenerate_health(delta)
	
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	character_body.velocity = direction * move_speed
	character_body.move_and_slide()

	_update_state()
	_handle_shooting(delta)
	_handle_shurikens(delta)

# Update state to handle animations
func _update_state():
	if is_hit:
		animated_sprite.play("Hit")
	else:
		if character_body.velocity.length() > 0.0:
			animated_sprite.play("Walk")
		else:
			animated_sprite.play("Idle")

# Apply permanent upgrades if the player has any
func apply_permanent_upgrades():
	max_health = 100 + perm_upgrades.max_health * 20
	health_regen += perm_upgrades.health_regen * 0.2
	armor += perm_upgrades.armor * 2
	player_dmg += perm_upgrades.damage * 5
	atk_speed += perm_upgrades.attack_speed * 0.05
	atk_size = 1 + perm_upgrades.attack_size * 0.08
	move_speed += perm_upgrades.move_speed * 25
	revive += perm_upgrades.revive * 1
	health_bar.set_max_health(max_health)
	health = min(health, max_health)

#Handle shooting of weapon except shuriken because it spawns, reduces the time using atk speed value
func _handle_shooting(delta):
	shoot_timer -= delta
	fireball_timer -= delta
	knife_timer -= delta

	if shoot_timer <= 0:
		shoot_timer = max(0.7, 1.5 / (0.5 + atk_speed ))  # Reduce time between shots with higher attack speed
		_shoot_laser()
		print("Atk speed laser timer ", atk_speed, " laser timer ", shoot_timer) 

	if fireball_active and fireball_level > 0 and fireball_timer <= 0:
		fireball_timer = max(0.9, 3.5 / (0.5 + atk_speed))
		_shoot_fireball()
		print("Atk speed fireball timer ", atk_speed, " fireball timer ", fireball_timer) 

	if knife_level > 0 and knife_timer <= 0:
		knife_timer = max(0.8, 4 / (0.5 + atk_speed))
		_shoot_knives()
		print("Atk speed knife timer ", atk_speed, " knife timer ", knife_timer) 
		
#Used to spawn shuriken
func _handle_shurikens(delta):
	if shuriken_active and shuriken_level > 0:
		_rotate_shurikens(delta)
	else:
		_deactivate_shurikens()

func _shoot_laser():
	var directions = [Vector2(1, 0)]
	
	# Add additional directions based on the purple laser level
	if purple_laser_level >= 1:
		directions.append(Vector2(-1, 0))  # Left
	if purple_laser_level >= 3:
		directions.append(Vector2(0, -1))  # Up
	if purple_laser_level >= 5:
		directions.append(Vector2(0, 1))  # Down

	# Instantiate and set up lasers for each direction
	for direction in directions:
		var laser_instance = purple_laser_scene.instantiate()
		var offset = Vector2(45, 0)
		
		if direction == Vector2(1, 0):  # Right
			laser_instance.rotation_degrees = 0
		elif direction == Vector2(-1, 0):  # Left
			laser_instance.rotation_degrees = 180
			offset = Vector2(-45, 0)
		elif direction == Vector2(0, -1):  # Up
			laser_instance.rotation_degrees = -90
			offset = Vector2(0, -45)
		elif direction == Vector2(0, 1):  # Down
			laser_instance.rotation_degrees = 90
			offset = Vector2(0, 45)
		
		# Apply specific level-based attributes
		if purple_laser_level >= 2:
			laser_instance.laser_damage += 10
			laser_instance.laser_speed += 10
			print("Level 2+ damage and speed applied.")
			
		if purple_laser_level >= 3:
			laser_instance.laser_damage += 10
			laser_instance.laser_speed += 20
			print("Level 3+ damage and speed applied.")

		if purple_laser_level >= 4:
			laser_instance.laser_damage += 10
			laser_instance.laser_speed += 20
			print("Level 4+ damage and speed applied.")
		
		laser_instance.global_position = global_position + offset
		laser_instance.laser_damage += player_dmg
		laser_instance.scale = Vector2(atk_size, atk_size)
		print("Laser damage after player damage added: ", laser_instance.laser_damage)
		print("Laser speed after all upgrades: ", laser_instance.laser_speed)
		laser_instance.laser_direction = direction  # Set the direction based on the level
		get_parent().add_child(laser_instance)

#Get enemy for fireball
func _get_random_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() > 0:
		return enemies[randi() % enemies.size()]
	return null

func _take_damage(amount):
	if is_dead or invincible:
		return

	var damage_taken = max(0, amount - armor)

	health -= damage_taken
	health_bar.set_health(health)
	print("Player health: ", health, " Damage taken: ", damage_taken)  # Debug print for health and damage

	# Play hit animation and set hit state
	if not is_hit:
		is_hit = true
		invincible = true
		_hit_effect()

	if health <= 0:
		_on_death()

func _hit_effect() -> void:
	await get_tree().create_timer(invincibility_time).timeout  # Wait for invincibility time
	invincible = false
	is_hit = false

func kill_player():
	_on_death()

func _on_death():
	if is_dead:
		return

	is_dead = true
	animated_sprite.play("Death")
	set_process(false)
	print("Game Over")
	
	if revive > 0:
		game.show_revive_hud()
	else:
		get_tree().paused = true
		game._end_game()

func _on_animation_finished():
	if animated_sprite.animation == "Death":
		animated_sprite.stop()

func resurrect():
	is_dead = false
	health = max_health  # Reset health
	health_bar.set_health(health)
	animated_sprite.play("Idle")
	set_process(true)

#Handle colisions
func _on_Area2D_body_entered(body):
	if body.is_in_group("enemies"):
		_take_damage(20)
	elif body.is_in_group("collectibles"):
		if body.has_signal("gold_collected"):
			body.connect("gold_collected", Callable(self, "collect_gold"))
		body.queue_free()

func add_experience(xp_amount):
	experience += xp_amount
	xp_bar.value = experience  # Update XP bar value
	if experience >= experience_next_lvl:
		level_up_player()

func _regenerate_health(delta):
	if health < max_health:
		health += health_regen * delta
		health = min(health, max_health)  # Ensure health doesn't exceed max_health
		health_bar.set_health(health)  # Update the health bar

func level_up_player():
	player_lvl += 1
	experience -= experience_next_lvl
	experience_next_lvl += 70

	# Update the XP bar to reflect the new levels requirement
	xp_bar.max_value = experience_next_lvl
	xp_bar.value = experience  # Ensure the XP bar reflects the remaining XP after leveling up

	health = min(max_health, health + 20)
	health_bar.set_health(health)

#Gives gold if max level
	print("Checking if all upgrades are maxed out...")
	if all_upgrades_maxed_out():
		print("All upgrades are maxed out. Adding gold...")
		collect_gold(25)
		
	else:
		print("Not all upgrades are maxed out. Showing level-up options...")
		# Emit the level-up signal with available options
		print("Emitting level_up signal")
		emit_signal("level_up", get_available_options())

func all_upgrades_maxed_out() -> bool:
	print("Checking if all upgrades are maxed out...")

	# If no upgrades have been selected at all, return false
	if selected_weapons.size() == 0 and selected_stats.size() == 0:
		print("No upgrades selected. Returning false.")
		return false

	# Check if all selected weapons have reached their max level
	if selected_weapons.size() > 0:
		for weapon in selected_weapons:
			var weapon_level = get_upgrade_level(weapon["name"])
			var max_level = upgrade_manager.get_max_level(weapon["name"])
			print("Weapon:", weapon["name"], "Level:", weapon_level, "Max Level:", max_level)
			if weapon_level < max_level:
				print("Returning false: Weapon not maxed out.")
				return false
	else:
		print("No weapons selected.")

	# Check if all selected stats have reached their max level
	if selected_stats.size() > 0:
		for stat in selected_stats:
			var stat_level = get_upgrade_level(stat["name"])
			var max_level = upgrade_manager.get_max_level(stat["name"])
			print("Stat:", stat["name"], "Level:", stat_level, "Max Level:", max_level)
			if stat_level < max_level:
				print("Returning false: Stat not maxed out.")
				return false
	else:
		print("No stats selected.")

	print("All upgrades are maxed out. Returning true.")
	return true


func handle_revive():
	if revive > 0:
		revive -= 1
		resurrect()

func get_upgrade_level(upgrade_name: String) -> int:
	match upgrade_name:
		"Purple Laser":
			return purple_laser_level
		"Fireball":
			return fireball_level
		"Shuriken":
			return shuriken_level
		"Knife":
			return knife_level
		"Health":
			return health_level
		"Health Regen":
			return health_regen_level
		"Damage":
			return damage_level
		"Move Speed":
			return move_speed_level
		"Attack Speed":
			return attack_speed_level
		_:
			return 0

func get_available_options() -> Array:
	var options = []
	var weapon_options = {
		"Purple Laser": preload("res://assets/Icons/PurpleLaser.png"),
		"Shuriken": preload("res://assets/Icons/shuriken.png"),
		"Fireball": preload("res://assets/Icons/Fireball.png"),
		"Knife": preload("res://assets/Icons/Knife.png")
	}
	
	var stat_options = {
		"Health": preload("res://assets/Icons/Health.png"),
		"Health Regen": preload("res://assets/Icons/HealthRegen.png"),
		"Damage": preload("res://assets/Icons/Damage.png"),
		"Move Speed": preload("res://assets/Icons/MoveSpeed.png"),
		"Attack Speed": preload("res://assets/Icons/AttackSpeed.png"),
	}

	var potential_upgrades = []

	# Allow leveling up for already selected weapons
	for selected_weapon in selected_weapons:
		var level = get_upgrade_level(selected_weapon["name"])
		if level < upgrade_manager.get_max_level(selected_weapon["name"]):
			potential_upgrades.append({
				"name": selected_weapon["name"],
				"icon": selected_weapon["icon"],
				"level": level,
				"description": upgrade_manager.get_description(selected_weapon["name"], level)
			})

	# Allow leveling up for already selected stats
	for selected_stat in selected_stats:
		var level = get_upgrade_level(selected_stat["name"])
		if level < upgrade_manager.get_max_level(selected_stat["name"]):
			potential_upgrades.append({
				"name": selected_stat["name"],
				"icon": selected_stat["icon"],
				"level": level,
				"description": upgrade_manager.get_description(selected_stat["name"], level)
			})

	# If there are available slots, add new upgrade options for weapon and stats
	if selected_weapons.size() < max_weapons:
		for weapon in weapon_options.keys():
			if not selected_weapons.has({"name": weapon, "icon": weapon_options[weapon]}):
				var level = get_upgrade_level(weapon)
				if level < upgrade_manager.get_max_level(weapon):
					potential_upgrades.append({
						"name": weapon,
						"icon": weapon_options[weapon],
						"level": level,
						"description": upgrade_manager.get_description(weapon, level)
					})

	if selected_stats.size() < max_stats:
		for stat in stat_options.keys():
			if not selected_stats.has({"name": stat, "icon": stat_options[stat]}):
				var level = get_upgrade_level(stat)
				if level < upgrade_manager.get_max_level(stat):
					potential_upgrades.append({
						"name": stat,
						"icon": stat_options[stat],
						"level": level,
						"description": upgrade_manager.get_description(stat, level)
					})

	# Shuffle the potential upgrades to ensure randomness
	potential_upgrades.shuffle()

	# Limit the number of options to 3, and ensure no duplicates
	var selected_names = []
	for upgrade in potential_upgrades:
		if selected_names.has(upgrade["name"]):
			continue
		options.append(upgrade)
		selected_names.append(upgrade["name"])
		if options.size() == 3:
			break

	return options

#Utilized to apply the correct upgrades
func upgrade_stat(upgrade_name: String):
	print("Upgrading:", upgrade_name)
	
	var max_level = upgrade_manager.get_max_level(upgrade_name)
	var level = get_upgrade_level(upgrade_name)
	
	if level >= max_level:
		print(upgrade_name + " is already at max level.")
		return

	var icon = null

	# Store the corresponding icon with the upgrade
	match upgrade_name:
		"Purple Laser":
			icon = preload("res://assets/Icons/PurpleLaser.png")
		"Shuriken":
			icon = preload("res://assets/Icons/shuriken.png")
		"Fireball":
			icon = preload("res://assets/Icons/Fireball.png")
		"Knife":
			icon = preload("res://assets/Icons/Knife.png")
		"Health":
			icon = preload("res://assets/Icons/Health.png")
		"Health Regen":
			icon = preload("res://assets/Icons/HealthRegen.png")
		"Damage":
			icon = preload("res://assets/Icons/Damage.png")
		"Move Speed":
			icon = preload("res://assets/Icons/MoveSpeed.png")
		"Attack Speed":
			icon = preload("res://assets/Icons/AttackSpeed.png")

	# Check if the weapon or stat is already selected before adding
	var is_new_selection = false

	if upgrade_name in ["Purple Laser", "Shuriken", "Fireball", "Knife"]:  # Weapon upgrades
		if not selected_weapons.has({"name": upgrade_name, "icon": icon}):
			if selected_weapons.size() < max_weapons:
				selected_weapons.append({"name": upgrade_name, "icon": icon})
				is_new_selection = true
				print("Added weapon:", upgrade_name)
	else:  # Stat upgrades
		if not selected_stats.has({"name": upgrade_name, "icon": icon}):
			if selected_stats.size() < max_stats:
				selected_stats.append({"name": upgrade_name, "icon": icon})
				is_new_selection = true
				print("Added stat:", upgrade_name)

	# Print current state after selection
	print("Selected Weapons After Upgrade: ", selected_weapons)
	print("Selected Stats After Upgrade: ", selected_stats)

	# Only update the HUD if this is a new selection
	if is_new_selection:
		upgrades_hud.update_hud(selected_weapons, selected_stats)

	# Increase the level and apply upgrades
	match upgrade_name:
		"Purple Laser":
			purple_laser_level += 1
			print("Purple Laser level:", purple_laser_level)
		"Shuriken":
			shuriken_level += 1
			apply_shuriken_upgrades()
			print("Shuriken level:", shuriken_level)
		"Fireball":
			fireball_level += 1
			apply_fireball_upgrades()
			print("Fireball level:", fireball_level)
		"Knife":
			knife_level += 1
			apply_knife_upgrades()
			print("Knife level:", knife_level)
		"Health":
			health_level += 1
			max_health += 10
			health = min(health, max_health)
			health_bar.set_max_health(max_health)
			health_bar.set_health(health)
			print("Health level:", health_level, "Max health:", max_health)
		"Health Regen":
			health_regen_level += 1
			health_regen += 0.08
			print("Health Regen level:", health_regen_level, "Health regen:", health_regen)
		"Damage":
			damage_level += 1
			player_dmg += 10
			print("Damage level:", damage_level, "Player damage:", player_dmg)
		"Move Speed":
			move_speed_level += 1
			move_speed += 20
			print("Move Speed level:", move_speed_level, "Move speed:", move_speed)
		"Attack Speed":
			attack_speed_level += 1
			atk_speed += 0.1
			print("Attack Speed level:", attack_speed_level, "Attack speed:", atk_speed)

	# Check if maxed out
	if get_upgrade_level(upgrade_name) >= max_level:
		print(upgrade_name + " is now maxed out.")

# Control activation of fireball and shuriken and checking to clear them
func _toggle_fireball(active: bool):
	fireball_active = active
	if not active:
		for fb in fireball:
			if fb and is_instance_valid(fb):
				fb.queue_free()
		fireball.clear()

func _toggle_shuriken(active: bool):
	shuriken_active = active
	if shuriken_active:
		_spawn_shurikens()
	else:
		_deactivate_shurikens()

func _deactivate_shurikens():
	for shuriken in shurikens:
		if shuriken and is_instance_valid(shuriken):
			shuriken.queue_free()
	shurikens.clear()
	shuriken_angles.clear()

# Apply the shuriken upgrades based on its level
func apply_shuriken_upgrades():
	_deactivate_shurikens()  # Clear all existing shurikens before applying new settings
	
	match shuriken_level:
		1:
			shuriken_rotation_speed = PI
			_spawn_single_shuriken(0)
		2:
			shuriken_rotation_speed = PI
			_spawn_single_shuriken(0)
		3:
			shuriken_rotation_speed = PI
			_spawn_single_shuriken(0)
		4:
			shuriken_rotation_speed = PI * 1.5
			_spawn_single_shuriken(0)
		5:
			shuriken_rotation_speed = PI * 2.2
			_spawn_single_shuriken(0)
			_spawn_single_shuriken(PI * 2 / 3)  # Second shuriken, 120 degrees apart
			_spawn_single_shuriken(4 * PI / 3)  # Third shuriken, 240 degrees apart

#Used to spawn the shurikens
func _spawn_shurikens():
	_deactivate_shurikens()  # Remove any existing shurikens
	var shuriken_count = shuriken_level  # Increase count based on level

	for i in range(shuriken_count):
		var angle_offset = i * (PI * 2 / shuriken_count)
		_spawn_single_shuriken(angle_offset)

func _spawn_single_shuriken(angle_offset: float):
	var shuriken = shuriken_scene.instantiate()
	
	# Set initial position relative to the player
	var orbit_position = Vector2(shuriken_orbit_radius, 0).rotated(angle_offset)
	shuriken.position = orbit_position
	
	# Set additional properties
	shuriken.shuriken_damage += player_dmg
	shuriken.shuriken_angle = angle_offset
	shuriken.scale = Vector2(atk_size, atk_size)
	
	shuriken.shuriken_rotation_speed = shuriken_rotation_speed
	
	add_child(shuriken)
	print("Shuriken damage: ", shuriken.shuriken_damage)
	
	# Store references
	shurikens.append(shuriken)
	shuriken_angles.append(angle_offset)

func _rotate_shurikens(delta):
	var i = 0
	while i < shurikens.size():
		if is_instance_valid(shurikens[i]):  # Ensure the shuriken is valid
			shuriken_angles[i] += shuriken_rotation_speed * delta
			var orbit_position = Vector2(shuriken_orbit_radius, 0).rotated(shuriken_angles[i])
			shurikens[i].global_position = global_position + orbit_position
			i += 1  # Only increment i if no element is removed
		else:
			# If the shuriken is not valid, remove it from the list
			shurikens.remove_at(i)
			shuriken_angles.remove_at(i)

func _shoot_knives():
	var knife_count = knife_level  # Increase count based on level
	var base_angle = randf() * PI * 2  # Start at a random angle

	for i in range(knife_count):
		var angle_offset = i * (PI * 2 / knife_count) + base_angle
		var direction = Vector2(cos(angle_offset), sin(angle_offset))
		var knife_instance = knife_scene.instantiate()
		knife_instance.global_position = global_position
		knife_instance.knife_direction = direction
		knife_instance.scale = Vector2(atk_size, atk_size)
		knife_instance.knife_speed += knife_speed
		knife_instance.knife_damage += knife_damage + player_dmg
		print("Knife damage: ", knife_instance.knife_damage)
		print("Knife speed: ", knife_instance.knife_speed)
		print("Knife level: ", knife_level)
		get_parent().add_child(knife_instance)

func _shoot_fireball():
	var fireball_count = min(3, (fireball_level + 1) / 2)  # Determine number of fireballs
	fireball.clear()
	
	for i in range(fireball_count):
		var target = _get_random_enemy()
		if target:
			var direction = (target.global_position - global_position).normalized()
			var fireball_instance = fireball_scene.instantiate()
			fireball_instance.global_position = global_position
			fireball_instance.fireball_damage += fireball_damage + player_dmg  # Set the damage from the upgraded values
			fireball_instance.fireball_speed += fireball_speed    # Set the speed from the upgraded values
			fireball_instance.scale = Vector2(atk_size, atk_size)
			fireball_instance.rotation = direction.angle()
			fireball_instance.fireball_direction = direction  # Set the direction based on the target
			print("Fireball damage:", fireball_instance.fireball_damage, " Fireball speed:", fireball_instance.fireball_speed)
			get_parent().add_child(fireball_instance)
			fireball.append(fireball_instance)

func apply_fireball_upgrades():
	match fireball_level:
		2:
			fireball_damage += 10
			fireball_speed += 30
		3:
			fireball_damage += 10
			fireball_speed += 50
		4:
			fireball_damage += 10
			fireball_speed += 50
		5:
			fireball_damage += 10
			fireball_speed += 50

func apply_knife_upgrades():
	match knife_level:
		2:
			knife_damage += 5
			knife_speed += 50
		3:
			knife_damage += 10
			knife_speed += 50
		4:
			knife_damage += 5
			knife_speed += 50
		5:
			knife_damage += 10
			knife_speed += 50

func _on_LevelUpButton_pressed():
	add_experience(experience_next_lvl)

func collect_gold(amount: int):
	emit_signal("gold_collected", amount)
