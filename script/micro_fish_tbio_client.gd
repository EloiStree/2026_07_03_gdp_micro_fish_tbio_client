class_name MicroFishClientTBIO
extends Node

class FourMotorInputState:
	var left_motor_percent11: float = 0.0
	var right_motor_percent11: float = 0.0
	var back_motor_percent11: float = 0.0
	var front_motor_percent11: float = 0.0

signal on_push_text_to_server(text: String)
signal on_push_byte_to_server(bytes: PackedByteArray)

@export var last_received_text: String = ""
var last_received_byte: PackedByteArray = PackedByteArray()

@export var player_count: int = 0
@export var dimension: Vector3 = Vector3.ZERO
@export var game_time_in_seconds: float = 0.0
@export var score_left: int = 0
@export var score_right: int = 0
@export var ball_position: Vector3 = Vector3.ZERO
@export var ball_radius: float = 0.2


var player_position: Array[Vector3] = []
var player_rotation: Array[Quaternion] = []
var player_euler: Array[Vector3] = []
var player_claimed_integer: Array[int] = []
var player_public_key: Array[String] = []
var player_battery_level: Array[float] = []
var players_color: Array[Color] = []
var players_motors: Array[FourMotorInputState] = []

# Input state for this player
@export var player_index: int = 0
@export_range(-1.0, 1.0) var left_motor_percent: float = 0.0
@export_range(-1.0, 1.0) var right_motor_percent: float = 0.0
@export_range(-1.0, 1.0) var back_motor_percent: float = 0.0
@export_range(-1.0, 1.0) var front_motor_percent: float = 0.0

# Timer for pushing input
var _push_timer: float = 0.0

func _ready() -> void:
	_push_timer = 0.0

func _process(delta: float) -> void:
	_push_timer += delta
	if _push_timer >= 1.1:  # 1.0 + 0.1 seconds like original coroutine
		push_motor_state()
		_push_timer = 0.0


func received_from_server_text(text: String) -> void:
	print("R#" + text)
	last_received_text = text
	var lines: PackedStringArray = text.split("\n", false)
	
	for line in lines:
		if line.begins_with("PLAYER_COUNT:"):
			# PLAYER_COUNT: 13
			var parts: PackedStringArray = line.split(":")
			if parts.size() == 2:
				player_count = int(parts[1].strip_edges())
				_initialize_player_arrays()
				
		elif line.begins_with("DIMENSION:"):
			# DIMENSION:-2:-0.902:-1
			var parts: PackedStringArray = line.split(":")
			if parts.size() == 4:
				dimension = Vector3(
					float(parts[1]),
					float(parts[2]),
					float(parts[3])
				)
				
		elif line.begins_with("PLAYER_COLOR"):
			# PLAYER_COLOR: 8:25:193:221
			var parts: PackedStringArray = line.strip_edges().split(":")
			if parts.size() == 5:
				var player_idx: int = int(parts[1].strip_edges())
				var r: int = int(parts[2].strip_edges())
				var g: int = int(parts[3].strip_edges())
				var b: int = int(parts[4].strip_edges())
				if player_idx >= 0 and player_idx < player_count:
					players_color[player_idx] = Color8(r, g, b, 255)
					
		elif line.begins_with("PLAYER"):
			# PLAYER:0:123:publickey
			var parts: PackedStringArray = line.split(":")
			if parts.size() == 4:
				var player_idx: int = int(parts[1].strip_edges())
				var claimed_int: int = int(parts[2].strip_edges())
				var public_key: String = parts[3]
				if player_idx >= 0 and player_idx < player_count:
					player_claimed_integer[player_idx] = claimed_int
					player_public_key[player_idx] = public_key
					
		elif line.begins_with("BATTERY"):
			# BATTERY: 0:0.9022313
			var parts: PackedStringArray = line.split(":")
			if parts.size() == 3:
				var player_idx: int = int(parts[1].strip_edges())
				var battery_str: String = parts[2].replace(",", ".")
				var battery_level: float = float(battery_str.strip_edges())
				if player_idx >= 0 and player_idx < player_count:
					player_battery_level[player_idx] = battery_level
					
		elif line.begins_with("GAME_TIME_IN_SECONDS:"):
			# GAME_TIME_IN_SECONDS:1.037494
			var parts: PackedStringArray = line.split(":")
			if parts.size() == 2:
				game_time_in_seconds = float(parts[1])
				
		elif line.begins_with("SOCCER_SCORE:"):
			# SOCCER_SCORE:2:1
			var parts: PackedStringArray = line.split(":")
			if parts.size() == 3:
				score_left = int(parts[1])
				score_right = int(parts[2])
				
		elif line.begins_with("BALL_POSITION:"):
			# BALL_POSITION:-0.001:-0.902:-0.999
			var parts: PackedStringArray = line.split(":")
			if parts.size() == 4:
				ball_position = Vector3(
					float(parts[1]),
					float(parts[2]),
					float(parts[3])
				)
				
		elif line.begins_with("BALL_RADIUS:"):
			# BALL_RADIUS:0.2
			var parts: PackedStringArray = line.split(":")
			if parts.size() == 2:
				ball_radius = float(parts[1])


