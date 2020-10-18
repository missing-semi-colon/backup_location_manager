extends Control

export (PackedScene) var Entry

enum SortBy {
	None,
	Name, 
	Path
}

var save_location = "./paths.json"
var _can_edit = false
var _old_data = []    # Stores the Entry data from the last save
var _entry_nodes = []    # Stores the Entry nodes in the order they were added
onready var _scroll_container = $VBoxContainer/ScrollContainer
onready var _entry_parent_node = $VBoxContainer/ScrollContainer/VBoxContainer/Entries
onready var _sort_by_button = $VBoxContainer/VBoxContainer/HBoxContainer2/SortByOptionButton
onready var _order_button = $VBoxContainer/VBoxContainer/HBoxContainer2/OrderOptionButton
onready var _sort_button = $VBoxContainer/VBoxContainer/HBoxContainer2/SortButton


func _ready() -> void:
	var top_level = "VBoxContainer/VBoxContainer/HBoxContainer/"
	get_node(top_level + "Search") \
		.connect("text_entered", self, "search")
	get_node(top_level + "ExportButton") \
		.connect("pressed", self, "on_ExportButton_pressed")
	
	var top_level2 = "VBoxContainer/HBoxContainer/"
	get_node(top_level2 + "EditButton") \
		.connect("pressed", self, "enable_edits")
	get_node(top_level2 + "ImportButton") \
		.connect("pressed", self, "on_ImportButton_pressed")
	get_node(top_level2 + "AddButton") \
		.connect("pressed", self, "add_entry")
	get_node(top_level2 + "CancelButton") \
		.connect("pressed", self, "on_CancelButton_pressed")
	get_node(top_level2 + "SaveButton") \
		.connect("pressed", self, "on_SaveButton_pressed")
	$ImportFileDialog \
		.connect("file_selected", self, "import_paths_from")
#	$ExportFileDialog \
#		.connect("file_selected", self, "export_paths_to")
	$Export.connect("export_set", self, "on_Export_export_set")
	
	_sort_button.connect("pressed", self, "on_SortButton_pressed")
	
	for option in SortBy:
		_sort_by_button.add_item(option.to_lower())
	
	for order in ["ascending", "descending"]:
		_order_button.add_item(order)
	
	_old_data = _read_JSON_data()
	_add_entries(_old_data)
	# Don't use _scroll_to() here as need the yield() in this method
	yield(get_tree(), "idle_frame")
	_scroll_container.set_v_scroll(0)

func enable_edits() -> void:
	""" Enables the ability to edit entries """
	for entry in _entry_nodes:
		entry.set_disabled(false)
	$VBoxContainer/HBoxContainer/EditButton.set_disabled(true)
	$VBoxContainer/HBoxContainer/ImportButton.set_disabled(false)
	$VBoxContainer/HBoxContainer/AddButton.set_disabled(false)
	$VBoxContainer/HBoxContainer/CancelButton.set_disabled(false)
	$VBoxContainer/HBoxContainer/SaveButton.set_disabled(false)
#	_old_data = _get_entry_data()
	_can_edit = true

func disable_edits() -> void:
	""" Disables the ability to edit entries """
	for entry in _entry_nodes:
		entry.set_disabled(true)
	$VBoxContainer/HBoxContainer/EditButton.set_disabled(false)
	$VBoxContainer/HBoxContainer/ImportButton.set_disabled(true)
	$VBoxContainer/HBoxContainer/AddButton.set_disabled(true)
	$VBoxContainer/HBoxContainer/CancelButton.set_disabled(true)
	$VBoxContainer/HBoxContainer/SaveButton.set_disabled(true)
	_can_edit = false

func sort() -> void:
	""" Sorts the Entry nodes based on the user's input """
	var sort_input = _get_sort_input()
	_sort(sort_input[0], sort_input[1])

func search(text: String) -> void:
	""" 
	Match entries that contain the text in either their name or path. Hide the 
	entries that do not match
	"""
	text = text.to_lower()
	for entry in _entry_nodes:
		entry.set_visible(true)
	if text == "":
		return
	for entry in _entry_nodes:
		var path = entry.get_path_input().to_lower()
		var title = entry.get_name_input().to_lower()
		if not text in path and not text in title:
			entry.set_visible(false)

