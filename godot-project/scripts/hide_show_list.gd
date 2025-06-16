extends PanelContainer

@export var building: Node3D
@export var player: CharacterBody3D
var current_floor: Node3D
@onready var move_sel:OptionButton = $"VBoxContainer/FloorsBox/MovementMode/Selector"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var ok = $"VBoxContainer/FloorsBox/Height Lock/CheckButton".toggled.connect(_toggle_height_lock)
	$"VBoxContainer/FloorsBox/Rest of building/CheckBox".toggled.connect(_show_only_rest_of_building)
	var floors_box = $"VBoxContainer/FloorsBox"
	var found = false
	
	for child in floors_box.get_children():
		var child_name = child.name.to_lower()
		if child is Control and child_name.begins_with("floor "):
			var checkbox = child.get_node_or_null("CheckBox")
			if checkbox:
				checkbox.toggled.connect(Callable(_show_only_floor).bind(child_name))
				found = true

	if not found:
		push_error("No floor checkboxes found in FloorsBox. Ensure children are named like 'floor 1', 'floor 2', etc.")

		
	var data: Label = $VBoxContainer/MarginContainer/Data
	data.text = "Info for rooms shown here"
	#add_child(data)
	$VBoxContainer.move_child($VBoxContainer/MarginContainer, -1)
	current_floor = building.get_node("rest of building")
	
	
#	
func exists() -> bool:
	return true
func _toggle_height_lock(toggled_on: bool):
	print("Toggle changed! New state:", toggled_on)
	if player == null:
		print("ERROR: player is null!")
	else:
		player.height_lock = toggled_on
		print("Height lock now:", player.height_lock)
func _show_only_floor(toggled_on: bool, name: String):
	building.get_node("rest of building").visible = false
	for floor in building.get_node("floors").get_children():
		if floor.name == name.to_lower():
			toggle_floor(floor, true)
		else:
			toggle_floor(floor, false)
	# building.get_node("floors").get_node(name.to_lower()).visible = true
		
func toggle_floor(floor: Node3D, toggled_on: bool):
	# var floor = building.get_node("floors")
	floor.visible = toggled_on
	floor.get_node("exterior/exterior/CollisionShape3D").disabled = not toggled_on
	floor.get_node("interior/interior/CollisionShape3D").disabled = not toggled_on
	floor.get_node("plan/StaticBody3D/CollisionShape3D").disabled = not toggled_on
func _show_only_rest_of_building(toggled_on: bool):
	building.get_node("rest of building").visible = true
	for floor in building.get_node("floors").get_children():
		toggle_floor(floor, true)
	

#func _show_only_floor(toggled_on: bool, name: String):
	#print(name + ": " + str(toggled_on))
	#if toggled_on:
		#building.get_node("rest of building").visible = false
		#current_floor.visible = false
		#current_floor = building.get_node("floors").get_node(name.to_lower())
		#current_floor.visible = true
		#for child in current_floor.get_children():
			#child.visible = true
		#for floor: Node3D in building.get_node("floors").get_children():
			#if floor != current_floor:
				#for child in floor.get_children():
					#child.visible = false
#func _show_only_rest_of_building(toggled_on: bool):
	#if toggled_on:
		#
		#current_floor = building.get_node("rest of building")
		#building.get_node("rest of building").visible = true
		#for floor: Node3D in building.get_node("floors").get_children():
			#floor.visible = true
			#for child in floor.get_children():
				#if child.name == "exterior":
					#child.visible = true
				#else:
					#child.visible = false
	#

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_selector_item_selected(index: int) -> void:
	player.select_mode_int(index)
