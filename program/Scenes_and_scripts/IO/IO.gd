extends Node

onready var accept_dialog = (
	get_tree().get_root().get_node("Main").get_node("AcceptDialog") )


func group_exists(filepath: String, group_title: String) -> bool:
	return _read_JSON_data(filepath).has(group_title)

func get_group_list(filepath: String) -> Array:
	return _read_JSON_data(filepath).keys()

func get_group_data(filepath: String, group_title: String) -> Array:
	return _read_JSON_data(filepath)[group_title]

func save_group_data(filepath: String, group_title: String, data: Array) -> void:
	var json_file = _open_file(filepath, File.READ)
	if json_file != null:
		var json_data = parse_json(json_file.get_as_text())
		json_data[group_title] = data
		json_file.close()
		_save_JSON_data(filepath, json_data)

func delete_group(filepath: String, group_title: String) -> void:
	var json_file = _open_file(filepath, File.READ)
	if json_file != null:
		var json_data = parse_json(json_file.get_as_text())
		json_data.erase(group_title)
		json_file.close()
		_save_JSON_data(filepath, json_data)

func import_from(filepath: String) -> Array:
	"""
	Reads text file for data.
	Currently only imports file paths.
	"""
	var file = _open_file(filepath, File.READ)
	var content = file.get_as_text()
	var lines = content.split("\n")
	var data = []
	for line in lines:
		var stripped_line = line.strip_edges()
		if stripped_line == "":
			continue
		data.append([stripped_line, "", ""])
	return data

func export_data(from: String, to: String, groups: Array, values: Array) -> void:
	"""
	Export the data as a CSV file.
	
	Args:
		from: path to read the data from
		to: path to write the data to
		groups: names of the groups to export the data from
		values: contains boolean values [path, name, notes] indicating wether 
			or not to export those values
	"""
	var dir = Directory.new()
	var path_dir = to.get_base_dir()
	var file_name = to.get_file()
	
	var err_msg = ""
	if not dir.dir_exists(path_dir):
		err_msg = "Data not exported, directory doesn't exist"
	elif file_name == "":
		err_msg = "Data not exported, no filename specified"
	elif not true in values:
		err_msg = "Data not exported, no values selected to export"
	if err_msg != "":
		push_warning(err_msg)
		accept_dialog.set_text(err_msg)
		accept_dialog.popup_centered(Vector2(200, 100))
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
	
	# Array of the form [[first group]] -> [[[path, title, notes]]]
	# The options given by `values` determines where any of "path", "title" or 
	# "notes" are actually put in the array
	var data_to_export = []
	for group in groups:
		# Stores the chosen `values` for the current `group`
		var group_extracted = []
		for entry in get_group_data(from, group):
			# Stores the data types chosen from `values`, from `entry`
			var extracted = []
			for idx in indexes_to_save:
				extracted.append(entry[idx])
			group_extracted.append(extracted)
		data_to_export.append(group_extracted)
	
	var file = _open_file(path_dir + "/" + file_name, File.WRITE)
	if file != null:
		var data_string = ""
		for i in range(len(data_to_export)):
			data_string += "---- " + groups[i] + " ----\n"
			for entry in data_to_export[i]:
				var line = ""
				for data in entry:
					line += data + ","
				line = line.trim_suffix(",")
				data_string += line + "\n"
		file.store_string(data_string)
		file.close()
	var msg = "Data exported to: " + to
	accept_dialog.set_text(msg)
	accept_dialog.popup_centered(Vector2(200, 100))

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
		accept_dialog.set_text(msg)
		accept_dialog.popup_centered(Vector2(200, 100))
		push_error(msg)
		return null

func _read_JSON_data(filepath) -> Dictionary:
	""" 
	Returns the data from the JSON save file provided it is an array otherwise 
	returns an empty array
	"""
	var json_file = _open_file(filepath, File.READ)
	if json_file == null:
		return {}
	else:
		var text = json_file.get_as_text()
		var data
		if text != "":
			data = parse_json(text)
		json_file.close()
		if typeof(data) != TYPE_DICTIONARY:
			data = {}
		return data

func _save_JSON_data(filepath: String, data: Dictionary) -> void:
	""" Saves the passed data to the JSON file """
	var json_file = _open_file(filepath, File.WRITE)
	if json_file != null:
		json_file.store_string(to_json(data))
		json_file.close()
