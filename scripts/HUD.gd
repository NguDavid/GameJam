extends CanvasLayer

@onready var timer_label = $TimerLabel
@onready var win_label = $WinLabel
@onready var game_over_label = $GameOverLabel

var time_left = 300.0 # 5 minutes in seconds

func _ready():
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.player_died.connect(show_game_over)

func _process(delta):
	if time_left > 0:
		time_left -= delta
		if time_left <= 0:
			time_left = 0
			win_label.visible = true
	
	update_timer_display()

func show_game_over():
	game_over_label.visible = true
	# Optional: Pause the game or stop the timer?
	# For now just showing the label as requested.

func update_timer_display():
	var minutes = floor(time_left / 60)
	var seconds = int(time_left) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]
