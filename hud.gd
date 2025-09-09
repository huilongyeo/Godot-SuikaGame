extends CanvasLayer

var score := 0

signal start_game

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Score.hide()
	$Message.show()
	$StartButton.show()
	$StartButton.connect("pressed", Callable(self, "_on_start_button_pressed"))

func show_message(text):
	$Message.text = text
	$Message.show()

func update_score(amount):
	score += amount
	$Score.text = str(score)

func reset_score():
	score = 0
	$Score.text = str(score)

func _on_start_button_pressed():
	start_game.emit()
	$StartButton.hide()
	$Message.hide()
	$Score.show()
	reset_score()

func game_over():
	$Message.text = "Game Over!"
	$Message.show()
	$StartButton.text = "Restart"
	$StartButton.show()