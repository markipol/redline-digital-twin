@tool
extends VBoxContainer


var show_in_toolbar: ButtonGroup = ButtonGroup.new()
var manager: Node

func _ready():
	$Plugin.visible = false
	$ResyncContainer/Resync.pressed.connect(resync)
	
func set_manager(m: Node):
	manager = m
	
func resync():
	print("Resyncing plugin menu and toolbar")
	manager.resync()


func build_menu(plugins):
	for c in get_children():
		if c.name not in ["Plugin", "ResyncContainer"]:
			remove_child(c)
	for dir in plugins:
		var display_name = plugins[dir][0]
		var active = plugins[dir][1]
		var new_node = $Plugin.duplicate(true)
		new_node.name = dir
		new_node.get_node("NameScroll/NameContainer/Name").text = display_name
		new_node.get_node("Enabled").toggled.connect(Callable(_on_enabled_toggled).bind(dir))
		new_node.get_node("Enabled").set_pressed_no_signal(active)
		new_node.get_node("Refresh").pressed.connect(Callable(_on_refresh_pressed).bind(dir))
		new_node.get_node("Refresh").icon = get_theme_icon("Reload", "EditorIcons")
		new_node.get_node("Refresh").disabled = not active
		new_node.get_node("ShowInToolbar").button_group = show_in_toolbar
		new_node.get_node("ShowInToolbar").pressed.connect(Callable(_on_favorite_pressed).bind(dir))
		new_node.visible = true
		add_child(new_node)
	move_child($ResyncContainer, -1)
	
func _on_enabled_toggled(toggled_on: bool, dir: String):
	if toggled_on:
		var success = manager.turn_plugin_on(dir)
		if success:
			get_node(dir + "/Refresh").disabled = false
		else:
			printerr("Plugin menu cannot turn plugin " + dir + " on because it is already on. The menu is out of sync, please re sync.")
	else:
		var success = manager.turn_plugin_off(dir)
		if success:
			get_node(dir + "/Refresh").disabled = true
		else:
			printerr("Plugin menu cannot turn plugin " + dir + " off because it is already off. The menu is out of sync, please re sync.")

func _on_refresh_pressed(dir: String):
	var success = manager.refresh_plugin(dir)
	if not success:
		printerr("Plugin menu cannot refresh plugin " + dir + " because it is off. The menu is out of sync, please re sync.")

func _on_favorite_pressed(dir: String):
	manager.change_favorite_plugin(dir)
