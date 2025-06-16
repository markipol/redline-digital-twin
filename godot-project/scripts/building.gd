extends Node3D

func _ready() -> void:
	for floor in $floors.get_children():
		for child in floor.get_children():
			if child.name == "points":
				process_info_points(child)


func process_info_points(points_node: Node):
	for n in points_node.get_children():
		var area = Area3D.new()
		area.add_to_group("info_points")
		var cs = CollisionShape3D.new()
		cs.shape = BoxShape3D.new()
		cs.shape.size = Vector3(0.8, 0.8, 0.8)
		area.add_child(cs)
		n.add_child(area)
