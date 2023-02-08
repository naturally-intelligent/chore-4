extends Control

var no_back_button = true
var no_hud = true
var label_count = 0

func _on_MainMenu_pressed() -> void:
	menus.show('main')

func _on_AddLabel_pressed() -> void:
	var label = Label.new()
	label_count += 1
	label.text = 'Chore ' + str(label_count)
	$LabelContainer.add_child(label)

func _on_BoringButton_pressed():
	scenes.show('boring')

func _on_Previous_pressed():
	scenes.show('play')
