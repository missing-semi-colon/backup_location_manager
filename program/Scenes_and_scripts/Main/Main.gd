extends MarginContainer

export (PackedScene) var ListView_pkscene

var save_location = "./paths.json"
onready var mod_group_cont = $VBoxContainer/ModGroupVBoxContainer


func _ready():
	$VBoxContainer/HBoxContainer/NewGroupButton \
		.connect("pressed", self, "on_NewGroupButton_pressed")
	$VBoxContainer/HBoxContainer/DeleteGroupButton \
		.connect("pressed", self, "on_DeleteGroupButton_pressed")
	mod_group_cont.get_node("HBoxContainer/GroupTitleButton") \
		.connect("pressed", self, "on_GroupTitleButton_pressed")
	$VBoxContainer/HBoxContainer/ExportButton \
		.connect("pressed", self, "on_ExportButton_pressed")
	$Export.connect("export_set", self, "on_Export_export_set")
	
	_create_tabs()

func on_NewGroupButton_pressed() -> void:
	var new_visibility = (
		$VBoxContainer/HBoxContainer/NewGroupButton.is_pressed() )
	mod_group_cont.set_visible(new_visibility)
	
	if new_visibility == true:
		mod_group_cont.get_node("HBoxContainer/GroupTitleButton").set_text("+")
		$VBoxContainer/HBoxContainer/DeleteGroupButton.set_pressed(false)

func on_DeleteGroupButton_pressed() -> void:
	var new_visibility = (
		$VBoxContainer/HBoxContainer/DeleteGroupButton.is_pressed() )
	mod_group_cont.set_visible(new_visibility)
	
	if new_visibility == true:
		mod_group_cont.get_node("HBoxContainer/GroupTitleButton").set_text("-")
		$VBoxContainer/HBoxContainer/NewGroupButton.set_pressed(false)

func on_GroupTitleButton_pressed() -> void:
	var line_edit = mod_group_cont.get_node(
		"HBoxContainer/GroupTitleLineEdit" )
	var text = line_edit.get_text().strip_edges()
	if $VBoxContainer/HBoxContainer/NewGroupButton.is_pressed():
		_add_group(text)
	elif $VBoxContainer/HBoxContainer/DeleteGroupButton.is_pressed():
		var msg = "Are you sure you want to delete group '" + text + "'?"
		$ConfirmationDialog.set_text(msg)
		$ConfirmationDialog.connect(
			"confirmed", self, "_delete_group", [text], CONNECT_ONESHOT )
		$ConfirmationDialog.get_cancel().connect(
			"pressed", self, "_cancel_deletion", [], CONNECT_ONESHOT )
		$ConfirmationDialog.show()

func on_ExportButton_pressed() -> void:
	var groups = IO.get_group_list(save_location)
	for group in groups:
		if not _get_list_view_node(group).is_data_saved():
			push_warning("Some data isn't saved")
			return
	$Export.set_groups(groups)
	$Export.show()

func on_Export_export_set(
	path: String, 
	groups: Array, 
	selected_values: Array) -> void:
	"""
	Exports the selected type of data (path, name, notes) from the groups to 
	the target location.
	"""
	IO.export_data(save_location, path, groups, selected_values)

func _create_tabs() -> void:
	var groups = IO.get_group_list(save_location)
	for group_title in groups:
		_create_tab(group_title)

func _create_tab(group_title: String) -> void:
	var tab_cont = $VBoxContainer/TabContainer
	var lv = ListView_pkscene.instance()
	lv.init(save_location, group_title)
	tab_cont.add_child(lv)
	tab_cont.set_tab_title(tab_cont.get_tab_count() - 1, group_title)

func _add_group(group_title: String) -> void:
	""" Validates the title of the new group then adds a tab for it """
	var err_msg = ""
	if group_title == "":
		err_msg = "Group name must not be empty"
	elif group_title in IO.get_group_list(save_location):
		err_msg = "Group with that name already exists"
	if err_msg != "":
		$AcceptDialog.set_text(err_msg)
		$AcceptDialog.popup_centered(Vector2(200, 100))
	else:
		_create_tab(group_title)
	$VBoxContainer/HBoxContainer/NewGroupButton.set_pressed(false)
	mod_group_cont.set_visible(false)

func _delete_group(group_title: String) -> void:
	""" Deletes the group with title `group_title` """
	var group_node = _get_list_view_node(group_title)
	if group_node:
		group_node.queue_free()
	IO.delete_group(save_location, group_title)
	$VBoxContainer/HBoxContainer/DeleteGroupButton.set_pressed(false)
	mod_group_cont.set_visible(false)
	
	if $ConfirmationDialog.get_cancel().is_connected(
			"pressed", self, "_cancel_deletion" ):
		$ConfirmationDialog.get_cancel().disconnect(
			"pressed", self, "_cancel_deletion")

func _cancel_deletion() -> void:
	mod_group_cont.get_node("HBoxContainer/GroupTitleLineEdit").clear()
	$VBoxContainer/HBoxContainer/DeleteGroupButton.set_pressed(false)
	mod_group_cont.set_visible(false)
	
	if $ConfirmationDialog.is_connected("confirmed", self, "_delete_group"):
		$ConfirmationDialog.disconnect("confirmed", self, "_delete_group")

func _get_list_view_node(group_title: String) -> ListView:
	for node in $VBoxContainer/TabContainer.get_children():
		if node is ListView:
			if node.group_title == group_title:
				return node
	return null
