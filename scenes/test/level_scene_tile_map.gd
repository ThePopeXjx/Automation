class_name LevelSceneTileMap

extends Node2D

var is_default: bool

var levels: Array[Level]
var current_level_idx: int

var level_description: String
var input: Array
var instructions_allowed: Array
var expected_output: Array
var available_registers: Array

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
@onready var timer: Timer = $Timer
@onready var game_screen: GameScreen = $GameScreen
@onready var error_message: ErrorMessage = $ErrorMessage
@onready var r_0: Node2D = $GameTileMap/R0
@onready var r_1: Node2D = $GameTileMap/R1
@onready var r_2: Node2D = $GameTileMap/R2
@onready var robot: Robot = $Robot
@onready var r_0_box: Box = $GameTileMap/R0/Box
@onready var r_1_box: Box = $GameTileMap/R1/Box
@onready var r_2_box: Box = $GameTileMap/R2/Box
@onready var robot_carrying_box: Box = $RobotCarryingBox
@onready var game_over_window: GameOverWindow = $GameOverWindow
@onready var color_rect: ColorRect = $ColorRect
@onready var input_box_seq: Node2D = $InputBoxSeq
@onready var output_box_seq: Node2D = $OutputBoxSeq
@onready var level_count_label: Label = $LevelCount/LevelCountLabel

signal levels_completed

static var single_instructions: Array[String] = ["inbox", "outbox"]
static var double_instructions: Array[String] = ["add", "sub", "copyto", "copyfrom", "jump", "jumpifzero"]
static var valid_registers: Array[int] = [0, 1, 2]

var registers: Array[Box]
const register_positions: Array[Vector2] = [Vector2(337, 211), Vector2(188, 211), Vector2(482, 211)]
const register_time: Dictionary = { Vector2(0, 1): 2, Vector2(1, 0): 2, Vector2(0, 2): 2,
										Vector2(2, 0): 2, Vector2(1, 2): 4, Vector2(2, 1): 4 }
const register_flip_h: Dictionary = { Vector2(0, 1): true, Vector2(1, 0): false, Vector2(0, 2): false,
									Vector2(2, 0): true, Vector2(1, 2): false, Vector2(2, 1): true }

var instruction_edit: TextEdit
var confirm_button: Button
var restart_button: Button
var execute_one_button: Button
var execute_all_button: Button
var current_instruction_label: Label
var level_description_label: Label
var instruction_label: Label

var input_boxes: Array[Box]
var output_boxes: Array[Box]
var output_sequence: Array[int]
var input_instructions: Array[String]
var current_instruction_idx: int
var is_carrying_box: Dictionary
var execute_all_mode: bool

func _ready() -> void:
	instruction_edit = game_screen.instruction_panel.instruction_edit
	confirm_button = game_screen.instruction_panel.confirm_button
	restart_button = game_screen.instruction_panel.restart_button
	execute_one_button = game_screen.instruction_panel.execute_one_button
	execute_all_button = game_screen.instruction_panel.execute_all_button
	current_instruction_label = game_screen.current_instruction_panel.current_instruction_label
	level_description_label = game_screen.instruction_panel.level_description_label
	instruction_label = game_screen.instruction_panel.instruction_label

	confirm_button.pressed.connect(on_confirm_button_pressed)
	execute_one_button.pressed.connect(execute_one_step)
	execute_all_button.pressed.connect(execute_all)
	restart_button.pressed.connect(restart)
	
	registers = [r_0_box, r_1_box, r_2_box]

