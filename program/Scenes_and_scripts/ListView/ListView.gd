extends Control
class_name ListView

export (PackedScene) var Entry

enum SortBy {
	None,
	Name, 
	Path
}

var save_location
var group_title
var _can_edit = false
var _old_data = []    # Stores the Entry data from the last save
var _entry_nodes = []    # Stores the Entry nodes in the order they were added
onready var _scroll_container = $VBoxContainer/ScrollContainer
onready var _entry_parent_node = $VBoxContainer/ScrollContainer/VBoxContainer/Entries
onready var _sort_by_button = $VBoxContainer/VBoxContainer/HBoxContainer2/SortByOptionButton
onready var _order_button = $VBoxContainer/VBoxContainer/HBoxContainer2/OrderOptionButton
onready var _sort_button = $VBoxContainer/VBoxContainer/HBoxContainer2/SortButton


func init(sv_location: String, grp_title: String) -> void:
	save_location = sv_location
	group_title = grp_title

func _ready() -> void:
	for vari in [group_title, save_location]:
		if vari == null or vari == "":
			push_error("ListView not initialised with required variables")
			return
	
	var top_level = "VBoxContainer/VBoxContainer/HBoxContainer/"
	get_node(top_level + "Search") \
		.connect("text_entered", self, "search")
	
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
	
	_sort_button.connect("pressed", self, "on_SortButton_pressed")
	$ImportFileDialog \
		.connect("file_selected", self, "on_ImportFileDialog_file_selected")
	
	for option in SortBy:
		_sort_by_button.add_item(option.to_lower())
	
	for order in ["ascending", "descending"]:
		_order_button.add_item(order)
	
	if IO.group_exists(save_location, group_title):
		_old_data = IO.get_group_data(save_location, group_title)
		_add_entries(_old_data)
	_scroll_to(0)

func enable_edits() -> void:
	""" Enables the ability to edit entries """
	for entry in _entry_nodes:
		entry.set_disabled(false)
	$VBoxContainer/HBoxContainer/EditButton.set_disabled(true)
	$VBoxContainer/HBoxContainer/ImportButton.set_disabled(false)
	$VBoxContainer/HBoxContainer/AddButton.set_disabled(false)
	$VBoxContainer/HBoxContainer/CancelButton.set_disabled(false)
	$VBoxContainer/HBoxContainer/SaveButton.set_disabled(false)
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
	""" Adds an entry below the others """
	var entry = Entry.instance()
	_entry_parent_node.add_child(entry)
	entry.close_btn.connect("pressed", self, "delete_entry", [entry])
	entry.set_path_input(path)
	entry.set_name_input(title)
	entry.set_notes_input(notes)
	entry.set_disabled(not _can_edit)
	_entry_nodes.append(entry)
	_scroll_to_end()
	return entry

func delete_entry(entry: Node) -> void:
	_entry_parent_node.remove_child(entry)
	_entry_nodes.erase(entry)
	entry.queue_free()

func save_entries() -> void:
	""" Saves the data in the entry nodes to the JSON file """
	var data = _get_entry_data()
	IO.save_group_data(save_location, group_title, data)
	_old_data = data

func is_data_saved():
	""" Returns false if there is unsaved data """
	return _old_data == _get_entry_data()

func on_SortButton_pressed() -> void:
	sort()

func on_SaveButton_pressed() -> void:
	disable_edits()
	save_entries()

func on_CancelButton_pressed() -> void:
	var current_scroll = _scroll_container.get_v_scroll()
	disable_edits()
	_revert_changes(current_scroll)

func on_ImportButton_pressed() -> void:
	$ImportFileDialog.show()

func on_ImportFileDialog_file_selected(filepath: String) -> void:
	"""
	Replaces the data in this group with the data imported from `filepath`
	"""
	var data = IO.import_from(filepath)
	_import_data(data)

func _add_entries(data: Array) -> void:
	""" Creates entries with the passed data """
	for item in data:
		add_entry(item[0], item[1], item[2])

func _remove_all_entries() -> void:
	""" Removes all the entry nodes """
	for i in range(len(_entry_nodes)-1, -1, -1):
		delete_entry(_entry_nodes[i])

func _import_data(data: Array) -> void:
	_remove_all_entries()
	_add_entries(data)

func _get_entry_data() -> Array:
	""" Returns an array containing [path, name, notes] for each entry """
	var data = []
	for entry in _entry_nodes:
		var title = entry.get_name_input()
		var path = entry.get_path_input()
		var notes = entry.get_notes_input()
		data.append([path, title, notes])
	return data

func _revert_changes(current_scroll_pos: int=0) -> void:
	""" 
	Returns all entries to their state before the edit button was pressed
	"""
	_remove_all_entries()
	_add_entries(_old_data)
	_scroll_to(current_scroll_pos)

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
					var path_i = _entry_parent_node.get_child(i) \
						.get_path_input().to_lower()
					var path_j = _entry_parent_node.get_child(j) \
						.get_path_input().to_lower()
					if (path_i < path_j ):
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
	_scroll_container.set_v_scroll(pos)

func _scroll_to_end() -> void:
	""" Scrolls the scroll container to the end """
	_scroll_to(_scroll_container.get_v_scrollbar().get_max())
