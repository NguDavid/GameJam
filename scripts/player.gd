extends CharacterBody2D

@export var walk_speed: float = 100.0
@export var run_speed: float = 200.0

@onready var sprite: AnimatedSprite2D = find_animated_sprite()

var current_weapon: String = "Normal"
var last_direction: String = "Down"
var is_attacking: bool = false

func _ready() -> void:
	if sprite == null:
		push_error("ERREUR : Aucun nœud AnimatedSprite2D trouvé sous le Player !")
	else:
		# On connecte le signal pour savoir quand l'attaque se termine
		sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(_delta: float) -> void:
	if is_attacking:
		return # On bloque tout le reste si on est en train d'attaquer
	
	update_weapon_type()
	
	# On vérifie l'attaque avant le mouvement
	if Input.is_action_just_pressed("Attack") and current_weapon != "Normal":
		start_attack()
	else:
		on_move_event()

func update_weapon_type() -> void:
	if Input.is_action_just_pressed("Normal"):
		current_weapon = "Normal"
	elif Input.is_action_just_pressed("Spear"):
		current_weapon = "Spear"
	elif Input.is_action_just_pressed("Gun"):
		current_weapon = "Gun"

func start_attack() -> void:
	var anim_name = "Attack_" + current_weapon + "_" + last_direction
	if sprite.sprite_frames.has_animation(anim_name):
		is_attacking = true
		velocity = Vector2.ZERO # On stop le mouvement pendant l'attaque
		play_animation(anim_name)
	else:
		print("Animation d'attaque manquante : ", anim_name)

func _on_animation_finished() -> void:
	if is_attacking:
		is_attacking = false
		# On repasse en Idle pour éviter de rester bloqué sur la dernière frame d'attaque
		play_animation("Idle_" + current_weapon + "_" + last_direction)

func get_direction_string(dir: Vector2) -> String:
	# Note : On détecte maintenant les 8 directions pour l'attaque
	if dir.y < -0.3: # Haut
		if dir.x > 0.3: return "Right_Up"
		if dir.x < -0.3: return "Left_Up"
		return "Up"
	elif dir.y > 0.3: # Bas
		if dir.x > 0.3: return "Right_Down"
		if dir.x < -0.3: return "Left_Down"
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
		
		# On simplifie la direction pour la marche/idle (recyclage des diagonales bas)
		var anim_dir = last_direction
		if anim_dir == "Right_Down": anim_dir = "Right"
		if anim_dir == "Left_Down": anim_dir = "Left"
		
		var state = "Run" if is_running else "Walk"
		play_animation(state + "_" + current_weapon + "_" + anim_dir)
	else:
		velocity = Vector2.ZERO
		# Nettoyage des diagonales pour l'Idle
		var anim_dir = last_direction
		if anim_dir == "Right_Down": anim_dir = "Right"
		if anim_dir == "Left_Down": anim_dir = "Left"
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
