@tool
extends EditorPlugin

var panel: PopupPanel
var base: Control
var menu
var list
var toolbar
var plugins


var fav_dir
var fav_active
var fav_display_name

var width = 450
var height = 250

func _enter_tree():
	# Get plugin info initially
	plugins = _get_plugins()
	# Set fav as first plugin found
	for p in plugins:
		if p:
			update_fav_vars(p)
			break
	# Load menu and get list
	menu = preload("plugin_manager_menu.tscn").instantiate()
	list = menu.get_node("ListScroll/List")
	# Connect toolbar signal to open menu
	toolbar = preload("toolbar_container.tscn").instantiate()
	toolbar.open_menu.connect(_open_menu)
	
	# Set toolbar manager variable to this script
	toolbar.set_manager(self)
	toolbar.update()
	# Add toolbar to top container
	add_control_to_container(CONTAINER_TOOLBAR, toolbar)
	# Define panel 
	# (Technically, it's a different window, which I don't like,
	# but isn't really that bad)
	panel = PopupPanel.new()
	#
	base = EditorInterface.get_base_control()
	base.resized.connect(_on_base_resized)
	# Add list to panel
	panel.add_child(menu)
	add_child(panel)
	list.build_menu(plugins)
	
	
	
	list.set_manager(self)
	
	
	

func resync():
	update_fav_vars(fav_dir)
	toolbar.update()
	rebuild_menu()
func _ready():
	panel.size = Vector2i(width,height)
	project_settings_changed.connect(resync)
# Function to reload menu when needed
func rebuild_menu():
	plugins = _get_plugins()
	list.build_menu(plugins)

# Refresh favorite plugin
func refresh_fav_plugin():
	refresh_plugin(fav_dir)

func refresh_plugin(p_dir: String) -> bool:
	print("Refreshing plugin: ", p_dir)
	var success = turn_plugin_off(p_dir)
	if not success:
		# Re-sync menu only when needed
		rebuild_menu()
		return false
	turn_plugin_on(p_dir)
	return true

func update_fav_vars(p_fav):
	plugins = _get_plugins()
	fav_dir = p_fav
	fav_display_name = plugins[p_fav][0]
	fav_active = plugins[p_fav][1]

func change_favorite_plugin(p_fav):
	update_fav_vars(p_fav)
	toolbar.update()

# These will return true if successful, false if not
func turn_plugin_on(p_dir: String) -> bool:
	print("Turning plugin on: ", p_dir)
	if not get_editor_interface().is_plugin_enabled(p_dir):
		get_editor_interface().set_plugin_enabled(p_dir, true)
		if p_dir == fav_dir:
			fav_active = true
		return true
	else:
		return false
func turn_plugin_off(p_dir: String) -> bool:
	print("Turning plugin off: ", p_dir)
	if get_editor_interface().is_plugin_enabled(p_dir):
		get_editor_interface().set_plugin_enabled(p_dir, false)
		if p_dir == fav_dir:
			fav_active = false
		return true
	else:
		return false

func get_plugin_path():
	return get_script().resource_path.get_base_dir()
#
func _get_plugins():
	var this_plugin = get_plugin_path().get_file()
	var plugins = {}
	var origins = {}
	var dir = DirAccess.open("res://addons/")
	dir.list_dir_begin()
	var file = dir.get_next()
	
	while file != '':
		
		var addon_dir = "res://addons/".path_join(file)
		if dir.dir_exists(addon_dir):
			var display_name = file
			var plugin_config_path = addon_dir.path_join("plugin.cfg")
			if not dir.file_exists(plugin_config_path):
				file = dir.get_next()
				print("Warning: directory '" + addon_dir + "' does not have a plugin.cfg and therefore can't be loaded")
				continue
			var plugin_cfg = ConfigFile.new()
			plugin_cfg.load(plugin_config_path)
			display_name = plugin_cfg.get_value("plugin", "name", file)
			if not display_name in origins:
				origins[display_name] = [file]
			else:
				origins[display_name].append(file)
			plugins[file] = display_name
		file = dir.get_next()
	# Specify the exact plugin name in parenthesis in case of naming collisions.
	for display_name in origins:
		var plugin_names = origins[display_name]
		if plugin_names.size() > 1:
			for n in plugin_names:
				plugins[n] = "%s (%s)" % [display_name, n]
	for p in plugins:
		var enabled = get_editor_interface().is_plugin_enabled(p)
		plugins[p] = [plugins[p], enabled]
	return plugins

func _on_base_resized():
	panel.hide()

func _open_menu():
	base = EditorInterface.get_base_control()
	var screen_pos = base.get_screen_position()
	panel.position = Vector2i(screen_pos.x + base.size.x - 450, screen_pos.y + 47)
	plugins = _get_plugins()
	list.build_menu(plugins)
	panel.popup()
	

func _exit_tree():
	remove_control_from_container(CONTAINER_TOOLBAR, toolbar)
	panel.hide()
	panel.remove_child(menu)
	toolbar.queue_free()
	panel.queue_free()
