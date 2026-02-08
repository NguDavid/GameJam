extends CharacterBody2D

@export var speed: float = 50.0
@export var dash_speed: float = 250.0
@export var stopping_distance: float = 100.0
@export var knockback_force: float = 300.0
@export var max_health: float = 1000.0
@export var damage: float = 15.0

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
			velocity = knockback_velocity # On ne garde que le recul si on est à l'arrêt
			if dash_timer.is_stopped():
				start_dash(direction_to_player)
	
	# On met à jour l'animation juste avant de bouger
	update_animation(direction_to_player)
	move_and_slide()

func update_animation(dir: Vector2) -> void:
	if is_dead: 
		return 

	# --- 1. GESTION DU FLIP (CORRECTION) ---
	# On change le sens seulement si le mouvement est significatif sur l'axe X
	if dir.x > -0.1: 
		sprite.flip_h = true  # Regarde à gauche
	elif dir.x < 0.1: 
		sprite.flip_h = false # Regarde à droite

	# --- 2. CHOIX DE L'ANIMATION (IDLE vs MOVE) ---
	var final_anim = ""
	
	# On considère que le boss est "Idle" si sa vitesse est très faible et qu'il ne dash pas
	if velocity.length() < 10.0 and not is_dashing:
		final_anim = "idle"
	else:
		# Logique de mouvement (Up, Down, Right)
		var anim_name = "Down"
		if abs(dir.x) > abs(dir.y):
			anim_name = "Right" 
		else:
			anim_name = "Down" if dir.y > 0 else "Up"
		final_anim = "Move_" + anim_name
	
	# --- 3. JOUER L'ANIMATION ---
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
	is_dead = true
	
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	
	# On s'assure que rien d'autre ne joue
	sprite.stop()
	
	if sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
		print("Lancement de l'animation de mort")
	else:
		print("Animation 'death' introuvable")
		queue_free()

func _on_animation_finished() -> void:
	if sprite.animation == "death":
		queue_free()

func start_dash(dir: Vector2) -> void:
	if is_dead: return
	is_dashing = true
	dash_direction = dir
	# Optionnel : jouer une animation de dash spécifique ici si tu en as une
	await get_tree().create_timer(0.4).timeout
	is_dashing = false
	dash_timer.start(2.5)

func _on_dash_cooldown_finished() -> void:
	pass
	
func _on_hitbox_body_entered(body: Node2D) -> void:
	if is_dead: return
	
	if body.is_in_group("Player"):
		if body.has_method("take_damage"):
			var final_damage = damage
			if is_dashing:
				final_damage *= 2.0
			
			# --- LA CORRECTION EST ICI ---
			# On envoie d'abord la position (global_position), puis les dégâts
			body.take_damage(global_position, final_damage)
			
			print("Le boss a infligé ", final_damage, " points de dégâts !")
