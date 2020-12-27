extends MarginContainer

signal export_set

onready var _close_button = (
	$CenterContainer/PanelContainer/VBoxContainer/HBoxContainer/CloseButton )
onready var _selected_groups = (
	$CenterContainer/PanelContainer/VBoxContainer/HBoxContainer/GroupMenuButton )
onready var _selected_values_parent = (
	$CenterContainer/PanelContainer/VBoxContainer/ValuesHBoxContainer )
onready var _destination_line_edit = (
	$CenterContainer/PanelContainer/VBoxContainer/PathHBoxContainer/DestinationLineEdit )
onready var _destination_button = (
	$CenterContainer/PanelContainer/VBoxContainer/PathHBoxContainer/DestinationButton )
onready var _export_button = $CenterContainer/PanelContainer/VBoxContainer/ExportButton


func _ready() -> void:
	_close_button.connect("pressed", self, "on_CloseButton_pressed")
	_export_button.connect("pressed", self, "on_ExportButton_pressed")
	_destination_button.connect(
		"pressed", self, "on_DestinationButton_pressed" )
	$DestinationFileDialog.connect(
		"file_selected", self, "on_DestinationFileDialogue_file_selected" )

func set_groups(groups: Array) -> void:
	_selected_groups.set_groups(groups)

func on_ExportButton_pressed() -> void:
	var path = _destination_line_edit.get_text()
	var value_types = _get_selected_values()
	var groups = _selected_groups.get_selected()
	emit_signal("export_set", path, groups, value_types)
	hide()

func on_DestinationButton_pressed() -> void:
	$DestinationFileDialog.show()

func on_DestinationFileDialogue_file_selected(path: String) -> void:
	_destination_line_edit.set_text(path)

func on_CloseButton_pressed() -> void:
	hide()

func _get_selected_values() -> Array:
	"""
	Returns an array of booleans indicating which values are selected to be 
	exported. Array order of the values in the array is consistent with the 
	order the values are stored in the JSON file
	"""
	var selected = []
	for child in _selected_values_parent.get_children():
		if child is CheckBox:
			selected.append(child.is_pressed())
	return selected
