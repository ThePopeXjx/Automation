class_name InstructionPanel

extends Control

@onready var level_description_label: Label = $Panel/VBoxContainer/PanelContainer2/ScrollContainer/LevelDescriptionLabel
@onready var instruction_label: Label = $Panel/VBoxContainer/PanelContainer4/ScrollContainer/InstructionLabel
@onready var instruction_edit: TextEdit = $Panel/VBoxContainer/PanelContainer5/InstructionEdit
@onready var confirm_button: Button = $Panel/VBoxContainer/HBoxContainer/ConfirmButton
@onready var restart_button: Button = $Panel/VBoxContainer/HBoxContainer/RestartButton
@onready var execute_one_button: Button = $Panel/VBoxContainer/PanelContainer7/ExecuteOneButton
@onready var execute_all_button: Button = $Panel/VBoxContainer/PanelContainer8/ExecuteAllButton
