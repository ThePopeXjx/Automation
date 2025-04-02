extends Node2D

@onready var mask: ColorRect = $Mask
@onready var logo_scene: Node2D = $LogoScene
@onready var timer: Timer = $Timer
@onready var main_menu: MainMenu = $MainMenu
@onready var level_scene_tile_map: LevelSceneTileMap = $LevelSceneTileMap

func _ready() -> void:
	TranslationServer.set_locale("en")
	if not FileAccess.file_exists("user://default_level_data.res"):
		var data = DefaultLevelData.new()
		data.accessible_default_level = 0
		ResourceSaver.save(data, "user://default_level_data.res")
	var tween = create_tween()
	tween.tween_property(mask, "color", Color(0, 0, 0, 0), 2)
	timer.wait_time = 4
	timer.timeout.connect(hide_logo_scene)
	timer.start()

func hide_logo_scene() -> void:
	timer.timeout.disconnect(hide_logo_scene)
	var tween = create_tween()
	tween.tween_property(mask, "color", Color(0, 0, 0, 1), 2)
	tween.tween_property(mask, "color", Color(0, 0, 0, 0), 2)
	timer.wait_time = 2
	timer.timeout.connect(show_main_menu)
	timer.start()

func show_main_menu() -> void:
	timer.timeout.disconnect(show_main_menu)
	main_menu.title.global_position = Vector2(307, -76)
	main_menu.default_levels_button.global_position = Vector2(336, 551)
	main_menu.custom_levels_button.global_position = Vector2(336, 624)
	main_menu.language_button.global_position = Vector2(365, 697)
	logo_scene.visible = false
	level_scene_tile_map.visible = false
	main_menu.visible = true
	timer.wait_time = 2
	timer.timeout.connect(raise_mask)
	timer.timeout.connect(move_title_and_buttons)
	timer.start()

func raise_mask() -> void:
	timer.timeout.disconnect(raise_mask)
	mask.visible = false
	
func move_title_and_buttons() -> void:
	timer.timeout.disconnect(move_title_and_buttons)
	main_menu.default_levels_button.disabled = true
	main_menu.custom_levels_button.disabled = true
	main_menu.language_button.disabled = true
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(main_menu.title, "global_position", Vector2(307, 135), 2)
	tween.tween_property(main_menu.default_levels_button, "global_position", Vector2(336, 221), 2)
	tween.tween_property(main_menu.custom_levels_button, "global_position", Vector2(336, 294), 2)
	tween.tween_property(main_menu.language_button, "global_position", Vector2(365, 367), 2)
	timer.wait_time = 2
	timer.timeout.connect(enable_buttons)
	timer.start()

func enable_buttons() -> void:
	timer.timeout.disconnect(enable_buttons)
	main_menu.default_levels_button.disabled = false
	main_menu.custom_levels_button.disabled = false
	main_menu.language_button.disabled = false
	main_menu.default_levels_button.pressed.connect(select_default_levels)
	main_menu.custom_levels_button.pressed.connect(show_file_selection_window)
	main_menu.language_button.pressed.connect(show_language_selection_window)

func select_default_levels() -> void:
	level_scene_tile_map.is_default = true
	level_scene_tile_map.levels = Level.default_levels
	var data = ResourceLoader.load("user://default_level_data.res") as DefaultLevelData
	var idx: int = 1
	main_menu.level_selection_window.item_list.clear()
	for level: Level in Level.default_levels:
		main_menu.level_selection_window.item_list.add_item(
			tr("Level {0}: {1}").format([idx, level.caption])
		)
		if idx - 1 > data.accessible_default_level:
			main_menu.level_selection_window.item_list.set_item_disabled(idx - 1, true)
		idx += 1
	main_menu.level_selection_window.visible = true
	main_menu.level_selection_window.enter_button.pressed.connect(enter_levels)

func enter_levels() -> void:
	if main_menu.level_selection_window.item_list.is_anything_selected():
		main_menu.level_selection_window.enter_button.pressed.disconnect(enter_levels)
		level_scene_tile_map.current_level_idx = main_menu.level_selection_window.item_list.get_selected_items()[0]
		mask.visible = true
		var tween = create_tween()
		tween.tween_property(mask, "color", Color(0, 0, 0, 1), 2)
		tween.tween_property(mask, "color", Color(0, 0, 0, 0), 2)
		timer.wait_time = 2
		timer.timeout.connect(show_level_scene)
		timer.start()

func show_level_scene() -> void:
	timer.timeout.disconnect(show_level_scene)
	main_menu.visible = false
	level_scene_tile_map.visible = true
	level_scene_tile_map.restart()
	timer.wait_time = 2
	timer.timeout.connect(raise_mask)
	timer.start()

