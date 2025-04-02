class_name MainMenu

extends Node2D

@onready var up_conveyer: UpConveyer = $InputConveyer/UpConveyer
@onready var up_conveyer_2: UpConveyer = $InputConveyer/UpConveyer2
@onready var up_conveyer_3: UpConveyer = $InputConveyer/UpConveyer3
@onready var up_conveyer_4: UpConveyer = $InputConveyer/UpConveyer4
@onready var up_conveyer_5: UpConveyer = $InputConveyer/UpConveyer5
@onready var down_conveyer: DownConveyer = $OutputConveyer/DownConveyer
@onready var down_conveyer_2: DownConveyer = $OutputConveyer/DownConveyer2
@onready var down_conveyer_3: DownConveyer = $OutputConveyer/DownConveyer3
@onready var down_conveyer_4: DownConveyer = $OutputConveyer/DownConveyer4
@onready var down_conveyer_5: DownConveyer = $OutputConveyer/DownConveyer5

@onready var title: Label = $Title
@onready var default_levels_button: Button = $DefaultLevelsButton
@onready var custom_levels_button: Button = $CustomLevelsButton
@onready var exit_button: Button = $ExitButton
@onready var language_button: Button = $LanguageButton
@onready var warning_window: Control = $WarningWindow
@onready var level_selection_window: LevelSelectionWindow = $LevelSelectionWindow
@onready var language_selection_window: LanguageSelectionWindow = $LanguageSelectionWindow

func _ready() -> void:
	up_conveyer.animated_sprite_2d.play("scroll")
	up_conveyer_2.animated_sprite_2d.play("scroll")
	up_conveyer_3.animated_sprite_2d.play("scroll")
	up_conveyer_4.animated_sprite_2d.play("scroll")
	up_conveyer_5.animated_sprite_2d.play("scroll")
	down_conveyer.animated_sprite_2d.play("scroll")
	down_conveyer_2.animated_sprite_2d.play("scroll")
	down_conveyer_3.animated_sprite_2d.play("scroll")
	down_conveyer_4.animated_sprite_2d.play("scroll")
	down_conveyer_5.animated_sprite_2d.play("scroll")
	exit_button.pressed.connect(exit)

func exit() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()
