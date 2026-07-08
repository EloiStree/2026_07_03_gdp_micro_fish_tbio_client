class_name MicroFishPushUdpOutToTargets 
extends Node

@export var list_targets_ipv4: Array[String] = [
	"192.168.137.1",
	"192.168.1.1"
	]
@export var port_for_text: int = 3614
@export var port_for_bytes: int = 3615
	

var udp_socket := PacketPeerUDP.new()
func push_text_to_targets(text_to_send_utf8: String):
	var bytes_to_send = text_to_send_utf8.to_utf8_buffer()
	push_bytes_to_targets(bytes_to_send, true)

func push_bytes_to_targets(bytes_to_send: PackedByteArray, bool_is_text: bool = false):
	for target in list_targets_ipv4:
		udp_socket.connect_to_host(target, port_for_text if bool_is_text else port_for_bytes)
		udp_socket.put_packet(bytes_to_send)
		udp_socket.close()


func push_random_character():
	var random_char = char(randi() % 256)
	var bytes_to_send = PackedByteArray()
	bytes_to_send.append(random_char)
	push_bytes_to_targets(bytes_to_send, true)
	
	
func push_random_integer():
	var bytes_to_send = integer_to_int32_bytes(randi())
	push_bytes_to_targets(bytes_to_send, false)

func integer_to_int32_bytes(value_int32: int) -> PackedByteArray:
	var byte_array = PackedByteArray()
	byte_array.resize(4)
	byte_array[0] = value_int32 & 0xFF
	byte_array[1] = (value_int32 >> 8) & 0xFF
	byte_array[2] = (value_int32 >> 16) & 0xFF
	byte_array[3] = (value_int32 >> 24) & 0xFF
	return byte_array

func integer_to_ulong64bytes(value_ulong64: int) -> PackedByteArray:
	var byte_array = PackedByteArray()
	byte_array.resize(8)
	byte_array[0] = value_ulong64 & 0xFF
	byte_array[1] = (value_ulong64 >> 8) & 0xFF
	byte_array[2] = (value_ulong64 >> 16) & 0xFF
	byte_array[3] = (value_ulong64 >> 24) & 0xFF
	byte_array[4] = (value_ulong64 >> 32) & 0xFF
	byte_array[5] = (value_ulong64 >> 40) & 0xFF
	byte_array[6] = (value_ulong64 >> 48) & 0xFF
	byte_array[7] = (value_ulong64 >> 56) & 0xFF
	return byte_array


func push_index_integer_to_targets(index_int32: int, value_int32: int):
	var byte_as_int_index = integer_to_int32_bytes(index_int32)
	var byte_as_int_value = integer_to_int32_bytes(value_int32)

	var bytes_as_indexed_integer = PackedByteArray()
	bytes_as_indexed_integer.append_array(byte_as_int_index)
	bytes_as_indexed_integer.append_array(byte_as_int_value)
	push_bytes_to_targets(bytes_as_indexed_integer,false)


func push_integer_to_targets(value_int32: int):
	var byte_as_int_value = integer_to_int32_bytes(value_int32)
	push_bytes_to_targets(byte_as_int_value,false)


func push_iid_to_targets(index_int32: int, value_int32: int, date_ulong64: int):

	var byte_as_int_index = integer_to_int32_bytes(index_int32)
	var byte_as_int_value = integer_to_int32_bytes(value_int32)
	var byte_as_ulong_date = integer_to_ulong64bytes(date_ulong64)

	var bytes_as_iid = PackedByteArray()
	bytes_as_iid.append_array(byte_as_int_index)
	bytes_as_iid.append_array(byte_as_int_value)
	bytes_as_iid.append_array(byte_as_ulong_date)
	push_bytes_to_targets(bytes_as_iid,false)
