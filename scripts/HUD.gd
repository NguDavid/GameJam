extends CanvasLayer

@onready var timer_label = $TimerLabel
@onready var win_label = $WinLabel

var time_left = 300.0 # 5 minutes in seconds

func _process(delta):
	if time_left > 0:
		time_left -= delta
		if time_left <= 0:
			time_left = 0
			win_label.visible = true
	
	update_timer_display()

func update_timer_display():
	var minutes = floor(time_left / 60)
	var seconds = int(time_left) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]
