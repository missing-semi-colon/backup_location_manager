extends Node

"""
OPTIONS
(--export-groups | -g) DEST PATH NAME NOTES GROUP1 [GROUP2, GROUP3, ...]
	DEST is the filepath to write to
	PATH, NAME, NOTES take values of 0 or 1, where 1 indicates to export those 
	values and 0 to not export them
	GROUP1, GROUP2, ... are the names of the groups to export
"""



var save_location = "./paths.json"
const VALUES_PER_ENTRY = 3
#var switches_to_funcs = {["--export-groups", "-g"]: funcref(self, "")}


func init(sv_location: String) -> void:
	save_location = sv_location

func parse_args(args: Array) -> Dictionary:
	var parsed = {}
	for i in range(len(args)):
		var is_switch
		if len(args[i]) == 0:
			continue
		is_switch = args[i][0] == "-"
		if is_switch:
			for j in range(i + 1, len(args)):
				var j_is_switch
				if len(args[j]) == 0:
					continue
				j_is_switch = args[j][0] == "-"
				if j_is_switch:
					parsed[args[i]] = args.slice(i + 1, j - 1)
					break
			if not parsed.has(args[i]):
				if i >= len(args) - 1:
					parsed[args[i]] = []
				else:
					parsed[args[i]] = args.slice(i + 1, len(args) - 1)
	return parsed

func execute_args(args: Dictionary) -> void:
	for switch in args.keys():
		if switch == "--export-groups" or switch == "-g":
			_export(args[switch])

func _export(params: Array) -> void:
	# At least 5 parameters are required
	if len(params) < 5:
		var err_msg = "Invalid parameters"
		push_error(err_msg)
		return
	
	var dest = params[0]
	var dest_dir = dest.get_base_dir()
	var dest_filename = dest.get_file()
	var dir = Directory.new()
	if not dir.dir_exists(dest_dir):
		var err_msg = "Directory doesn't exist"
		push_error(err_msg)
		return
	if dest_filename == "":
		var err_msg = "No filename specified"
		push_error(err_msg)
		return
	
	var values = []
	for count in range(1, VALUES_PER_ENTRY + 1):
		if params[count] == "1":
			values.append(true)
		elif params[count] == "0":
			values.append(false)
		else:
			var err_msg = "Invalid parameters"
			push_error(err_msg)
			return
	
	var groups = []
	for i in range(4, len(params)):
		groups.append(params[i])
	
	IO.export_data(save_location, dest, groups, values)
