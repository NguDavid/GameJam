extends Area2D

@export var speed: float = 300.0
@export var max_range: float = 400.0 

@onready var sprite: AnimatedSprite2D = $Animation

var direction: Vector2 = Vector2.ZERO
var distance_traveled: float = 0.0
var is_exploding: bool = false

func _ready() -> void:
	if sprite:
		sprite.play("Bullet")
		sprite.animation_finished.connect(_on_animation_finished)
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	if is_exploding:
		return
	var distance_this_frame = speed * delta
	position += direction * distance_this_frame
	distance_traveled += distance_this_frame
	if distance_traveled >= max_range:
		explode()

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(global_position, 30.0)
	explode()

func explode() -> void:
	if is_exploding:
		return
	is_exploding = true
	if sprite:
		var random_number = randi_range(1, 5)
		var anim_name = "Explosion_" + str(random_number)
		if sprite.sprite_frames.has_animation(anim_name):
			sprite.scale = Vector2(0.25, 0.25)
			sprite.play(anim_name)
			monitoring = false
		else:
			if sprite.sprite_frames.has_animation("Explosion"):
				sprite.play("Explosion")
			else:
				queue_free()
	else:
		queue_free()

func _on_animation_finished() -> void:
	if sprite.animation.begins_with("Explosion"):
		queue_free()
