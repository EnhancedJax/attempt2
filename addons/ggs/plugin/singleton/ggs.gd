@tool
extends Node
## The core GGS singleton. Handles everything that needs a persistent
## and global instance to function.

## Can be used to react to a setting being applied. [param setting] is
## the [member ggsSetting.key] name of the setting resource this is emitted
## from.
signal setting_applied(setting: ggsSetting, value: Variant)
signal settings_loaded(loaded_settings: Dictionary)

## Base directory where the save file will be saved.
const BASE_PATH: String = "user://"

## Name of the config _file that will be used to save and load game settings.
@export var config_file: String = "settings.cfg"

## Location of your setting resources.
@export_dir var settings_dir: String = "res://game_settings"

@export_group("Input Preferences")
## Time the input component listens for input. When this expires, it
## automatically stops listening for input.
@export_range(0.001, 4096, 0.001, "exp", "suffix:s")
var listen_time: float = 3.0

## Delay before accepting the chosen input. Mainly used to give enough time
## to process modifiers for keyboard and mouse events.[br]
## If you don't plan to accept modifiers, you can set this to its minimum
## value.[br]
## If you do, choosing a number that's too low may prevent the users from
## inputting a key with modifier.
@export_range(0.001, 4096, 0.001, "exp", "suffix:s")
var accept_delay: float = 0.33

## The button text animation speed when an input component is listening for
## input. A higher value means slower animation.
@export var anim_speed: float = 1.5

## The default glyph type that should be used when no gamepad device is
## connected or the device is not recognized.
@export_custom(PROPERTY_HINT_ENUM, "other,xbox,ps,switch")
var default_glyph: String = "other"

var _file_path: String
var _file: ConfigFile = ConfigFile.new()
var _settings: Array[ggsSetting]

# Dictionary to store the local copy (state) of all settings values.
var _value_states: Dictionary = {}

## Used to group and access audio players (e.g. [code]GGS.Audio.Interact[/code])
@onready var Audio: Node = $Audio


func _ready() -> void:
	# Connect our internal setting applied signal to update _value_states
	if not DirAccess.dir_exists_absolute(settings_dir):
		DirAccess.make_dir_absolute(settings_dir)

		if Engine.is_editor_hint():
			var editor_interface: Object = Engine.get_singleton("EditorInterface")
			editor_interface.get_resource_filesystem().scan()

	_settings = _get_all_settings()
	_file_init()
	_file_clean_up()

	# Apply all the settings.
	if not Engine.is_editor_hint():
		_apply_all()

	# Initialize the internal state by reading all setting values.
	for setting: ggsSetting in _settings:
		_value_states[setting.key] = get_value(setting)
		
	# Emit the settings_loaded signal with the current state of loaded settings.
	settings_loaded.emit(_value_states)


## Helper function to print the contents of the config file.
func print_file_contents() -> void:
	print("[DEBUG] Config file content start:")
	for section in _file.get_sections():
		print("  Section: ", section)
		for key in _file.get_section_keys(section):
			print("    ", key, " = ", _file.get_value(section, key))
	print("[DEBUG] Config file content end.")

## Saves the provided [param value] in the provided [param setting] key of
## the save file.
func set_value(setting: ggsSetting, value: Variant) -> void:
	_file.set_value(setting.section, setting.key, value)
	_file.save(_file_path)
	print("[DEBUG] set_value: ", setting.section, " - ", setting.key, " set to: ", value)
	_on_setting_applied(setting, value)
	# Emit the signal so that our internal state (and any other listener) gets updated immediately.
	GGS.setting_applied.emit(setting, value)
	

## Loads the current value of the provided [param setting] from the save
## file. Returns the setting's default if its key doesn't exist.
func get_value(setting: ggsSetting) -> Variant:
	var val = _file.get_value(setting.section, setting.key, setting.default)
	print("[DEBUG] get_value: Getting ", setting.section, ", ", setting.key, " -> ", val)
	return val


