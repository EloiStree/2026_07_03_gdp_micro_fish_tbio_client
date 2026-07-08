
class_name MicroFishInputFieldSavedAtChange
extends Node


signal on_input_field_text_changed(new_text: String)
signal on_input_field_text_reloaded(new_text: String)

@export var input_field:LineEdit
@export var save_unique_id: String = "IPV4"

func _enter_tree() -> void:
	# Connect the text_changed signal to a function that saves the text
	input_field.text_changed.connect(_text_changed)
	# Load the saved text when the node enters the tree
	reload_input_field_text_from_saved_file()

func _exit_tree() -> void:
	input_field.text_changed.disconnect(_text_changed)


func get_save_path() -> String:
	return "user://file_save_" + save_unique_id + ".txt"


func _text_changed(new_text: String) -> void:
	# Save the text to a file whenever it changes
	save_current_input_field_text()

func save_current_input_field_text():
	## As file in user://
	var file_path = get_save_path()
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(input_field.text)
		on_input_field_text_changed.emit(input_field.text)


func reload_input_field_text_from_saved_file():
	## As file in user://
	var file_path = get_save_path()
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var saved_text = file.get_as_text()
		input_field.text = saved_text
		on_input_field_text_reloaded.emit(saved_text)