func _on_level_scene_tile_map_levels_completed() -> void:
	main_menu.level_selection_window.visible = false
	mask.visible = true
	var tween = create_tween()
	tween.tween_property(mask, "color", Color(0, 0, 0, 1), 2)
	tween.tween_property(mask, "color", Color(0, 0, 0, 0), 2)
	timer.wait_time = 2
	timer.timeout.connect(show_main_menu)
	timer.start()

func show_file_selection_window() -> void:
	DisplayServer.file_dialog_show(tr("Select Level File"), "C:/", "", false, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, ["*.json"], check_custom_file)

func check_custom_file(status: bool, selected_paths: PackedStringArray, selected_filter_index: int) -> void:
	if selected_paths.is_empty():
		return
	var path: String = selected_paths[0]
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	var json = JSON.new()
	var error: Error = json.parse(content)
	var custom_levels: Array[Level] = []
	if error == OK:
		var data_received = json.data
		if typeof(data_received) == TYPE_DICTIONARY and data_received.keys() == ["levels"] and typeof(data_received["levels"]) == TYPE_ARRAY:
			for level in data_received["levels"]:
				if typeof(level) == TYPE_DICTIONARY and \
				   level.keys() == ["caption", "input", "instructions_allowed", "expected_output", "available_registers", "description"] and \
				   typeof(level["caption"]) == TYPE_STRING and level["caption"] != "" and \
				   typeof(level["input"]) == TYPE_ARRAY and is_int_array(level["input"]) and not level["input"].is_empty() and \
				   typeof(level["instructions_allowed"]) == TYPE_ARRAY and is_valid_instructions(level["instructions_allowed"]) and is_unique(level["instructions_allowed"]) and not level["instructions_allowed"].is_empty() and \
				   typeof(level["expected_output"]) == TYPE_ARRAY and is_int_array(level["expected_output"]) and not level["expected_output"].is_empty() and \
				   typeof(level["available_registers"]) == TYPE_ARRAY and is_valid_registers(level["available_registers"]) and is_unique(level["available_registers"]) and \
				   typeof(level["description"]) == TYPE_STRING and level["description"] != "":
					custom_levels.append(Level.create_level(
						level["caption"],
						to_int_array(level["input"]),
						to_string_array(level["instructions_allowed"]),
						to_int_array(level["expected_output"]),
						to_int_array(level["available_registers"]),
						level["description"]))
				else:
					main_menu.warning_window.visible = true
					return
			level_scene_tile_map.is_default = false
			level_scene_tile_map.levels = custom_levels
			select_custom_levels()
		else:
			main_menu.warning_window.visible = true
	else:
		main_menu.warning_window.visible = true

func select_custom_levels() -> void:
	var idx: int = 1
	main_menu.level_selection_window.item_list.clear()
	for level: Level in level_scene_tile_map.levels:
		main_menu.level_selection_window.item_list.add_item(
			tr("Level {0}: {1}").format([idx, level.caption])
		)
		idx += 1
	main_menu.level_selection_window.visible = true
	main_menu.level_selection_window.enter_button.pressed.connect(enter_levels)

func is_int_array(a: Array) -> bool:
	for item in a:
		if typeof(item) != TYPE_FLOAT or item != roundi(item):
			return false
	return true

func is_valid_instructions(i: Array) -> bool:
	for item in i:
		if item not in LevelSceneTileMap.single_instructions and item not in LevelSceneTileMap.double_instructions:
			return false
	return true

func is_valid_registers(r: Array) -> bool:
	for item in r:
		if typeof(item) != TYPE_FLOAT or item != roundi(item) or roundi(item) not in LevelSceneTileMap.valid_registers:
			return false
	return true

func is_unique(a: Array) -> bool:
	var l = len(a)
	a.sort()
	for i in range(l - 1):
		if a[i] == a[i + 1]:
			return false
	return true

func to_int_array(a: Array) -> Array[int]:
	var new_a: Array[int] = []
	for item in a:
		new_a.append(roundi(item))
	return new_a

func to_string_array(a: Array) -> Array[String]:
	var new_a: Array[String] = []
	for item in a:
		new_a.append(str(item))
	return new_a

func show_language_selection_window() -> void:
	main_menu.language_selection_window.visible = true
	main_menu.language_selection_window.enter_button.pressed.connect(change_language)

func change_language() -> void:
	if main_menu.language_selection_window.item_list.is_anything_selected():
		main_menu.language_selection_window.enter_button.pressed.disconnect(change_language)
		var idx = main_menu.language_selection_window.item_list.get_selected_items()[0]
		if idx == 0:
			TranslationServer.set_locale("en")
		else:
			TranslationServer.set_locale("zh_CN")
		main_menu.language_selection_window.visible = false

func _process(delta: float) -> void:
	if Input.is_action_pressed("exit"):
		get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
		get_tree().quit()
