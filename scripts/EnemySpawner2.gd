extends Node2D

@export var enemy_scene: PackedScene 
@export var spawn_radius: float = 500.0
@export var max_enemies: int = 25

@onready var timer: Timer = $SpawnTimer

func _ready() -> void:
	if not timer.timeout.is_connected(_on_spawn_timer_timeout):
		timer.timeout.connect(_on_spawn_timer_timeout)

func _on_spawn_timer_timeout() -> void:
	var current_enemy_count = get_tree().get_nodes_in_group("Enemies").size()
	if current_enemy_count < max_enemies:
		spawn_enemy()

func spawn_enemy() -> void:
	if enemy_scene == null:
		return
	var spawn_pos = global_position
	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_pos
	get_tree().current_scene.add_child(enemy)
