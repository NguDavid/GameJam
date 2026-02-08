extends Node2D

@export var boss_scene: PackedScene
@onready var boss_timer: Timer = $Timer

func _ready() -> void:
	print("--- Spawner initialisé ---")
	if boss_scene == null:
		print("ERREUR : La boss_scene n'est pas assignée dans l'inspecteur !")
	
	if boss_timer == null:
		print("ERREUR : Le nœud Timer est introuvable ! Vérifie le nom.")
		return

	boss_timer.wait_time = 60.0
	boss_timer.one_shot = false
	
	if not boss_timer.timeout.is_connected(_on_boss_timer_timeout):
		boss_timer.timeout.connect(_on_boss_timer_timeout)
	
	boss_timer.start()
	print("Timer lancé pour 10 secondes...")

func _on_boss_timer_timeout() -> void:
	print("Le Timer a fini de compter !")
	var current_bosses = get_tree().get_nodes_in_group("Boss")
	print("Nombre de boss actuellement en jeu : ", current_bosses.size())
	
	if current_bosses.size() == 0:
		spawn_boss()
	else:
		print("Spawn annulé : Un boss est déjà présent.")

func spawn_boss() -> void:
	print("Tentative de spawn...")
	if boss_scene:
		var boss = boss_scene.instantiate()
		# On s'assure que le boss est bien mis dans le groupe via le code au cas où
		boss.add_to_group("Boss") 
		
		boss.global_position = global_position
		get_tree().current_scene.add_child(boss)
		print("SUCCÈS : Boss ajouté à la scène à la position : ", global_position)
	else:
		print("ÉCHEC : Impossible d'instancier, boss_scene est nulle.")
