extends CanvasLayer

# Signal to notify the game about the players choice
signal revive_selected(revived: bool)

func _ready():
	hide()
	$ReviveHUD/PanelContainer/VBoxContainer/Revive.connect("pressed", Callable(self, "_on_ReviveButton_pressed"))
	$ReviveHUD/PanelContainer/VBoxContainer/Quit.connect("pressed", Callable(self, "_on_QuitButton_pressed"))

func show_hud():
	show()

func hide_hud():
	hide()

func _on_ReviveButton_pressed():
	emit_signal("revive_selected", true)

func _on_QuitButton_pressed():
	emit_signal("revive_selected", false)
