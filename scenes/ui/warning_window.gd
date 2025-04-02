extends Control

@onready var button: Button = $Panel/VBoxContainer/PanelContainer3/Button

func _on_button_pressed() -> void:
	visible = false
