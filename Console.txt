extends Control


var player = load("res://Player.tscn")


var hidden = false
var startGame = false

func _ready():
	$txt_commands.grab_focus()
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_to_server")
	
	
	add_command("\n\nClient's current IP Address is: " + Network.ip_address + "\n\n")
	

func _process(delta):
	if get_tree().network_peer != null:
		if get_tree().get_network_connected_peers().size() >= 1 and get_tree().is_network_server():
			startGame = true
		else:
			startGame = false
			
			

func _player_connected(id):
	add_command("Player " + str(id) + " has connected.")
	add_command("\nThe game can start now. Waiting for host to enter 'start' commmand...")
	instance_player(id)
	
func _player_disconnected(id):
	add_command("Player " + str(id) + " has disconnected.")
	
	if Players.has_node(str(id)):
		Players.get_node(str(id)).queue_free()

func add_command(txt):
	$console_text.text += "\n" + txt

func create_server():
	Network.create_server()
	add_command("\nGame created!\nto join this server, type: join " + Network.ip_address)
	
	instance_player(get_tree().get_network_unique_id())

func join_server(ip):
	Network.ip_address = ip
	Network.join_server() 


func _on_txt_commands_text_entered(new_text):
	
	if new_text != "":
		add_command(new_text)
		$txt_commands.text = ""
		
		var txt = new_text.split(" ")
		
		if txt[0] == "create":
			create_server()
			Network.current_username = txt[1]
		elif txt[0] == ("join"):
			join_server(txt[1])
			Network.current_username = txt[2]
		elif txt[0] == "start":
			
			if startGame:
				rpc("switch_to_game")
			
	

func _input(event):
	if event.is_action_pressed("console"):
		hidden = !hidden
		
		if(hidden):
			show()
		else:
			hide()
			
		
func _connected_to_server():
	yield(get_tree().create_timer(0.1), "timeout")
	instance_player(get_tree().get_network_unique_id())
		
func instance_player(id) -> void:
	var player_instance = Global.instance_node_at_location(player, Players, Vector2(rand_range(0, 1270), rand_range(0,720)))
	player_instance.name = str(id)
	player_instance.set_network_master(id)

sync func switch_to_game():
	
	for child in Players.get_children():
		if child.is_in_group("player"):
			child.shoot_mode = true
	
	get_tree().change_scene("res://Game.tscn")