func received_from_server_byte(bytes: PackedByteArray) -> void:
	last_received_byte = bytes
	var byte_expected_for_player_position: int = player_count * 7 * 4
	
	# Position + Quaternion = 7 floats = 28 bytes per player
	if bytes.size() == byte_expected_for_player_position:
		var stream: StreamPeerBuffer = StreamPeerBuffer.new()
		stream.data_array = bytes
		
		for i in range(player_count):
			stream.seek(i * 7 * 4)
			var pos_x: float = stream.get_float()
			var pos_y: float = stream.get_float()
			var pos_z: float = stream.get_float()
			player_position[i] = Vector3(pos_x, pos_y, pos_z)
			
			var rot_x: float = stream.get_float()
			var rot_y: float = stream.get_float()
			var rot_z: float = stream.get_float()
			var rot_w: float = stream.get_float()
			var rotation: Quaternion = Quaternion(rot_x, rot_y, rot_z, rot_w)
			player_rotation[i] = rotation
			player_euler[i] = rotation.get_euler()
	
	# Motor input: 4 floats = 16 bytes per player
	var byte_expected_for_player_input: int = player_count * 4 * 4
	if bytes.size() == byte_expected_for_player_input:
		var stream: StreamPeerBuffer = StreamPeerBuffer.new()
		stream.data_array = bytes
		
		for i in range(player_count):
			if i < players_motors.size():
				stream.seek(i * 4 * 4)
				if players_motors[i] == null:
					players_motors[i] = FourMotorInputState.new()
				players_motors[i].left_motor_percent11 = stream.get_float()
				players_motors[i].right_motor_percent11 = stream.get_float()
				players_motors[i].back_motor_percent11 = stream.get_float()
				players_motors[i].front_motor_percent11 = stream.get_float()


func push_motor_state() -> void:
	var stream: StreamPeerBuffer = StreamPeerBuffer.new()
	stream.put_32(player_index)  # 4 bytes for int
	stream.put_float(left_motor_percent)
	stream.put_float(right_motor_percent)
	stream.put_float(back_motor_percent)
	stream.put_float(front_motor_percent)
	on_push_byte_to_server.emit(stream.data_array)


func _initialize_player_arrays() -> void:
	# Only reinitialize if size changed
	if player_position.size() != player_count:
		player_position.clear()
		player_rotation.clear()
		player_euler.clear()
		player_claimed_integer.clear()
		player_public_key.clear()
		player_battery_level.clear()
		players_color.clear()
		players_motors.clear()
		
		for i in range(player_count):
			player_position.append(Vector3.ZERO)
			player_rotation.append(Quaternion.IDENTITY)
			player_euler.append(Vector3.ZERO)
			player_claimed_integer.append(0)
			player_public_key.append("")
			player_battery_level.append(0.0)
			players_color.append(Color.WHITE)
			players_motors.append(FourMotorInputState.new())
