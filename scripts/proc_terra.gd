extends Node2D

@onready var tile_map = $TileMap
@onready var oceanic_layer = $TileMap/OceanicLayer
@onready var water_layer = $TileMap/WaterLayer
@onready var continental_layer = $TileMap/ContinentalLayer
@onready var volcanic_layer = $TileMap/VolcanicLayer

@export var noise_texture : NoiseTexture2D
@export var tectonic_noise_texture : NoiseTexture2D
@export var volcanic_noise_texture : NoiseTexture2D

var width : int = 500
var height : int = 500

var noise : Noise
var tectonic_noise : Noise
var volcanic_noise : Noise
var depth_map = {}

var oceanic_tile_coords = Vector2i(0, 0)
var water_tile_coords = Vector2i(1, 0)
var continental_tile_coords = Vector2i(2, 0)
var volcanic_tile_coords = Vector2i(3, 0)

# Define layer indices
const OCEANIC_LAYER_INDEX = 0
const WATER_LAYER_INDEX = 1
const CONTINENTAL_LAYER_INDEX = 2
const VOLCANIC_LAYER_INDEX = 3

func _ready():
	noise = noise_texture.noise
	tectonic_noise = tectonic_noise_texture.noise if tectonic_noise_texture else noise
	volcanic_noise = volcanic_noise_texture.noise if volcanic_noise_texture else noise

	initialize_depth_map()
	generate_visuals()
	apply_layer_colors()  # Apply colors to terrain layers


func initialize_depth_map():
	for x in range(-width/2, width/2):
		for y in range(-height/2, height/2):
			var noise_val = noise.get_noise_2d(x, y)
			var tectonic_val = tectonic_noise.get_noise_2d(x, y) if tectonic_noise else 0
			var volcanic_val = volcanic_noise.get_noise_2d(x, y) if volcanic_noise else 0
			var tile_layers = []

			# Base elevation
			var elevation = remap(noise_val, 0, 1, -20, 100)
			# Elevation and tectonic influence
			if tectonic_val > 0.7:
				elevation += randf() * (40 - 10) + 10 # Uplift effect

			# Determine terrain type
			if elevation > 30:
				tile_layers.append({"type": "continental", "elevation": elevation})
			elif elevation < 0:
				tile_layers.append({"type": "oceanic", "elevation": elevation})
			else:
				tile_layers.append({"type": "water", "elevation": elevation})

			# Add volcanoes only on land
			if volcanic_val > 0.6 and elevation > 0:
				tile_layers.append({"type": "volcanic", "elevation": elevation + randf() * 30 + 10})

			# Store data in depth map
			depth_map[Vector2i(x, y)] = tile_layers

func generate_visuals():
	print("Depth map size:", depth_map.size())
	
	for coord in depth_map.keys():
		var tile_data = depth_map[coord]
		var elevation = tile_data[-1]["elevation"]
		var is_volcanic = false
		
		for layer in tile_data:
			if layer["type"] == "volcanic":
				is_volcanic = true
				break

		if is_volcanic:
			volcanic_layer.set_cell(coord, 0, volcanic_tile_coords)
			#$TileMap.set_cell(0, coord, 0, volcanic_tile_coords)  # 0 is the layer index
		elif elevation > 30:
			continental_layer.set_cell(coord, 0, continental_tile_coords)
		elif elevation < 0:
			oceanic_layer.set_cell(coord, 0, oceanic_tile_coords)
		else:
			water_layer.set_cell(coord, 0, water_tile_coords)

func apply_layer_colors():
	oceanic_layer.set_modulate(Color(0.0, 0.0, 0.8))  # Deep blue
	water_layer.set_modulate(Color(0.2, 0.6, 1.0))   # Light blue
	continental_layer.set_modulate(Color(0.5, 0.4, 0.2))  # Brown
	volcanic_layer.set_modulate(Color(0.8, 0.2, 0.2))  # Red
