extends Node3D

@export var jg: Node3D
var ip: Array[MeshInstance3D]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	var nodes =  jg.get_node("Room Info Points").get_children()
	for i in nodes:
		var sb = Area3D.new()
		#sb.set_collision_layer_value(1, false)
		#sb.set_collision_layer_value(3, true)
		var cs = CollisionShape3D.new()
		cs.shape = BoxShape3D.new()
		cs.shape.size = Vector3(0.8,0.8,0.8)
		sb.add_child(cs)
		i.add_child(sb)
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
