#debug_label
extends Label

var target_node: Node
var properties: Array[String] = []
var parent_debug_prop_name = "debug_properties"
var no_data = "[N/A]"

func _ready():
	target_node = get_parent()
	if target_node == null:
		return

	var prop_names = target_node.get_property_list().map(func(d): return d.name)
	if parent_debug_prop_name in prop_names:
		properties = target_node.debug_properties
	
func _process(_delta):
	if target_node == null or properties.is_empty():
		return

	var lines := []
	for prop in properties:
		var value = _get_property_value(target_node, prop)
		var short_name = prop.substr(0, 3)  # lấy 3 ký tự đầu
		lines.append("%s: %s" % [short_name, value])

	text = "\n".join(lines)


func _get_property_value(node: Object, prop: String) -> String:
	var parts = prop.split(".")
	var current: Variant = node

	for p in parts:
		if current == null:
			return no_data

		if current is Object:
			if p in current.get_property_list().map(func(x): return x.name):
				current = current.get(p)
			elif current.has_method(p):
				current = current.call(p)
			else:
				return no_data
		elif typeof(current) == TYPE_DICTIONARY and current.has(p):
			current = current[p]
		else:
			return no_data

	if typeof(current) == TYPE_FLOAT:
		return str(round(current * 100) / 100.0)
	elif typeof(current) == TYPE_INT:
		return str(current)
	else:
		return str(current)
