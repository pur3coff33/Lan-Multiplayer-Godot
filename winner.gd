extends ColorRect

sync func return_to_lobby():
	get_tree().change_scene("res://Console.tscn")

func _on_Button_pressed():
	if get_tree().is_network_server():
		rpc("return_to_lobby")
