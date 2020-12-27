extends HBoxContainer

onready var close_btn = $CloseButton
onready var path_line_edit = $HSplitContainer/VBoxContainer/PathLineEdit
onready var name_line_edit = $HSplitContainer/VBoxContainer/NameLineEdit
onready var notes_text_edit = $HSplitContainer/NotesTextEdit


func _ready() -> void:
	pass

func get_path_input() -> String:
	return path_line_edit.get_text()

func get_name_input() -> String:
	return name_line_edit.get_text()

func get_notes_input() -> String:
	return notes_text_edit.get_text()

func get_path_node() -> Node:
	return path_line_edit

func get_name_node() -> Node:
	return name_line_edit

func get_notes_node() -> Node:
	return notes_text_edit

func set_path_input(path: String) -> void:
	path_line_edit.set_text(path)

func set_name_input(title: String) -> void:
	name_line_edit.set_text(title)

func set_notes_input(notes: String) -> void:
	notes_text_edit.set_text(notes)

func set_disabled(val: bool) -> void:
	get_path_node().set_editable(not val)
	get_name_node().set_editable(not val)
	get_notes_node().set_readonly(val)
	close_btn.set_disabled(val)
