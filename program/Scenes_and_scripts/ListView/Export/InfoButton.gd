extends Button

func _ready():
	connect("pressed", self, "on_pressed")

func on_pressed():
	if not $AcceptDialog.is_visible():
		$AcceptDialog.popup_centered()
