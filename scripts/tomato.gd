extends CharacterBody2D

@export var speed: float = 50.0
@export var dash_speed: float = 250.0
@export var stopping_distance: float = 100.0
@export var knockback_force: float = 300.0
@export var max_health: float = 1000.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var dash_timer: Timer = $Timer

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
	
	# Sécurité des connexions
	if not dash_timer.timeout.is_connected(_on_dash_cooldown_finished):
		dash_timer.timeout.connect(_on_dash_cooldown_finished)
	
	if not sprite.animation_finished.is_connected(_on_animation_finished):
		sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	if is_dead or player == null:
		return
	
	var direction_to_player = global_position.direction_to(player.global_position)
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 500 * delta)
	
	if is_dashing:
		velocity = dash_direction * dash_speed + knockback_velocity
	else:
		var distance = global_position.distance_to(player.global_position)
		if distance > stopping_distance:
			velocity = direction_to_player * speed + knockback_velocity
		else:
			velocity = knockback_velocity
			if dash_timer.is_stopped():
				start_dash(direction_to_player)
	
	# On met à jour l'animation juste avant de bouger
	update_animation(direction_to_player)
	move_and_slide()

func update_animation(dir: Vector2) -> void:
	# SI LE BOSS EST MORT, ON NE TOUCHE PLUS AUX ANIMATIONS
	if is_dead: 
		return 

	# GESTION DU FLIP (Le sens de la tomate)
	if dir.x > -0.1: # On va à gauche
		sprite.flip_h = true
	elif dir.x < 0.1: # On va à droite
		sprite.flip_h = false

	# GESTION DU NOM DE L'ANIMATION
	var anim_name = "Down"
	if abs(dir.x) > abs(dir.y):
		# On utilise TOUJOURS "Right". Si flip_h est vrai, elle regardera à gauche.
		anim_name = "Right" 
	else:
		anim_name = "Down" if dir.y > 0 else "Up"
	
	var final_anim = "Move_" + anim_name
	
	# On ne lance l'animation que si elle est différente de l'actuelle (optimisation)
	if sprite.animation != final_anim:
		if sprite.sprite_frames.has_animation(final_anim):
			sprite.play(final_anim)

func take_damage(source_position: Vector2, damage: float = 25.0):
	if is_dead: return    
	
	current_health -= damage
	var push_dir = source_position.direction_to(global_position)
	knockback_velocity = push_dir * knockback_force
	
	if current_health <= 0:
		die()

func die():
	if is_dead: return
	is_dead = true # Bloque _physics_process et update_animation
	
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	
	if sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
		print("Lancement de l'animation de mort")
	else:
		print("Animation Death introuvable, suppression immédiate")
		queue_free()

func _on_animation_finished() -> void:
	if sprite.animation == "death":
		queue_free()

func start_dash(dir: Vector2) -> void:
	if is_dead: return
	is_dashing = true
	dash_direction = dir
	await get_tree().create_timer(0.4).timeout
	is_dashing = false
	dash_timer.start(2.5)

func _on_dash_cooldown_finished() -> void:
	pass