func add_entry(path: String="", title: String="", notes: String="") -> Node:
	""" Adds an empty entry below the others """
	var entry = Entry.instance()
	_entry_parent_node.add_child(entry)
	entry.close_btn.connect("pressed", self, "delete_entry", [entry])
	entry.set_path_input(path)
	entry.set_name_input(title)
	entry.set_notes_input(notes)
	entry.set_disabled(not _can_edit)
	_entry_nodes.append(entry)
	_scroll_to(_scroll_container.get_v_scrollbar().get_max())
	return entry

func delete_entry(entry: Node) -> void:
	_entry_parent_node.remove_child(entry)
	_entry_nodes.erase(entry)
	entry.queue_free()

func save_entries() -> void:
	""" Saves the data in the entry nodes to the JSON file """
	var data = _get_entry_data()
	_save(data)

func import_paths_from(filepath: String) -> void:
	""" Replaces current entries with the imported ones """
	var file = _open_file(filepath, File.READ)
	var content = file.get_as_text()
	var lines = content.split("\n")
	var data = []
	for line in lines:
		var stripped_line = line.strip_edges()
		if stripped_line == "":
			continue
		data.append([stripped_line, "", ""])
	_remove_all_entries()
	_add_entries(data)

func export_paths_to(filepath: String) -> void:
	""" Save the list of paths as plain text to the passed file location """
	var dir = filepath.get_base_dir()
	var file_name = filepath.get_file()
	if file_name == "":
		file_name = "filepaths_export.txt"
	var paths = []
	for item in _get_entry_data():
		paths.append(item[0])
	var file = _open_file(dir + "/" + file_name, File.WRITE)
	if file != null:
		var paths_string = ""
		for path in paths:
			if path != "":
				paths_string += path + "\n"
		file.store_string(paths_string)
		file.close()

func on_SortButton_pressed() -> void:
	sort()

func on_SaveButton_pressed() -> void:
	disable_edits()
	save_entries()

func on_CancelButton_pressed() -> void:
	disable_edits()
	_revert_changes()

func on_ImportButton_pressed() -> void:
	$ImportFileDialog.show()

func on_ExportButton_pressed() -> void:
	if _old_data != _get_entry_data():
		push_warning("Some data isn't saved")
	$Export.show()

func on_Export_export_set(path: String, selected_values: Array) -> void:
	_export(path, selected_values)

func _add_entries(data: Array) -> void:
	""" Creates entries with the passed data """
	for item in data:
		add_entry(item[0], item[1], item[2])

func _remove_all_entries() -> void:
	""" Removes all the entry nodes """
	for i in range(len(_entry_nodes)-1, -1, -1):
		delete_entry(_entry_nodes[i])

#func _get_entries() -> Array:
#	""" Returns the VBoxContainer nodes containing the inputs """
#	var entries = []
#	for node in _entry_parent_node.get_children():
#		if "Entry" in node.get_name():
#			entries.append(node)
#	return entries

#func _get_entry(idx: int) -> VBoxContainer:
#	""" Returns the entry node at position idx """
#	if idx < _entry_parent_node.get_child_count():
#		var node = _entry_parent_node.get_child(idx)
#		if "Entry" in node.get_name():
#			return node
#	return null

func _get_entry_data() -> Array:
	""" Returns an array containing [path, name, notes] for each entry """
	var data = []
	for entry in _entry_nodes:
		var title = entry.get_name_input()
		var path = entry.get_path_input()
		var notes = entry.get_notes_input()
		data.append([path, title, notes])
	return data

func _save(data: Array) -> void:
	""" Saves the passed data to the JSON file """
	var json_file = _open_file(save_location, File.WRITE)
	if json_file != null:
		json_file.store_string(to_json(data))
		json_file.close()
	_old_data = data

func _revert_changes() -> void:
	""" 
	Returns all entries to their state before the edit button was pressed
	"""
	_remove_all_entries()
	_add_entries(_old_data)

func _get_sort_input() -> Array:
	""" Returns the sorting options selected by the user """
	# Index of selected ID maps to value of item in SortBy enum
	var option = _sort_by_button.get_selected()
	# This evaluated so ascending is true and descending is false
	var ascending = bool(_order_button.get_selected() - 1)
	return [option, ascending]

