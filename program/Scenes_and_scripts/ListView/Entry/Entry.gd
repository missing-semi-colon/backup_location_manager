extends HBoxContainer

onready var close_btn = $CloseButton
onready var path_line_edit = $HSplitContainer/VBoxContainer/PathLineEdit
onready var name_line_edit = $HSplitContainer/VBoxContainer/NameLineEdit
onready var notes_text_edit = $HSplitContainer/NotesTextEdit


func _ready() -> void:
	$HSplitContainer/VBoxContainer/PathLineEdit.connect(
		"gui_input", self, "on_PathLineEdit_gui_input" )
	$HSplitContainer/VBoxContainer/NameLineEdit.connect(
		"gui_input", self, "on_NameLineEdit_gui_input" )
	$HSplitContainer/NotesTextEdit.connect(
		"gui_input", self, "on_NotesTextEdit_gui_input" )

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

func on_PathLineEdit_gui_input(event) -> void:
	"""
	Copy PathLineEdit content to clipboard if it is pressed and in read only 
	mode.
	"""
	if event is InputEventMouseButton and event.is_pressed():
		if not get_path_node().is_editable():
			OS.set_clipboard(get_path_input())

func on_NameLineEdit_gui_input(event) -> void:
	"""
	Copy NameLineEdit content to clipboard if it is pressed and in read only 
	mode.
	"""
	if event is InputEventMouseButton and event.is_pressed():
		if not get_name_node().is_editable():
			OS.set_clipboard(get_name_input())

func on_NotesTextEdit_gui_input(event) -> void:
	"""
	Copy NotesTextEdit content to clipboard if it is pressed and in read only 
	mode.
	"""
	if event is InputEventMouseButton and event.is_pressed():
		if get_notes_node().is_readonly():
			OS.set_clipboard(get_notes_input())
