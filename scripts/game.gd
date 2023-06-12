extends Node2D

signal game_over

@export var world_speed = 300
@export var collectible_pitch_reset_interval = 2000

@onready var moving_enviroment = $"/root/World/Enviroment/Moving"
@onready var collect_sound = $"/root/World/Sounds/CollectSound"
@onready var score_label = $"/root/World/HUD/UI/Score"
@onready var ammo_label = $"/root/World/HUD/UI/Ammo"
@onready var player = $"/root/World/Player"
@onready var ground = $"/root/World/Enviroment/Static/Ground"
@onready var game_over_label = $"/root/World/HUD/UI/GameOver"


var plattform = preload("res://scenes/plattform.tscn")
var plattform_collectible_single = preload("res://scenes/plattform_collectible_single.tscn")
var plattform_collectible_row = preload("res://scenes/plattform_collectible_row.tscn")
var plattform_collectible_column = preload("res://scenes/plattform_collectible_column.tscn")
var plattform_enemy = preload("res://scenes/plattform_enemy.tscn")
var plattform_ammo_collectible = preload("res://scenes/plattform_ammo_collectible.tscn")
var rng = RandomNumberGenerator.new()
var last_plattform_position = Vector2.ZERO
var next_spawn_time = 0
var score = 0
var collectible_pitch = 1.0
var reset_collectible_pitch_time = 0
#called when the node enters the scene tree for the first time
func _ready():
	rng.randomize()
	player.player_died.connect(_on_player_died)
	ground.body_entered.connect(_on_ground_body_entered)
	
#called every frame. 'delta' is elapsed time since the prev
func _process(delta):
	if not player.active:
		if Input.is_action_just_pressed("jump"):
			get_tree().reload_current_scene()
		return
		
	if Time.get_ticks_msec() > reset_collectible_pitch_time:
		collectible_pitch = 1.0
		
	#spawn new plattform
	if Time.get_ticks_msec() > next_spawn_time:
		_spawn_next_platfform()
		
	#update the UI labels
	score_label.text = "Score: %s"% score
	ammo_label.text = "Ammo: %s"% player.ammo
	
func _spawn_next_platfform():
	var avalaible_plattforms = [
		plattform,
		plattform_collectible_single,
		plattform_collectible_row,
		plattform_collectible_column,
		plattform_enemy,
		plattform_ammo_collectible
	]

	var new_plattform = avalaible_plattforms.pick_random().instantiate()
		#set position
	if last_plattform_position == Vector2.ZERO :
		new_plattform.position = Vector2(400,0)
	else:
		var x = last_plattform_position.x + rng.randi_range(450,550)
		var y = clamp(last_plattform_position.y + rng.randi_range(-150,150),200,1000)
		new_plattform.position = Vector2(x,y)
	#add plattform to the enviroment
	moving_enviroment.add_child(new_plattform)
	#update latplattform position and increase the next
	last_plattform_position = new_plattform.position
	next_spawn_time += world_speed

func _physics_process(delta):
	if not player.active:
		return
	#move plattforms left
	moving_enviroment.position.x -= world_speed * delta

func add_score(value):
	score += value
	collect_sound.set_pitch_scale(collectible_pitch)
	collect_sound.play()
	collectible_pitch += 0.1
	reset_collectible_pitch_time = Time.get_ticks_msec() + collectible_pitch_reset_interval
	
func _on_player_died():
	emit_signal("game_over")
	game_over_label.text = game_over_label.text % score
	game_over_label.set_visible(true)
	
func _on_ground_body_entered(body):
	if body.is_in_group("player"):
		player.die()
