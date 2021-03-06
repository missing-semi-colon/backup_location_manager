extends Node

export (PackedScene) var MainView_pkscene
export (PackedScene) var CmdLine_pkscene

var save_location = "./paths.json"
# Whether using the GUI or command line
var graphical = true


func _ready():
	if IO._open_file(save_location, File.READ).get_as_text() == "":
		IO.initialise_save_file(save_location)
	
	var args = Array(OS.get_cmdline_args())
	if len(args) == 0:
		graphical = true
		var main_view = MainView_pkscene.instance()
		main_view.init(save_location)
		add_child(main_view)
	else:
		graphical = false
		var cmd_line = CmdLine_pkscene.instance()
		cmd_line.init(save_location)
		var parsed = cmd_line.parse_args(args)
		cmd_line.execute_args(parsed)
		cmd_line.queue_free()
		yield(get_tree(), "idle_frame")
		get_tree().quit()
