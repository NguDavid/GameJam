extends CharacterBody2D

@export var walk_speed: float = 100.0
@export var run_speed: float = 200.0
var bullet_scene = preload("res://scenes/Bullet.tscn")

@onready var sprite: AnimatedSprite2D = find_animated_sprite()

var current_weapon: String = "Normal"
var last_direction: String = "Down"
var is_attacking: bool = false

func _ready() -> void:
	if sprite == null:
		push_error("[ERROR] No AnimatedSprite2D node found under the Player.")
	else:
		sprite.animation_finished.connect(_on_animation_finished)
	if has_node("SpearArea/SpearCollision"):
		$SpearArea/SpearCollision.disabled = true

func _physics_process(_delta: float) -> void:
	if is_attacking:
		return
	update_weapon_type()
	if Input.is_action_just_pressed("Attack") and current_weapon != "Normal":
		on_attack_event()
	else:
		on_move_event()

func update_weapon_type() -> void:
	if Input.is_action_just_pressed("Normal"):
		current_weapon = "Normal"
	elif Input.is_action_just_pressed("Spear"):
		current_weapon = "Spear"
	elif Input.is_action_just_pressed("Gun"):
		current_weapon = "Gun"

func shoot_bullets() -> void:
	if bullet_scene == null:
		return
	var bullet_count = 5
	var delay_between_shots = (1.0 / 3.0) / bullet_count 
	var total_spread = deg_to_rad(20.0)
	var base_dir = get_vector_from_string(last_direction)
	if base_dir == Vector2.ZERO:
		base_dir = Vector2.DOWN
	for i in range(bullet_count):
		var bullet = bullet_scene.instantiate()
		bullet.max_range = randf_range(200.0, 250.0)
		var random_offset = randf_range(-total_spread / 2, total_spread / 2)
		var bullet_dir = base_dir.rotated(random_offset)
		bullet.direction = bullet_dir
		bullet.global_position = global_position
		get_tree().current_scene.add_child(bullet)
		await get_tree().create_timer(delay_between_shots).timeout

func get_vector_from_string(dir_str: String) -> Vector2:
	match dir_str:
		"Up":
			return Vector2.UP
		"Down":
			return Vector2.DOWN
		"Left":
			return Vector2.LEFT
		"Right":
			return Vector2.RIGHT
		"Left_Up":
			return Vector2(-1, -1).normalized()
		"Right_Up":
			return Vector2(1, -1).normalized()
		"Left_Down":
			return Vector2(-1, 1).normalized()
		"Right_Down":
			return Vector2(1, 1).normalized()
	return Vector2.DOWN

func get_direction_string(dir: Vector2) -> String:
	if dir.y < -0.3:
		if dir.x > 0.3:
			return "Right_Up"
		if dir.x < -0.3:
			return "Left_Up"
		return "Up"
	elif dir.y > 0.3:
		if dir.x > 0.3:
			return "Right_Down"
		if dir.x < -0.3:
			return "Left_Down"
		return "Down"
	return "Right" if dir.x > 0 else "Left"

func on_move_event() -> void:
	var input_vector = Input.get_vector("Left", "Right", "Up", "Down")
	var is_running = Input.is_action_pressed("Run")
	
	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized()
		var speed = run_speed if is_running else walk_speed
		velocity = input_vector * speed
		last_direction = get_direction_string(input_vector)
		
		var anim_dir = last_direction
		if anim_dir == "Right_Down":
			anim_dir = "Right"
		if anim_dir == "Left_Down":
			anim_dir = "Left"
		
		var state = "Run" if is_running else "Walk"
		play_animation(state + "_" + current_weapon + "_" + anim_dir)
	else:
		velocity = Vector2.ZERO
		var anim_dir = last_direction
		if anim_dir == "Right_Down":
			anim_dir = "Right"
		if anim_dir == "Left_Down":
			anim_dir = "Left"
		play_animation("Idle_" + current_weapon + "_" + anim_dir)
	move_and_slide()

func play_animation(anim_name: String) -> void:
	if sprite:
		sprite.play(anim_name)

func find_animated_sprite() -> AnimatedSprite2D:
	if has_node("AnimatedSprite2D"):
		return $AnimatedSprite2D as AnimatedSprite2D
	for child in get_children():
		if child is AnimatedSprite2D:
			return child
	return null

func toggle_spear_collision(direction: String, active: bool) -> void:
	var area_name = "SpearRotator/Spear_" + direction
	if has_node(area_name):
		var area = get_node(area_name)
		area.get_node("CollisionShape2D").set_deferred("disabled", !active)
		if active and not area.body_entered.is_connected(_on_spear_area_body_entered):
			area.body_entered.connect(_on_spear_area_body_entered)

func on_attack_event() -> void:
	var anim_name = "Attack_" + current_weapon + "_" + last_direction
	if sprite.sprite_frames.has_animation(anim_name):
		is_attacking = true
		velocity = Vector2.ZERO
		if current_weapon == "Spear":
			toggle_spear_collision(last_direction, true)
		play_animation(anim_name)
		if current_weapon == "Gun":
			shoot_bullets()

func _on_animation_finished() -> void:
	if is_attacking:
		is_attacking = false
		for area in $SpearRotator.get_children():
			area.get_node("CollisionShape2D").set_deferred("disabled", true)
			
		play_animation("Idle_" + current_weapon + "_" + last_direction)

func _on_spear_area_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(global_position, 100.0)
