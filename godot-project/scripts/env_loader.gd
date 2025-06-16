extends Node3D
var env: Dictionary = {}
var path = ""
func _ready():
	
	if OS.has_feature("editor"):
		path = ProjectSettings.globalize_path("res://").path_join("../.env").simplify_path()
	else:
		path = OS.get_executable_path().get_base_dir().path_join(".env")
		
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		while not file.eof_reached():
			var line = file.get_line()
			line = line.strip_edges()
			if line == "" or line.begins_with("#"):
				continue
			var pair = line.split("=", false, 2)
			if pair.size() == 2:
				env[pair[0].strip_edges()] = pair[1].strip_edges()

		if not get_var("READ_KEY"):
			print("No read key found, can not read data from server")
	else:
		print("No .env file found at: %s" % path)

func get_var(key: String, default: String = "") -> String:
	return env.get(key, default)
func exists():
	return true
