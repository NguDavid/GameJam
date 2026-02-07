extends CharacterBody2D

@export var walk_speed: float = 100.0
@export var run_speed: float = 200.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var current_weapon: String = "Normal"
var last_direction: String = "Down"

func _physics_process(delta: float) -> void:
	update_weapon_type()
	on_move_event(delta)

func update_weapon_type() -> void:
	if Input.is_action_just_pressed("Normal"):
		current_weapon = "Normal"
	elif Input.is_action_just_pressed("Spear"):
		current_weapon = "Spear"
	elif Input.is_action_just_pressed("Gun"):
		current_weapon = "Gun"

func get_direction_string(dir: Vector2) -> String:
	if dir.y < -0.3:
		if dir.x > 0.3: 
			return "Right_Up"
		if dir.x < -0.3: 
			return "Left_Up"
		return "Up"
	elif dir.y > 0.3:
		if dir.x > 0.3: 
			return "Right"
		if dir.x < -0.3: 
			return "Left"
		return "Down"
	return "Right" if dir.x > 0 else "Left"

func on_move_event(delta: float) -> void:
	var input_vector = Input.get_vector("Left", "Right", "Up", "Down")
	var is_running = Input.is_action_pressed("Run")
	
	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized()
		var speed = run_speed if is_running else walk_speed
		position += input_vector * speed * delta
		last_direction = get_direction_string(input_vector)
		var state = "Run" if is_running else "Walk"
		animated_sprite.play(state + "_" + current_weapon + "_" + last_direction)
	else:
		animated_sprite.play("Idle_" + current_weapon + "_" + last_direction)
