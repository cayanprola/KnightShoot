extends Node2D

@export var pattern_scene_path: String = "res://scenes/SmallGrassPattern.tscn"
@export var tile_size: Vector2 = Vector2(32, 32)
@export var chunk_size: Vector2 = Vector2(64, 64)
@export var unload_radius: int = 3  # How far away a chunk can be before it gets unloaded

var player_position_in_tiles: Vector2
var generated_chunks = {}

func _ready():
	player_position_in_tiles = Vector2.ZERO
	_update_map()

func _process(delta):
	var player = get_parent().get_node("Player")
	var player_global_position = player.global_position
	var new_player_position_in_tiles = Vector2(
		int(player_global_position.x / tile_size.x),
		int(player_global_position.y / tile_size.y)
	)
	
	if new_player_position_in_tiles != player_position_in_tiles:
		player_position_in_tiles = new_player_position_in_tiles
		_update_map()

# Update the map with the chunks
func _update_map():
	var current_chunk = _get_chunk_position(player_position_in_tiles)
	
	for x_offset in range(-1, 2):
		for y_offset in range(-1, 2):
			var chunk_pos = current_chunk + Vector2(x_offset, y_offset)
			if not generated_chunks.has(chunk_pos):
				_instance_pattern(chunk_pos)
	
	_unload_distant_chunks(current_chunk)

func _get_chunk_position(tile_position: Vector2) -> Vector2:
	return Vector2(
		int(tile_position.x / chunk_size.x),
		int(tile_position.y / chunk_size.y)
	)

# Instantiace the pattern scene
func _instance_pattern(chunk_pos: Vector2):
	var pattern_scene = load(pattern_scene_path)
	if not pattern_scene:
		print("Failed to load pattern scene at path: ", pattern_scene_path)
		return

	var pattern_instance = pattern_scene.instantiate()
	if not pattern_instance:
		print("Failed to instantiate pattern scene.")
		return

	# Calculate and set the world position for the chunk
	var world_position = chunk_pos * chunk_size * tile_size
	pattern_instance.position = world_position
	add_child(pattern_instance)
	generated_chunks[chunk_pos] = pattern_instance
	print("Pattern instanced at ", world_position)


func _unload_distant_chunks(current_chunk: Vector2):
	var chunks_to_unload = []
	
	# Iterate through all generated chunks
	for chunk_pos in generated_chunks.keys():
		# Calculate the distance from the current chunk
		var distance = current_chunk.distance_to(chunk_pos)
		if distance > unload_radius:
			chunks_to_unload.append(chunk_pos)
	
	# Unload the distant chunks
	for chunk_pos in chunks_to_unload:
		_unload_chunk(chunk_pos)

func _unload_chunk(chunk_pos: Vector2):
	if generated_chunks.has(chunk_pos):
		var chunk_instance = generated_chunks[chunk_pos]
		if chunk_instance != null:
			remove_child(chunk_instance)
			chunk_instance.queue_free()
		generated_chunks.erase(chunk_pos)