## Gets a copy/the state of the setting from an internal copy in GGS.
## This function first checks if the value exists in our local _value_states
## dictionary. If it does not, it retrieves it from the config file (using get_value)
## and caches it in _value_states.
func get_value_state(setting: ggsSetting) -> Variant:
	if not _value_states.has(setting.key):
		_value_states[setting.key] = get_value(setting)
	return _value_states[setting.key]


## Signal handler to update _value_states whenever a setting is applied.
func _on_setting_applied(setting: ggsSetting, value: Variant) -> void:
	_value_states[setting.key] = value
	print("[DEBUG] _on_setting_applied: Updated state for ", setting.key, " to ", value)


func _get_all_settings() -> Array[ggsSetting]:
	var result: Array[ggsSetting]
	var settings: PackedStringArray = _get_dir_settings(settings_dir)
	for setting: String in settings:
		# ".remap" is trimmed to prevent resource loader errors when
		# the project is exported.
		var obj: Resource = load(setting.trim_suffix(".remap"))
		if obj is not ggsSetting:
			continue

		result.append(obj)

	return result


func _get_dir_settings(path: String) -> PackedStringArray:
	var result: PackedStringArray
	var dir_access: DirAccess = DirAccess.open(path)

	for file: String in dir_access.get_files():
		if file.get_extension() == "gd":
			continue

		var file_path: String = path.path_join(file)
		result.append(file_path)

	for dir: String in dir_access.get_directories():
		var dir_path: String = path.path_join(dir)
		var dir_settings: PackedStringArray = _get_dir_settings(dir_path)
		result.append_array(dir_settings)

	return result


func _file_init() -> void:
	_file_path = BASE_PATH.path_join(config_file)
	if FileAccess.file_exists(_file_path):
		var err = _file.load(_file_path)
		print("[DEBUG] _file_init: Loaded file from: ", _file_path, " with error code: ", err)
		print_file_contents()
	else:
		print("[DEBUG] _file_init: No file exists at: ", _file_path)
	# Save the file regardless (this may create a new file with defaults)
	_file.save(_file_path)
	print("[DEBUG] _file_init: File saved at: ", _file_path)
	

# Removes unused keys and adds missing ones to the save file.
func _file_clean_up() -> void:
	print("[DEBUG] _file_clean_up: Starting clean-up process.")
	# Print file contents before clean-up
	print("[DEBUG] _file_clean_up: File contents before clearing:")
	print_file_contents()

	# 1. Save the current keys in a temp variable for later.
	var temp: Dictionary = {}
	for section in _file.get_sections():
		temp[section] = {}
		for key in _file.get_section_keys(section):
			temp[section][key] = _file.get_value(section, key)

	# 2. Clear the file.
	_file.clear()
	print("[DEBUG] _file_clean_up: File cleared.")

	# 3. Recreate keys from the default value of settings.
	for setting: ggsSetting in _settings:
		if setting.key.is_empty():
			continue

		_file.set_value(setting.section, setting.key, setting.default)
		print("[DEBUG] _file_clean_up: Resetting key: ", setting.section, ", ", setting.key, " to default: ", setting.default)

	# 4. If the key exists in this new file, use temp to restore the value it had before clearing the file.
	for section in temp.keys():
		if not _file.has_section(section):
			continue

		for key in temp[section].keys():
			if not _file.has_section_key(section, key):
				continue

			_file.set_value(section, key, temp[section][key])
			print("[DEBUG] _file_clean_up: Restored key: ", section, ", ", key, " with value: ", temp[section][key])

	# Save the file after clean-up.
	_file.save(_file_path)
	print("[DEBUG] _file_clean_up: File saved after clean-up at: ", _file_path)
	print("[DEBUG] _file_clean_up: File contents after clean-up:")
	print_file_contents()


func _apply_all() -> void:
	for setting: ggsSetting in _settings:
		var value: Variant = get_value(setting)
		setting.apply(value)
