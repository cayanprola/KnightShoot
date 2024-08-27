extends Node2D

@onready var player = $Player
@onready var player_camera: Camera2D = $Player/Camera2D
var player_dead = false

@onready var timer_label: Label = $GameUI/Control/TimerLabel
@onready var gold_icon: TextureRect = $GameUI/Control/Control/MarginContainer/HBoxContainer/GoldCoin
@onready var gold_label = $GameUI/Control/Control/MarginContainer/HBoxContainer/CurrentGoldRun
var current_run_gold = 0
var time_left = 600

@onready var levelling_hud = $LevellingHUD
@onready var pause_menu_scene = preload("res://scenes/PauseMenu.tscn")
@onready var revive_hud_scene = preload("res://scenes/ReviveHUD.tscn")
@onready var endgame_hud_scene = preload("res://scenes/EndGame.tscn")
var pause_menu_instance: CanvasLayer = null
var revive_hud_instance: CanvasLayer = null
var endgame_hud_instance: CanvasLayer = null

@export var inactivity_time = 5.0
var inactivity_timer: Timer
var cursor_hidden = false

func _ready():
	GlobalTimer.start_game_timer(time_left)
	_setup_revive_hud()
	_setup_pause_menu()
	player.connect("level_up", Callable(self, "_on_player_level_up"))
	player.connect("gold_collected", Callable(self, "_on_gold_collected"))
	levelling_hud.connect("skip_selected", Callable(self, "_on_skip_selected"))
	levelling_hud.connect("option_selected", Callable(self, "_on_option_selected"))
	update_gold_display()
	
	inactivity_timer = Timer.new()
	inactivity_timer.wait_time = inactivity_time
	inactivity_timer.one_shot = true
	inactivity_timer.connect("timeout", Callable(self, "_on_inactivity_timeout"))
	add_child(inactivity_timer)

	# Start tracking mouse movement
	set_process_input(true)


func _process(delta):
	if get_tree().paused:
		_show_cursor()
		return
	update_viewport_for_weapons()
	_update_timer_label()

func update_viewport_for_weapons():
	if player_camera:
		var camera_global_position = player_camera.global_position
		for weapon in get_tree().get_nodes_in_group("weapons"):
			weapon.update_viewport(camera_global_position)
	else:
		print("Camera2D node not found!")

func _on_game_timer_timeout():
	time_left -= 1
	if time_left <= 0:
		_end_game()

func _update_timer_label():
	time_left = GlobalTimer.get_time_left()
	var minutes = int(time_left / 60)
	var seconds = int(time_left) % 60
	var seconds_str = str(seconds)
	timer_label.text = str(minutes) + ":" + seconds_str

func get_time_left() -> int:
	return time_left

func _end_game():
	_show_cursor()
	update_gold_display()
	print("Game Over")
	_add_run_gold_to_permanent()
	perm_upgrades.save_game()

	# Stop all game processes
	GlobalTimer.pause_game_timer()
	GlobalTimer.stop_shuriken_timer()
	GlobalTimer.stop_fireball_timer()
	GlobalTimer.pause_spawn()

	get_tree().paused = true

	# Instantiate and show the endgame HUD
	if endgame_hud_instance == null:
		print("Instantiating EndGame HUD")
		endgame_hud_instance = endgame_hud_scene.instantiate() as CanvasLayer
		add_child(endgame_hud_instance)

	endgame_hud_instance.show_endgame_menu()

func _input(event):
	if event.is_action_pressed("menu-back"):
		if get_tree().paused:
			if pause_menu_instance and pause_menu_instance.is_visible():
				_resume_game()
		else:
			_pause_game()
	if event is InputEventMouseMotion:
		_reset_inactivity_timer()

		if cursor_hidden:
			_show_cursor()
	#if event.is_action_pressed("toggle_speed"):
		#if Engine.time_scale == 1.0:
			#Engine.time_scale = 10.0  # Speed up the game by 5x for faster testing
			#print("Game speed increased to 5x")
		#else:
			#Engine.time_scale = 1.0  # Reset to normal speed
			#print("Game speed reset to normal")

func _pause_game():
	_show_cursor()
	if pause_menu_instance == null:
		pause_menu_instance = pause_menu_scene.instantiate() as CanvasLayer
		add_child(pause_menu_instance)
	pause_menu_instance.show()
	get_tree().paused = true
	GlobalTimer.pause_game_timer()
	GlobalTimer.pause_spawn()
	GlobalTimer.stop_fireball_timer()
	GlobalTimer.stop_shuriken_timer()

func _resume_game():
	_show_cursor()
	if pause_menu_instance != null:
		pause_menu_instance.hide()
	get_tree().paused = false
	GlobalTimer.resume_game_timer()
	GlobalTimer.resume_spawn()
	GlobalTimer.start_fireball_timer()
	GlobalTimer.start_shuriken_timer()

func _setup_pause_menu():
	if pause_menu_instance == null:
		pause_menu_instance = pause_menu_scene.instantiate() as CanvasLayer
		add_child(pause_menu_instance)
		pause_menu_instance.hide()

func _setup_revive_hud():
	if revive_hud_instance == null:
		revive_hud_instance = revive_hud_scene.instantiate() as CanvasLayer
		add_child(revive_hud_instance)
		revive_hud_instance.connect("revive_selected", Callable(self, "_on_revive_selected"))

func show_revive_hud():
	_show_cursor()
	get_tree().paused = true  # Pause the game
	GlobalTimer.pause_game_timer()
	GlobalTimer.pause_spawn()
	revive_hud_instance.show_hud()

func _on_revive_selected(revived: bool):
	if revived:
		print("Reviving player")
		player.handle_revive()
		revive_hud_instance.hide_hud()
		_resume_game()  # Resume the game after reviving
	else:
		print("Player chose not to revive")
		revive_hud_instance.hide_hud()
		_end_game()

func _on_player_level_up(options: Array):
	_show_cursor()
	levelling_hud.show_hud(options)

func _on_option_selected(option: Dictionary):
	player.upgrade_stat(option["name"])
	levelling_hud.hide()

func _on_skip_selected():
	print("Player skipped the level-up")

func _on_gold_collected(amount: int):
	current_run_gold += amount
	update_gold_display()
	print("Current Run Gold: ", current_run_gold)

func _add_run_gold_to_permanent():
	perm_upgrades.gold += current_run_gold
	perm_upgrades.save_game()
	print("Added Run Gold to Permanent Gold. Total Permanent Gold: ", perm_upgrades.gold)

func update_gold_display():
	if gold_label:
		print(gold_label)
		gold_label.text = str(current_run_gold)

func _reset_inactivity_timer():
	inactivity_timer.start()

func _on_inactivity_timeout():
	_hide_cursor()

func _hide_cursor():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	cursor_hidden = true

func _show_cursor():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	cursor_hidden = false
