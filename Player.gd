extends KinematicBody2D

const speed = 300

var hp = 500 setget set_hp
var velocity = Vector2(0,0)
var can_shoot = true
var is_reloading = false
var shoot_mode = false

var bullet = load("res://Bullet.tscn")

puppet var puppet_hp = 500 setget puppet_hp_set
puppet var puppet_position = Vector2(0,0) setget puppet_position_set
puppet var puppet_velocity = Vector2()
puppet var puppet_rotation = 0


func _ready():
	
	Global.alive_players.append(self)
	
	yield(get_tree(), "idle_frame")
	if is_network_master():
		Global.player_master = self

func _process(delta: float) -> void:
	
	if is_network_master():
		var x_input = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
		var y_input = int(Input.is_action_pressed("down")) - int(Input.is_action_pressed("up"))
		
		velocity = Vector2(x_input, y_input).normalized()
		
		move_and_slide(velocity * speed)
		
		if $Sprite.is_visible_in_tree():
			look_at(get_global_mouse_position())
		
		if Input.is_action_pressed("click") and can_shoot and not is_reloading:
			rpc("instance_bullet", get_tree().get_network_unique_id())
			is_reloading = true
			$reload_timer.start()
		
	else:
		rotation_degrees = lerp(rotation_degrees, puppet_rotation, delta * 8)
		
		if not $Tween.is_active():
			move_and_slide(puppet_velocity * speed)
		
	if hp <= 0:
		if get_tree().is_network_server():
			rpc("destroy")
		
func puppet_position_set(new_value) -> void:
	puppet_position = new_value
	
	$Tween.interpolate_property(self, "global_position", global_position, puppet_position, 0.1)
	$Tween.start()

func set_hp(new_value):
	hp = new_value
	
	if is_network_master():
		rset("puppet_hp", hp)
		
func puppet_hp_set(new_value):
	puppet_hp = new_value
	
	if not is_network_master():
		hp = puppet_hp

func _on_network_tick_rate_timeout():
	if is_network_master():
		rset_unreliable("puppet_position", global_position)
		rset_unreliable("puppet_velocity", velocity)
		rset_unreliable("puppet_rotation", rotation_degrees)
		
sync func instance_bullet(id):
	var bullet_instance = Global.instance_node_at_location(bullet, Players, $shoot_point.global_position)
	bullet_instance.name = "Bullet" + name + str(Network.networked_object_name_index)
	bullet_instance.set_network_master(id)
	bullet_instance.player_rotation = rotation
	bullet_instance.player_owner = id
	Network.networked_object_name_index += 1

sync func update_position(pos):
	global_position = pos
	puppet_position = pos

func _on_reload_timer_timeout():
	is_reloading = false


func _on_hit_timer_timeout():
	modulate = Color(1,1,1,1)


func _on_hitbox_area_entered(area):
	if get_tree().is_network_server():
		if area.is_in_group("player_damager") and area.get_parent().player_owner != int(name):
			rpc("hit_by_damager", area.get_parent().damage)
			area.get_parent().rpc("destroy")

sync func hit_by_damager(damage):
	
	if shoot_mode:
		hp -= damage
	modulate = Color(5,5,5,1)
	$hit_timer.start()

sync func destroy():
	$Sprite.visible = false
	can_shoot = false
	$CollisionShape2D.disabled = true
	$hitbox/CollisionShape2D.disabled = true
	
	Global.alive_players.erase(self)
	
	if is_network_master():
		Global.player_master = null

func _exit_tree():
	Global.alive_players.erase(self)
	if is_network_master():
		Global.player_master = null
		
