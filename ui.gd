extends CanvasLayer

func _ready():
	$Control/winner.hide()
	
	
func _process(delta):
	if Global.alive_players.size() <= 1:
		if Global.alive_players[0].name == str(get_tree().get_network_unique_id()):
			$Control/winner/label.text = "YOU WIN!"
		else:
			$Control/winner/label.text = "YOU LOSE!"
			
		$Control/winner.show()
