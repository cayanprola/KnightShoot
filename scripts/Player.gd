extends CharacterBody2D

@export var shuriken_scene: PackedScene
@export var purple_laser_scene: PackedScene
@export var fireball_scene: PackedScene
@export var knife_scene: PackedScene
@export var invincibility_time = 0.7
@export var max_health = 100
@export var health = max_health
@export var health_regen = 0.0
@export var armor = 0.0
@export var player_dmg = 10
@export var atk_speed = 1
@export var atk_size = 1
@export var move_speed = 250
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
var fireball_active = false
var fireball = []
var knife_speed = 400
var knife_damage = 10

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
	health_bar.set_max_health(max_health)  # Update the health bar with max health
	health = max_health  # Set health to max health initially
	health_bar.set_health(health)  # Set initial health in health bar
	xp_bar = get_tree().get_root().get_node("Game/GameUI/Control/XPBarContainer/XPBar")
	xp_bar.max_value = experience_next_lvl  # Set XP bar max value
	area_2d.connect("body_entered", Callable(self, "_on_Area2D_body_entered"))
	GlobalTimer.connect("shuriken_timeout", Callable(self, "_toggle_shuriken"))
	GlobalTimer.start_shuriken_timer()
	GlobalTimer.connect("fireball_timeout", Callable(self, "_toggle_fireball"))
	GlobalTimer.start_fireball_timer()

func apply_permanent_upgrades():
	max_health = 100 + perm_upgrades.max_health * 20
	health_regen += perm_upgrades.health_regen * 0.2
	armor += perm_upgrades.armor * 2
	player_dmg += perm_upgrades.damage * 7.5
	atk_speed = max(0.1, 1 - perm_upgrades.attack_speed * 0.05)
	atk_size = 1 + perm_upgrades.attack_size * 0.08
	move_speed += perm_upgrades.move_speed * 20
	revive += perm_upgrades.revive * 1
	health_bar.set_max_health(max_health)
	health = min(health, max_health)

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

func _update_state():
	if is_hit:
		animated_sprite.play("Hit")
	else:
		if character_body.velocity.length() > 0.0:
			animated_sprite.play("Walk")
		else:
			animated_sprite.play("Idle")

func _handle_shooting(delta):
	shoot_timer -= delta
	fireball_timer -= delta
	knife_timer -= delta

	if shoot_timer <= 0:
		shoot_timer = max(0.1, 1.0 / atk_speed)  # Reduce time between shots with higher attack speed
		_shoot()

	if fireball_active and fireball_level > 0 and fireball_timer <= 0:
		fireball_timer = max(1, 5.0 / (1.0 + atk_speed * fireball_level))  # Reduce time between fireballs with higher attack speed
		_shoot_fireball()

	# Continuous knife shooting
	if knife_level > 0 and knife_timer <= 0:
		knife_timer = max(1, 5.0 / (1.0 + atk_speed * knife_level))  # Adjust rate of fire with knife level
		_shoot_knives()

func _handle_shurikens(delta):
	if shuriken_active and shuriken_level > 0:
		_rotate_shurikens(delta)
	else:
		_deactivate_shurikens()

func _shoot():
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
		var weapon = purple_laser_scene.instantiate()
		var offset = Vector2(45, 0)
		
		if direction == Vector2(1, 0):  # Right
			weapon.rotation_degrees = 0
		elif direction == Vector2(-1, 0):  # Left
			weapon.rotation_degrees = 180
			offset = Vector2(-45, 0)
		elif direction == Vector2(0, -1):  # Up
			weapon.rotation_degrees = -90
			offset = Vector2(0, -45)
		elif direction == Vector2(0, 1):  # Down
			weapon.rotation_degrees = 90
			offset = Vector2(0, 45)
		
		weapon.global_position = global_position + offset
		weapon.laser_damage += player_dmg  # Set the weapon damage
		weapon.scale = Vector2(atk_size, atk_size)
		weapon.laser_direction = direction  # Set the direction based on the level
		get_parent().add_child(weapon)

func _shoot_fireball():
	var fireball_count = clamp((fireball_level - 1) / 2 + 1, 1, 3)  # Clamp the number of fireballs to a maximum of 3
	fireball.clear()
	
	for i in range(fireball_count):
		var target = _get_random_enemy()
		if target:
			var direction = (target.global_position - global_position).normalized()
			var weapon = fireball_scene.instantiate()
			weapon.global_position = global_position
			weapon.fireball_damage += player_dmg  # Set the damage based on level and player damage
			print("Fireball damage: ", weapon.fireball_damage)
			weapon.scale = Vector2(atk_size, atk_size)
			weapon.rotation = direction.angle()
			weapon.fireball_direction = direction  # Set the direction based on the target
			get_parent().add_child(weapon)
			fireball.append(weapon)

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
	health = max_health  # Reset health or any other relevant properties
	health_bar.set_health(health)
	animated_sprite.play("Idle")
	set_process(true)

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
	experience_next_lvl += 70  # Example increment, adjust as needed

	# Update the XP bar to reflect the new level's requirement
	xp_bar.max_value = experience_next_lvl
	xp_bar.value = experience  # Ensure the XP bar reflects the remaining XP after leveling up

	health = min(max_health, health + 20)
	health_bar.set_health(health)

	# Emit the level-up signal with available options
	emit_signal("level_up", get_available_options())

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

	# If there are available slots, add new upgrade options
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

