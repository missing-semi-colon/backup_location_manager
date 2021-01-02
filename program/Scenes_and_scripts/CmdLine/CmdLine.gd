extends Node

# OPTIONS = [[[switches], parameters, description, parameter details], ...]
const OPTIONS = [
	[
		["-?"],
		"", 
		"shows the help list", 
		""
	],
	[
		["-g", "--export-groups"],
		"DEST PATH NAME NOTES GROUP1 [GROUP2, GROUP3, ...]" \
		+ "    exports the data in CSV format", 
		"", 
		"DEST is the filepath to write to, either an absolute path or relative" \
			+ " to the executable" \
		+ "\nPATH, NAME, NOTES take values of 0 or 1, where 1 indicates to" \
			+ " export those values and 0 to not export them" \
		+ "\nGROUP1, GROUP2, ... are the names of the groups to export"
	]
]

var save_location = "./paths.json"
const VALUES_PER_ENTRY = 3


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
	if "-?" in args.keys():
		_show_help(args)
		return
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
	if dest_dir[0] == ".":
		dest_dir[0] = OS.get_executable_path().get_base_dir()
	var dest_filename = dest.get_file()
	var abs_dest = dest_dir + "/" + dest_filename
	var dir = Directory.new()
	if not dir.dir_exists(dest_dir):
		var err_msg = "Directory doesn't exist"
		push_error(err_msg)
		return
	if dest_filename == "":
		var err_msg = "No filename specified"
		push_error(err_msg)
		return
	
	# Get which of: paths, names or notes, for each entry to export
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
	
	IO.export_data(save_location, abs_dest, groups, values)

func _show_help(args: Dictionary) -> void:
	"""
	Prints the list of possible arguments specified in `OPTIONS`. If the first 
	argument in `args` is not the help switch (-?) prints more detailed 
	information about the first argument.
	"""
	var first_arg = args.keys()[0]
	if first_arg != "-?":
		var arg_help = _find_arg_help(first_arg)
		if arg_help.size() > 0:
			var out = str(arg_help[0]).substr(1, len(str(arg_help[0])) - 2)
			out += " " + arg_help[1]
			out += "    " + arg_help[2] + "\n"
			out += arg_help[3]
			print(out)
			return
	for option in OPTIONS:
		var out = str(option[0]).substr(1, len(str(option[0])) - 2)
		out += " " + option[1]
		out += "    " + option[2]
		print(out)

func _find_arg_help(arg: String) -> Array:
	"""
	Returns the array from `OPTIONS` related to `arg`.
	"""
	for option in OPTIONS:
		if arg in option[0]:
			return option
	return []