func restart() -> void:
	execute_all_mode = false
	
	color_rect.visible = false
	game_over_window.visible = false
	
	level_count_label.text = tr("Level {0}").format([current_level_idx + 1])
	level_description = levels[current_level_idx].description
	input = levels[current_level_idx].input
	instructions_allowed = levels[current_level_idx].instructions_allowed
	expected_output = levels[current_level_idx].expected_output
	available_registers = levels[current_level_idx].available_registers
	
	output_sequence.clear()
	input_instructions.clear()
	is_carrying_box = { "robot": false, 0: false, 1: false, 2: false }
	current_instruction_label.text = ""
	level_description_label.text = level_description
	var ins_allowed: String = ""
	for ins in instructions_allowed:
		ins_allowed += ins
		ins_allowed += "\n"
	instruction_label.text = ins_allowed
	instruction_edit.text = ""
	instruction_edit.editable = true
	
	for box: Box in input_boxes:
		box.queue_free()
	input_boxes.clear()
	for box: Box in output_boxes:
		box.queue_free()
	output_boxes.clear()
	
	execute_one_button.disabled = true
	execute_all_button.disabled = true
	restart_button.disabled = true

	if 0 in available_registers:
		r_0.visible = true
	else:
		r_0.visible = false
	if 1 in available_registers:
		r_1.visible = true
	else:
		r_1.visible = false
	if 2 in available_registers:
		r_2.visible = true
	else:
		r_2.visible = false
	r_0_box.visible = false
	r_1_box.visible = false
	r_2_box.visible = false
	robot_carrying_box.visible = false
	
	robot.global_position = register_positions[0]
	robot.animated_sprite_2d.flip_h = false
	
	var box_scene = load("res://scenes/objects/box.tscn")
	var init_x = 126
	var init_y = 517
	var tween = create_tween()
	tween.set_parallel(true)
	for i in input:
		var box_instance = box_scene.instantiate() as Box
		box_instance.get_child(0).text = str(i)
		box_instance.global_position = Vector2(init_x, init_y)
		input_box_seq.add_child(box_instance)
		input_boxes.append(box_instance)
		tween.tween_property(box_instance, "global_position", Vector2(init_x, init_y - 300), 3)
		init_y += 50
	up_conveyer.animated_sprite_2d.play("scroll")
	up_conveyer_2.animated_sprite_2d.play("scroll")
	up_conveyer_3.animated_sprite_2d.play("scroll")
	up_conveyer_4.animated_sprite_2d.play("scroll")
	up_conveyer_5.animated_sprite_2d.play("scroll")
	confirm_button.disabled = true
	timer.wait_time = 3
	timer.timeout.connect(stop_up_conveyers.bind("_ready", true))
	timer.start()

func _process(delta: float) -> void:
	if !robot.animated_sprite_2d.flip_h:
		robot_carrying_box.global_position = robot.global_position - Vector2(19, -2)
	else:
		robot_carrying_box.global_position = robot.global_position - Vector2(-19, -2)
	
func stop_up_conveyers(caller: String, has_connected: bool) -> void:
	if has_connected:
		timer.timeout.disconnect(stop_up_conveyers)
	up_conveyer.animated_sprite_2d.play("default")
	up_conveyer_2.animated_sprite_2d.play("default")
	up_conveyer_3.animated_sprite_2d.play("default")
	up_conveyer_4.animated_sprite_2d.play("default")
	up_conveyer_5.animated_sprite_2d.play("default")
	if caller == "_ready":
		confirm_button.disabled = false
		restart_button.disabled = false
	elif caller == "collect_inbox":
		execute_one_button.disabled = false
		execute_all_button.disabled = false
		restart_button.disabled = false
		check_is_gameover()

func stop_down_conveyers(has_connected: bool) -> void:
	if has_connected:
		timer.timeout.disconnect(stop_down_conveyers)
	down_conveyer.animated_sprite_2d.play("default")
	down_conveyer_2.animated_sprite_2d.play("default")
	down_conveyer_3.animated_sprite_2d.play("default")
	down_conveyer_4.animated_sprite_2d.play("default")
	down_conveyer_5.animated_sprite_2d.play("default")
	execute_one_button.disabled = false
	execute_all_button.disabled = false
	restart_button.disabled = false
	robot_carrying_box.visible = false
	is_carrying_box["robot"] = false
	var box_scene = load("res://scenes/objects/box.tscn")
	var box_instance = box_scene.instantiate() as Box
	box_instance.get_child(0).text = robot_carrying_box.label.text
	box_instance.global_position = Vector2(543, 217)
	output_box_seq.add_child(box_instance)
	output_boxes.append(box_instance)
	output_sequence.append(int(robot_carrying_box.label.text))
	check_is_gameover()