func upgrade_stat(upgrade_name: String):
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
	else:  # Stat upgrades
		if not selected_stats.has({"name": upgrade_name, "icon": icon}):
			if selected_stats.size() < max_stats:
				selected_stats.append({"name": upgrade_name, "icon": icon})
				is_new_selection = true

	# Only update the HUD if this is a new selection
	if is_new_selection:
		upgrades_hud.update_hud(selected_weapons, selected_stats)

	# Increase the level
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
			health_regen += 0.1
			print("Health Regen level:", health_regen_level, "Health regen:", health_regen)
		"Damage":
			damage_level += 1
			player_dmg += 10
			print("Damage level:", damage_level, "Player damage:", player_dmg)
		"Move Speed":
			move_speed_level += 1
			move_speed += 10
			print("Move Speed level:", move_speed_level, "Move speed:", move_speed)
		"Attack Speed":
			attack_speed_level += 1
			atk_speed -= 0.05
			print("Attack Speed level:", attack_speed_level, "Attack speed:", atk_speed)

	# Check if maxed out
	if get_upgrade_level(upgrade_name) >= max_level:
		print(upgrade_name + " is now maxed out.")

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
			shuriken_rotation_speed = PI  # Default speed at level 1
			_spawn_single_shuriken(0)
		2:
			shuriken_rotation_speed = PI # Increase speed at level 2
			_spawn_single_shuriken(0)
		3:
			shuriken_rotation_speed = PI  # Keep the speed from level 2
			_spawn_single_shuriken(0)
		4:
			shuriken_rotation_speed = PI * 1.5  # Increase speed at level 4
			_spawn_single_shuriken(0)
		5:
			shuriken_rotation_speed = PI * 2.2  # Increase speed
			_spawn_single_shuriken(0)
			_spawn_single_shuriken(PI * 2 / 3)  # Second shuriken, 120 degrees apart
			_spawn_single_shuriken(4 * PI / 3)  # Third shuriken, 240 degrees apart

func _spawn_shurikens():
	_deactivate_shurikens()  # Remove any existing shurikens
	var shuriken_count = min(shuriken_level, 5)  # Maximum of 3 shurikens at level 5

	for i in range(shuriken_count):
		var angle_offset = i * (PI * 2 / shuriken_count)
		_spawn_single_shuriken(angle_offset)

func _spawn_single_shuriken(angle_offset: float):
	var shuriken = shuriken_scene.instantiate()
	
	# Set initial position relative to the player
	var orbit_position = Vector2(shuriken_orbit_radius, 0).rotated(angle_offset)
	shuriken.position = orbit_position
	
	# Set additional properties
	shuriken.shuriken_damage += player_dmg  # Set shuriken damage based on player damage
	shuriken.shuriken_angle = angle_offset
	shuriken.scale = Vector2(atk_size, atk_size)
	
	shuriken.shuriken_rotation_speed = shuriken_rotation_speed
	
	# Add shuriken as a child of the player
	add_child(shuriken)
	
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
			shuriken_angles.remove_at(i)  # Do not increment i here

func _shoot_knives():
	var knife_count = knife_level  # Number of knives is directly related to the knife level
	var base_angle = randf() * PI * 2  # Start at a random angle

	for i in range(knife_count):
		var angle_offset = i * (PI * 2 / knife_count) + base_angle
		var direction = Vector2(cos(angle_offset), sin(angle_offset))
		var knife = knife_scene.instantiate()
		knife.global_position = global_position
		knife.knife_direction = direction
		knife.scale = Vector2(atk_size, atk_size)
		
		knife.knife_speed = knife_speed  # Set speed based on level
		knife.knife_damage = knife_damage  # Set damage based on level
		get_parent().add_child(knife)

func apply_knife_upgrades():
	match knife_level:
		1:
			knife_speed = 400
		2:
			knife_damage += 5
			knife_speed = 450
		3:
			knife_speed = 500
			knife_damage += 5
		4:
			knife_speed = 550
			knife_damage += 5
		5:
			knife_speed = 600
			knife_damage += 5

func _on_LevelUpButton_pressed():
	add_experience(experience_next_lvl)

func collect_gold(amount: int):
	emit_signal("gold_collected", amount)
