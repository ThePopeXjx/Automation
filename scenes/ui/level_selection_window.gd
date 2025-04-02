class_name LevelSelectionWindow

extends Control

@onready var item_list: ItemList = $Panel/VBoxContainer/ItemList
@onready var enter_button: Button = $Panel/VBoxContainer/PanelContainer2/EnterButton
@onready var cancel_button: Button = $Panel/VBoxContainer/PanelContainer2/CancelButton

func _on_cancel_button_pressed() -> void:
	visible = false
