extends CharacterBody2D

@export var speed: float = 50.0
@export var dash_speed: float = 200.0
@export var stopping_distance: float = 50.0
@export var knockback_force: float = 300.0
@export var max_health: float = 100.0
@export var damage: float = 20.0

@onready var sprite: AnimatedSprite2D = $Animation
@onready var dash_timer: Timer = $ShootTimer

var current_health: float
var is_dead: bool = false
var player: Node2D = null
var knockback_velocity: Vector2 = Vector2.ZERO
var is_dashing: bool = false
var dash_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	current_health = max_health
	player = get_tree().get_first_node_in_group("Player")
	dash_timer.one_shot = true 
	dash_timer.timeout.connect(_on_dash_cooldown_finished)
	sprite.animation_finished.connect(_on_animation_finished)
	if has_node("Hitbox"):
		$Hitbox.body_entered.connect(_on_hitbox_body_entered)

func _on_hitbox_body_entered(body: Node) -> void:
	if is_dead:
		return
	if is_dashing and body.is_in_group("Player"):
		if body.has_method("take_damage"):
			body.take_damage(global_position, damage)
			is_dashing = false
			dash_timer.start(2.5)

func _physics_process(delta: float) -> void:
	if player == null or is_dead:
		return
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 500 * delta)
	if is_dashing:
		velocity = dash_direction * dash_speed + knockback_velocity
	else:
		var direction_to_player = global_position.direction_to(player.global_position)
		var distance = global_position.distance_to(player.global_position)
		if distance > stopping_distance:
			velocity = direction_to_player * speed + knockback_velocity
			update_animation(direction_to_player)
		else:
			velocity = knockback_velocity
			if dash_timer.is_stopped():
				start_dash(direction_to_player)
	move_and_slide()

func take_damage(source_position: Vector2, damage: float = 25.0):
	if is_dead:
		return	
	current_health -= damage
	var push_dir = source_position.direction_to(global_position)
	knockback_velocity = push_dir * knockback_force
	is_dashing = false
	if current_health <= 0:
		die()

func die():
	is_dead = true
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	if sprite.sprite_frames.has_animation("Death"):
		sprite.play("Death")
	else:
		queue_free()

func _on_animation_finished() -> void:
	if sprite.animation == "Death":
		queue_free()

func start_dash(dir: Vector2) -> void:
	is_dashing = true
	dash_direction = dir
	update_animation(dir)
	await get_tree().create_timer(0.4).timeout
	is_dashing = false
	dash_timer.start(2.5)

func _on_dash_cooldown_finished() -> void:
	pass 

func update_animation(dir: Vector2) -> void:
	var anim_dir = "Down"
	if abs(dir.x) > abs(dir.y):
		anim_dir = "Right" if dir.x > 0 else "Left"
	else:
		anim_dir = "Down" if dir.y > 0 else "Up"	
	sprite.play("Move_" + anim_dir)