func on_confirm_button_pressed() -> void:
	var possible_instructions: Array[String]
	var instructions: String = instruction_edit.text
	if len(instructions) == 0:
		return
	var lines: PackedStringArray = instructions.split("\n")
	if lines[lines.size() - 1] == "":
		lines.remove_at(lines.size() - 1)
	var cnt: int = 1
	for line in lines:
		var words: PackedStringArray = line.split(" ")
		if len(words) == 1:
			if words[0] in single_instructions and words[0] in instructions_allowed:
				possible_instructions.append(line)
			else:
				print_error_message(cnt, "compile")
				return
		elif len(words) == 2:
			if words[0] in double_instructions and words[0] in instructions_allowed and words[1].is_valid_int():
				if words[0] == "jump" or words[0] == "jumpifzero":
					if int(words[1]) <= len(lines) and int(words[1]) > 0:
						possible_instructions.append(line)
					else:
						print_error_message(cnt, "compile")
						return
				elif int(words[1]) in available_registers:
					possible_instructions.append(line)
				else:
					print_error_message(cnt, "compile")
					return
			else:
				print_error_message(cnt, "compile")
				return
		else:
			print_error_message(cnt, "compile")
			return
		cnt += 1
	input_instructions = possible_instructions
	confirm_button.disabled = true
	execute_one_button.disabled = false
	execute_all_button.disabled = false
	restart_button.disabled = false
	instruction_edit.editable = false
	current_instruction_idx = 0
	current_instruction_label.text = tr("line {0}: {1}").format([current_instruction_idx + 1, input_instructions[current_instruction_idx]])
	return

func print_error_message(index: int, type: String) -> void:
	error_message.label.text = tr(" Error on instruction {0}").format([index])
	if type == "compile":
		confirm_button.disabled = true
		restart_button.disabled = true
	elif type == "runtime":
		execute_one_button.disabled = true
		execute_all_button.disabled = true
		restart_button.disabled = true
	var x: int = error_message.global_position.x
	var y: int = error_message.global_position.y
	var tween = create_tween()
	tween.tween_property(error_message, "global_position", Vector2(x, y - 70), 1)
	timer.wait_time = 2
	timer.timeout.connect(remove_error_message.bind(type))
	timer.start()

func remove_error_message(type: String) -> void:
	var x: int = error_message.global_position.x
	var y: int = error_message.global_position.y
	var tween = create_tween()
	tween.tween_property(error_message, "global_position", Vector2(x, y + 70), 1)
	if type == "compile":
		confirm_button.disabled = false
		restart_button.disabled = false
	elif type == "runtime":
		restart_button.disabled = false
	timer.timeout.disconnect(remove_error_message)

func execute_one_step() -> void:
	var instruction: String = input_instructions[current_instruction_idx]
	var words: PackedStringArray = instruction.split(" ")
	execute_one_button.disabled = true
	execute_all_button.disabled = true
	restart_button.disabled = true
	if len(words) == 1:
		if words[0] == "inbox":
			execute_inbox()
		elif words[0] == "outbox":
			execute_outbox()
	else:
		var register: int = int(words[1])
		if words[0] == "add" or words[0] == "sub":
			if is_carrying_box["robot"] and is_carrying_box[register]:
				execute_register_operations(register, words[0])
			else:
				print_error_message(current_instruction_idx, "runtime")
		elif words[0] == "copyto":
			if is_carrying_box["robot"]:
				execute_register_operations(register, words[0])
			else:
				print_error_message(current_instruction_idx, "runtime")
		elif words[0] == "copyfrom":
			if is_carrying_box[register]:
				execute_register_operations(register, words[0])
			else:
				print_error_message(current_instruction_idx, "runtime")
		elif words[0] == "jump":
			current_instruction_idx = int(words[1]) - 1
			current_instruction_label.text = "line {0}: {1}".format([current_instruction_idx + 1, input_instructions[current_instruction_idx]])
			if execute_all_mode:
				execute_one_button.disabled = true
				execute_all_button.disabled = true
				restart_button.disabled = true
				timer.wait_time = 0.5
				timer.timeout.connect(execute_one_step_with_timeout)
				timer.start()
		elif words[0] == "jumpifzero":
			if is_carrying_box["robot"]:
				if robot_carrying_box.label.text == "0":
					current_instruction_idx = int(words[1]) - 1
					current_instruction_label.text = "line {0}: {1}".format([current_instruction_idx + 1, input_instructions[current_instruction_idx]])
					if execute_all_mode:
						execute_one_button.disabled = true
						execute_all_button.disabled = true
						restart_button.disabled = true
						timer.wait_time = 0.5
						timer.timeout.connect(execute_one_step_with_timeout)
						timer.start()
				else:
					check_is_gameover()
			else:
				print_error_message(current_instruction_idx, "runtime")