func _sort(option, ascending=true) -> void:
	""" Sorts the entries by the given options """
	# Initially sort it by SortBy.None
	for child in _entry_parent_node.get_children():
		_entry_parent_node.remove_child(child)
	for entry in _entry_nodes:
		_entry_parent_node.add_child(entry)
	
	if option != SortBy.None:
		for i in range(1, len(_entry_nodes)):
			for j in range(i):
				if option == SortBy.Name:
					var name_i = _entry_parent_node.get_child(i) \
						.get_name_input().to_lower()
					var name_j = _entry_parent_node.get_child(j) \
						.get_name_input().to_lower()
					if (name_i < name_j ):
						_entry_parent_node.move_child(
							_entry_parent_node.get_child(i), j )
						break
				elif option == SortBy.Path:
					if (_entry_parent_node.get_child(i).get_path_input() 
							< _entry_parent_node.get_child(j).get_path_input() ):
						_entry_parent_node.move_child(
							_entry_parent_node.get_child(i), j)
						break
	
	if ascending == false:
		# Reverse the order of the nodes
		var nodes = _entry_parent_node.get_children()
		for child in _entry_parent_node.get_children():
			_entry_parent_node.remove_child(child)
		for i in range(len(nodes)-1, -1, -1):
			_entry_parent_node.add_child(nodes[i])

func _scroll_to(pos: int) -> void:
	""" Scrolls the scroll container to the given position """
	yield(get_tree(), "idle_frame")
	_scroll_container.set_v_scroll(
		_scroll_container.get_v_scrollbar().get_max() )

func _export(filepath: String, values: Array) -> void:
	""" Export the data as a CSV file """
	var dir = Directory.new()
	var path_dir = filepath.get_base_dir()
	var file_name = filepath.get_file()
	
	var err_msg = ""
	if not dir.dir_exists(path_dir):
		err_msg = "Data not exported, directory doesn't exist"
	elif file_name == "":
		err_msg = "Data not exported, no filename specified"
	elif not true in values:
		err_msg = "Data not exported, no values selected to export"
	if err_msg != "":
		push_warning(err_msg)
		$AcceptDialog.set_text(err_msg)
		$AcceptDialog.popup_centered(Vector2(200, 100))
		return
	
	# Get the indexes of the values to save
	var indexes_to_save = []
	var search_start = 0
	for _i in range(len(values)):
		var idx = values.find(true, search_start)
		if idx != -1:
			indexes_to_save.append(idx)
			search_start = idx + 1
		else:
			break
	
	var export_data = []
	for entry in _old_data:
		var extracted = []
		for idx in indexes_to_save:
			extracted.append(entry[idx])
		export_data.append(extracted)
	
	var file = _open_file(path_dir + "/" + file_name, File.WRITE)
	if file != null:
		var data_string = ""
		for entry in export_data:
			var line = ""
			for data in entry:
				line += data + ","
			line = line.trim_suffix(",")
			data_string += line + "\n"
		file.store_string(data_string)
		file.close()
	var msg = "Data exported to: " + filepath
	$AcceptDialog.set_text(msg)
	$AcceptDialog.popup_centered(Vector2(200, 100))

func _read_JSON_data() -> Array:
	""" 
	Returns the data from the JSON save file provided it is an array otherwise 
	returns an empty array
	"""
	var json_file = _open_file(save_location, File.READ)
	if json_file == null:
		return []
	else:
		var text = json_file.get_as_text()
		var data
		if text != "":
			data = parse_json(text)
		json_file.close()
		if typeof(data) != TYPE_ARRAY:
			data = []
		return data

func _open_file(filepath: String, mode: int) -> File:
	"""
	Returns the openend file or throws an error and displays a popup if it 
	failed
	"""
	var file = File.new()
	# The file is not created automatically if the mode == READ 
	# or mode == READ_WRITE, so create it in case the mode is one of those
	if not file.file_exists(filepath):
		file.open(filepath, File.WRITE)
		file.close()
	var err = file.open(filepath, mode)
	if err == OK:
		return file
	else:
		var msg = "Error opening the file"
		$AcceptDialog.set_text(msg)
		$AcceptDialog.popup_centered(Vector2(200, 100))
		push_error(msg)
		return null
