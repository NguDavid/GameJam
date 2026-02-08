extends CharacterBody2D

@export var walk_speed: float = 100.0
@export var run_speed: float = 200.0
@export var max_health: float = 100.0

signal player_died
signal health_changed(current_health, max_health)

var current_health: float
var is_dead: bool = false
var bullet_scene = preload("res://scenes/Bullet.tscn")

@onready var sprite: AnimatedSprite2D = find_animated_sprite()

var current_weapon: String = "Normal"
var last_direction: String = "Down"
var is_attacking: bool = false

func _ready() -> void:
	current_health = max_health
	emit_signal("health_changed", current_health, max_health)
	add_to_group("Player")
	if sprite:
		sprite.animation_finished.connect(_on_animation_finished)
	if has_node("SpearRotator"):
		for area in $SpearRotator.get_children():
			if area is Area2D:
				area.get_node("CollisionShape2D").disabled = true
				if not area.body_entered.is_connected(_on_spear_area_body_entered):
					area.body_entered.connect(_on_spear_area_body_entered)

func _physics_process(_delta: float) -> void:
	if is_dead or is_attacking:
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

func take_damage(source_position: Vector2, damage: float = 25.0):
	if is_dead:
		return
	current_health -= damage
	emit_signal("health_changed", current_health, max_health)
	var push_dir = source_position.direction_to(global_position)
	velocity = push_dir * 400.0
	move_and_slide()
	if current_health <= 0:
		die()

func die():
	is_dead = true
	emit_signal("player_died")
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	var anim_dir = last_direction
	if anim_dir.contains("Left"):
		anim_dir = "Left"
	elif anim_dir.contains("Right"):
		anim_dir = "Right"
	var anim_name = "Death_" + current_weapon + "_" + anim_dir
	if sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
	else:
		sprite.play("Death_Normal_Down")

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

func shoot_bullets() -> void:
	if bullet_scene == null:
		return
	var bullet_count = 20
	var delay_between_shots = (1.0 / 3.0) / bullet_count 
	var total_spread = deg_to_rad(20.0)
	var base_dir = get_vector_from_string(last_direction)
	var spawn_pos = global_position + (base_dir * 15.0)

	for i in range(bullet_count):
		var bullet = bullet_scene.instantiate()
		bullet.max_range = randf_range(200.0, 250.0)
		var random_offset = randf_range(-total_spread / 2, total_spread / 2)
		bullet.direction = base_dir.rotated(random_offset)
		bullet.global_position = spawn_pos
		get_tree().current_scene.add_child(bullet)
		await get_tree().create_timer(delay_between_shots).timeout

func on_move_event() -> void:
	var input_vector = Input.get_vector("Left", "Right", "Up", "Down")
	var is_running = Input.is_action_pressed("Run")
	
	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized()
		var speed = run_speed if is_running else walk_speed
		velocity = input_vector * speed
		last_direction = get_direction_string(input_vector)
		var state = "Run" if is_running else "Walk"
		var anim_dir = last_direction
		if anim_dir.contains("Left"): anim_dir = "Left"
		elif anim_dir.contains("Right"): anim_dir = "Right"
		
		play_animation(state + "_" + current_weapon + "_" + anim_dir)
	else:
		velocity = Vector2.ZERO
		var anim_dir = last_direction
		if anim_dir.contains("Left"): anim_dir = "Left"
		elif anim_dir.contains("Right"): anim_dir = "Right"
		play_animation("Idle_" + current_weapon + "_" + anim_dir)
	
	move_and_slide()

func get_vector_from_string(dir_str: String) -> Vector2:
	match dir_str:
		"Up": return Vector2.UP
		"Down": return Vector2.DOWN
		"Left": return Vector2.LEFT
		"Right": return Vector2.RIGHT
		"Left_Up": return Vector2(-1, -1).normalized()
		"Right_Up": return Vector2(1, -1).normalized()
		"Left_Down": return Vector2(-1, 1).normalized()
		"Right_Down": return Vector2(1, 1).normalized()
	return Vector2.DOWN

func get_direction_string(dir: Vector2) -> String:
	if dir.y < -0.3:
		if dir.x > 0.3: return "Right_Up"
		if dir.x < -0.3: return "Left_Up"
		return "Up"
	elif dir.y > 0.3:
		if dir.x > 0.3: return "Right_Down"
		if dir.x < -0.3: return "Left_Down"
		return "Down"
	return "Right" if dir.x > 0 else "Left"

func toggle_spear_collision(direction: String, active: bool) -> void:
	var area_path = "SpearRotator/Spear_" + direction
	
	if has_node(area_path):
		var area = get_node(area_path)
		var shape = area.get_node("CollisionShape2D")
		shape.set_deferred("disabled", !active)
		if active and not area.body_entered.is_connected(_on_spear_area_body_entered):
			area.body_entered.connect(_on_spear_area_body_entered)

func _on_animation_finished() -> void:
	if is_dead:
		return
	if is_attacking:
		is_attacking = false
		if has_node("SpearRotator"):
			for area in $SpearRotator.get_children():
				area.get_node("CollisionShape2D").set_deferred("disabled", true)
		play_animation("Idle_" + current_weapon + "_" + last_direction)

func _on_spear_area_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(global_position, 100.0)

func play_animation(anim_name: String) -> void:
	if sprite:
		sprite.play(anim_name)

func find_animated_sprite() -> AnimatedSprite2D:
	if has_node("AnimatedSprite2D"): return $AnimatedSprite2D
	for child in get_children():
		if child is AnimatedSprite2D: return child
	return null