func execute_all() -> void:
	execute_all_mode = true
	execute_one_step()

func execute_one_step_with_timeout() -> void:
	timer.timeout.disconnect(execute_one_step_with_timeout)
	execute_one_step()

func execute_inbox() -> void:
	if input_boxes.is_empty():
		show_gameover_window()
	else:
		robot.animated_sprite_2d.flip_h = true
		if robot.global_position == register_positions[0]:
			robot.animated_sprite_2d.play("walk")
			var tween = create_tween()
			tween.tween_property(robot, "global_position", register_positions[1], 2)
			timer.wait_time = 2
			timer.timeout.connect(collect_inbox.bind(true))
			timer.start()
		elif robot.global_position == register_positions[2]:
			robot.animated_sprite_2d.play("walk")
			var tween = create_tween()
			tween.tween_property(robot, "global_position", register_positions[1], 4)
			timer.wait_time = 4
			timer.timeout.connect(collect_inbox.bind(true))
			timer.start()
		else:
			collect_inbox(false)
		
func collect_inbox(has_connected: bool) -> void:
	if has_connected:
		timer.timeout.disconnect(collect_inbox)
	robot.animated_sprite_2d.play("idle")
	var first_box: Box = input_boxes[0]
	var number = first_box.label.text
	first_box.queue_free()
	input_boxes.pop_front()
	robot_carrying_box.label.text = number
	robot_carrying_box.visible = true
	is_carrying_box["robot"] = true
	if !input_boxes.is_empty():
		var tween = create_tween()
		tween.set_parallel(true)
		for box: Box in input_boxes:
			var init_x: int = box.global_position.x
			var init_y: int = box.global_position.y
			tween.tween_property(box, "global_position", Vector2(init_x, init_y - 50), 0.5)
		up_conveyer.animated_sprite_2d.play("scroll")
		up_conveyer_2.animated_sprite_2d.play("scroll")
		up_conveyer_3.animated_sprite_2d.play("scroll")
		up_conveyer_4.animated_sprite_2d.play("scroll")
		up_conveyer_5.animated_sprite_2d.play("scroll")
		timer.wait_time = 0.5
		timer.timeout.connect(stop_up_conveyers.bind("collect_inbox", true))
		timer.start()
	else:
		stop_up_conveyers("collect_inbox", false)

func execute_outbox() -> void:
	if not is_carrying_box["robot"]:
		print_error_message(current_instruction_idx + 1, "runtime")
	else:
		robot.animated_sprite_2d.flip_h = false
		if robot.global_position == register_positions[0]:
			robot.animated_sprite_2d.play("walk")
			var tween = create_tween()
			tween.tween_property(robot, "global_position", register_positions[2], 2)
			timer.wait_time = 2
			timer.timeout.connect(put_outbox.bind(true))
			timer.start()
		elif robot.global_position == register_positions[1]:
			robot.animated_sprite_2d.play("walk")
			var tween = create_tween()
			tween.tween_property(robot, "global_position", register_positions[2], 4)
			timer.wait_time = 4
			timer.timeout.connect(put_outbox.bind(true))
			timer.start()
		else:
			put_outbox(false)

func put_outbox(has_connected: bool) -> void:
	if has_connected:
		timer.timeout.disconnect(put_outbox)
	robot.animated_sprite_2d.play("idle")
	if !output_boxes.is_empty():
		var tween = create_tween()
		tween.set_parallel(true)
		for box: Box in output_boxes:
			var init_x: int = box.global_position.x
			var init_y: int = box.global_position.y
			tween.tween_property(box, "global_position", Vector2(init_x, init_y + 50), 0.5)
		down_conveyer.animated_sprite_2d.play("scroll")
		down_conveyer_2.animated_sprite_2d.play("scroll")
		down_conveyer_3.animated_sprite_2d.play("scroll")
		down_conveyer_4.animated_sprite_2d.play("scroll")
		down_conveyer_5.animated_sprite_2d.play("scroll")
		timer.wait_time = 0.5
		timer.timeout.connect(stop_down_conveyers.bind(true))
		timer.start()
	else:
		stop_down_conveyers(false)

