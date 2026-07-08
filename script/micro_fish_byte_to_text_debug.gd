class_name MicroFishByteToTextDebug
extends Node

signal on_debug_last_byte_packed(data: String)

@export var data_to_debug: PackedByteArray = PackedByteArray()
@export var data_to_debug_as_string: String = ""


func push_byte_packed_to_debug(data: PackedByteArray):
	data_to_debug = data
	var string_representation = ""
	for byte in data:
		string_representation += str(byte) + " "
	data_to_debug_as_string = string_representation.strip_edges()
	on_debug_last_byte_packed.emit(data_to_debug_as_string)


func push_byte_array_to_debug(data: Array[bool]):
	var debug_text = ""

	for bit in data:
		debug_text += str(bit) + " "
	data_to_debug_as_string = debug_text.strip_edges()
	on_debug_last_byte_packed.emit(data_to_debug_as_string)
