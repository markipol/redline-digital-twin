@tool
extends HBoxContainer


signal open_menu()

var favorite_dir: String
var favorite_name: String
var manager: Node


func _ready():
	$RefreshFavorite.icon = get_theme_icon("Reload", "EditorIcons")
	$RefreshFavorite.pressed.connect(_on_refresh_favorite_pressed)
	
	$PluginButton.icon = get_theme_icon("EditorPlugin", "EditorIcons")
	$PluginButton.pressed.connect(_open_menu)
	
	$FavoriteName.pressed.connect(_open_menu)
	
	$ToggleFavorite.toggled.connect(_on_toggle_favorite_pressed)
	
func set_manager(m: Node):
	manager = m

func _open_menu():
	emit_signal("open_menu")

# Called when toolbar favorite is changed and data needs to be updated
# Favorite plugin dir is stored in manager itself, not toolbar
func update():
	$ToggleFavorite.set_pressed_no_signal(manager.fav_active)
	$FavoriteName.text = manager.fav_display_name
	$RefreshFavorite.disabled = not manager.fav_active
	
func _on_toggle_favorite_pressed(toggled_on: bool):
	var dir = manager.fav_dir
	if toggled_on:
		var success = manager.turn_plugin_on(dir)
		if success:
			$RefreshFavorite.disabled = false
		else:
			printerr("Plugin menu cannot turn plugin " + dir + " on because it is already on. The menu is out of sync, please re sync.")
	else:
		var success = manager.turn_plugin_off(dir)
		if success:
			$RefreshFavorite.disabled = true
		else:
			printerr("Plugin menu cannot turn plugin " + dir + " off because it is already off. The menu is out of sync, please re sync.")

	
func _on_refresh_favorite_pressed():
	var success = manager.refresh_plugin(manager.fav_dir)
	if not success:
		printerr("Plugin menu cannot refresh plugin " + manager.fav_dir + " because it is off. The menu is out of sync, please re sync.")