func execute_register_operations(register: int, type: String) -> void:
	var current_register: int = 0
	for i in range(3):
		if robot.global_position == register_positions[i]:
			current_register = i
	if current_register != register:
		var tween = create_tween()
		robot.animated_sprite_2d.flip_h = register_flip_h[Vector2(current_register, register)]
		robot.animated_sprite_2d.play("walk")
		tween.tween_property(robot, "global_position", register_positions[register], register_time[Vector2(current_register, register)])
		timer.wait_time = register_time[Vector2(current_register, register)]
		timer.timeout.connect(stop_and_wait.bind(register, type))
		timer.start()
	else:
		timer.wait_time = 0.5
		timer.timeout.connect(calculate.bind(register, type))
		timer.start()

func stop_and_wait(register: int, type: String) -> void:
	timer.timeout.disconnect(stop_and_wait)
	robot.animated_sprite_2d.play("idle")
	timer.wait_time = 0.5
	timer.timeout.connect(calculate.bind(register, type))
	timer.start()

func calculate(register: int, type: String) -> void:
	timer.timeout.disconnect(calculate)
	var target = int(registers[register].label.text)
	var source = int(robot_carrying_box.label.text)
	if type == "add":
		robot_carrying_box.label.text = str(source + target)
	elif type == "sub":
		robot_carrying_box.label.text = str(source - target)
	elif type == "copyto":
		registers[register].label.text = str(source)
		registers[register].visible = true
		is_carrying_box[register] = true
	elif type == "copyfrom":
		robot_carrying_box.label.text = str(target)
		robot_carrying_box.visible = true
		is_carrying_box["robot"] = true
	execute_one_button.disabled = false
	execute_all_button.disabled = false
	restart_button.disabled = false
	check_is_gameover()

func check_is_gameover() -> void:
	if current_instruction_idx == len(input_instructions) - 1:
		show_gameover_window()
	else:
		current_instruction_idx += 1
		current_instruction_label.text = tr("line {0}: {1}").format([current_instruction_idx + 1, input_instructions[current_instruction_idx]])
		if execute_all_mode:
			execute_one_button.disabled = true
			execute_all_button.disabled = true
			restart_button.disabled = true
			timer.wait_time = 0.5
			timer.timeout.connect(execute_one_step_with_timeout)
			timer.start()

func show_gameover_window() -> void:
	color_rect.visible = true
	game_over_window.visible = true
	if output_sequence != levels[current_level_idx].expected_output:
		game_over_window.caption.text = tr("Level Fail")
		game_over_window.message.text = tr("Think again!")
		game_over_window.game_over_button.text = tr("Restart")
		game_over_window.game_over_button.pressed.connect(execute_once_restart)
	elif current_level_idx == len(levels) - 1:
		update_level_data()
		game_over_window.caption.text = tr("Good Job")
		game_over_window.message.text = tr("Line count of this level: {0}\nYou have finished all levels!\n").format([len(input_instructions)])
		game_over_window.game_over_button.text = tr("Back to menu")
		game_over_window.game_over_button.pressed.connect(emit_levels_completed)
	else:
		update_level_data()
		game_over_window.caption.text = tr("Level Success")
		game_over_window.message.text = tr("Let's go ahead!\nLine count of this level: {0}").format([len(input_instructions)])
		game_over_window.game_over_button.text = tr("Yes")
		current_level_idx += 1
		game_over_window.game_over_button.pressed.connect(execute_once_restart)

func execute_once_restart() -> void:
	game_over_window.game_over_button.pressed.disconnect(execute_once_restart)
	restart()

func emit_levels_completed() -> void:
	game_over_window.game_over_button.pressed.disconnect(emit_levels_completed)
	levels_completed.emit()

func update_level_data():
	if is_default:
		var data = ResourceLoader.load("user://default_level_data.res") as DefaultLevelData
		if current_level_idx >= data.accessible_default_level:
			data.accessible_default_level = current_level_idx + 1
			ResourceSaver.save(data, "user://default_level_data.res")
