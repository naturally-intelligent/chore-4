extends Node

func _get_joypad_type():
	var available := Input.get_connected_joypads()
	var device: int = available.front()

	var controller_name := Input.get_joy_name(device)
	var controller_match := controller_name.to_lower()
	var tests := ["steam", "nintendo", "logitech", "xbox", "x-box", "switch", "retro"]
	var alias := {"x-box": "xbox", "switch": "nintendo", "retro": "nintendo"}
	var found := "generic"
	for test in tests:
		if test in controller_match:
			found = test
	if alias[found]: found = alias[found]
	return found
