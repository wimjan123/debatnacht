extends Node

# Advanced save/load system with JSON serialization, version validation, and integrity checks
# Handles multiple save slots, compression, and data validation

# Singleton instance
static var _instance: SaveLoadManager

# Dependencies
var game_state_manager: GameStateManager
var ui_state_manager: UIStateManager
var event_bus: EventBus

# Save/Load Configuration
const SAVE_VERSION: String = "1.0.0"
const SAVE_DIRECTORY: String = "user://saves/"
const AUTO_SAVE_DIRECTORY: String = "user://autosaves/"
const BACKUP_DIRECTORY: String = "user://backups/"
const MAX_SAVE_SLOTS: int = 10
const MAX_AUTO_SAVES: int = 5
const MAX_BACKUPS: int = 3

# File extensions
const SAVE_EXTENSION: String = ".json"
const COMPRESSED_EXTENSION: String = ".gz"
const METADATA_EXTENSION: String = ".meta"

# Save/Load settings
var compression_enabled: bool = true
var checksum_validation: bool = true
var auto_backup: bool = true
var save_ui_state: bool = true

# Save data structure
class SaveData:
	var version: String
	var timestamp: float
	var game_state: Dictionary
	var ui_state: Dictionary
	var metadata: Dictionary
	var checksum: String
	
	func _init():
		version = SAVE_VERSION
		timestamp = Time.get_unix_time_from_system()
		game_state = {}
		ui_state = {}
		metadata = {}
		checksum = ""
	
	func serialize() -> Dictionary:
		return {
			"version": version,
			"timestamp": timestamp,
			"game_state": game_state,
			"ui_state": ui_state,
			"metadata": metadata,
			"checksum": checksum
		}
	
	func deserialize(data: Dictionary) -> bool:
		if not data.has("version") or not data.has("timestamp"):
			return false
		
		version = data.get("version", "")
		timestamp = data.get("timestamp", 0.0)
		game_state = data.get("game_state", {})
		ui_state = data.get("ui_state", {})
		metadata = data.get("metadata", {})
		checksum = data.get("checksum", "")
		return true

# Signals
signal save_started(slot_name: String)
signal save_completed(slot_name: String, success: bool, error_message: String)
signal load_started(slot_name: String)
signal load_completed(slot_name: String, success: bool, error_message: String)
signal save_slots_updated(available_slots: Array)
signal backup_created(backup_name: String)

func _ready() -> void:
	# Initialize singleton
	if _instance == null:
		_instance = self
		process_mode = Node.PROCESS_MODE_ALWAYS
		
		# Initialize dependencies
		_initialize_dependencies()
		
		# Setup directories
		_ensure_directories_exist()
		
		# Setup periodic cleanup
		_setup_cleanup_timer()
	else:
		queue_free()

static func get_instance() -> SaveLoadManager:
	"""Get singleton instance of SaveLoadManager"""
	if _instance == null:
		# Create instance if it doesn't exist
		var scene_tree = Engine.get_main_loop() as SceneTree
		if scene_tree:
			_instance = SaveLoadManager.new()
			scene_tree.root.add_child(_instance)
	return _instance

func _initialize_dependencies() -> void:
	"""Initialize references to required managers"""
	game_state_manager = GameStateManager.get_instance()
	ui_state_manager = UIStateManager.get_instance()
	event_bus = EventBus.get_instance()
	
	print("SaveLoadManager: Dependencies initialized")

func _ensure_directories_exist() -> void:
	"""Ensure all required directories exist"""
	var directories = [SAVE_DIRECTORY, AUTO_SAVE_DIRECTORY, BACKUP_DIRECTORY]
	
	for dir_path in directories:
		if not DirAccess.dir_exists_absolute(dir_path):
			var dir = DirAccess.open("user://")
			if dir:
				dir.make_dir_recursive(dir_path)
				print("SaveLoadManager: Created directory: ", dir_path)

func _setup_cleanup_timer() -> void:
	"""Setup periodic cleanup of old saves and backups"""
	var timer = Timer.new()
	timer.wait_time = 300.0  # 5 minutes
	timer.autostart = true
	timer.timeout.connect(_on_cleanup_timer)
	add_child(timer)

# Main save/load functions
func save_game(slot_name: String = "quicksave", description: String = "") -> bool:
	"""Save current game state to specified slot"""
	save_started.emit(slot_name)
	
	# Validate slot name
	if not _is_valid_slot_name(slot_name):
		var error = "Invalid slot name: " + slot_name
		save_completed.emit(slot_name, false, error)
		return false
	
	# Get current game state
	var current_game_state = game_state_manager.get_current_state()
	if not current_game_state:
		var error = "No active game state to save"
		save_completed.emit(slot_name, false, error)
		return false
	
	# Create save data
	var save_data = SaveData.new()
	
	# Serialize game state
	save_data.game_state = current_game_state.serialize()
	
	# Serialize UI state if enabled
	if save_ui_state and ui_state_manager:
		save_data.ui_state = _serialize_ui_state()
	
	# Create metadata
	save_data.metadata = _create_save_metadata(description, current_game_state)
	
	# Calculate checksum if enabled
	if checksum_validation:
		save_data.checksum = _calculate_checksum(save_data)
	
	# Write to file
	var file_path = _get_save_file_path(slot_name)
	var success = _write_save_file(file_path, save_data)
	
	if success:
		# Create backup if enabled
		if auto_backup:
			_create_backup(slot_name)
		
		# Emit completion signal
		save_completed.emit(slot_name, true, "")
		print("SaveLoadManager: Game saved successfully to slot: ", slot_name)
		
		# Publish event
		event_bus.publish("game_saved", {
			"slot_name": slot_name,
			"timestamp": save_data.timestamp
		}, EventBus.EventCategory.USER_ACTION)
	else:
		var error = "Failed to write save file"
		save_completed.emit(slot_name, false, error)
	
	return success

func load_game(slot_name: String) -> bool:
	"""Load game state from specified slot"""
	load_started.emit(slot_name)
	
	# Check if save file exists
	var file_path = _get_save_file_path(slot_name)
	if not FileAccess.file_exists(file_path):
		var error = "Save file not found: " + slot_name
		load_completed.emit(slot_name, false, error)
		return false
	
	# Read save file
	var save_data = _read_save_file(file_path)
	if not save_data:
		var error = "Failed to read save file: " + slot_name
		load_completed.emit(slot_name, false, error)
		return false
	
	# Validate save version
	if not _validate_save_version(save_data.version):
		var error = "Incompatible save version: " + save_data.version
		load_completed.emit(slot_name, false, error)
		return false
	
	# Validate checksum if enabled
	if checksum_validation and not _validate_checksum(save_data):
		var error = "Save file corrupted (checksum mismatch)"
		load_completed.emit(slot_name, false, error)
		return false
	
	# Deserialize game state
	var game_state = DataModels.GameState.new()
	var deserialize_success = game_state.deserialize(save_data.game_state)
	
	if not deserialize_success:
		var error = "Failed to deserialize game state"
		load_completed.emit(slot_name, false, error)
		return false
	
	# Update game state manager
	game_state_manager.update_game_state(game_state, "Game loaded from: " + slot_name)
	
	# Restore UI state if available
	if save_ui_state and save_data.ui_state.size() > 0:
		_restore_ui_state(save_data.ui_state)
	
	# Emit completion signal
	load_completed.emit(slot_name, true, "")
	print("SaveLoadManager: Game loaded successfully from slot: ", slot_name)
	
	# Publish event
	event_bus.publish("game_loaded", {
		"slot_name": slot_name,
		"timestamp": save_data.timestamp
	}, EventBus.EventCategory.USER_ACTION)
	
	return true

# Auto-save functionality
func create_auto_save() -> bool:
	"""Create an automatic save"""
	var auto_save_name = "auto_" + Time.get_datetime_string_from_system().replace(":", "-")
	var file_path = AUTO_SAVE_DIRECTORY + auto_save_name + SAVE_EXTENSION
	
	# Create save data similar to regular save
	var current_game_state = game_state_manager.get_current_state()
	if not current_game_state:
		return false
	
	var save_data = SaveData.new()
	save_data.game_state = current_game_state.serialize()
	save_data.metadata = _create_save_metadata("Auto-save", current_game_state)
	
	if checksum_validation:
		save_data.checksum = _calculate_checksum(save_data)
	
	var success = _write_save_file(file_path, save_data)
	
	if success:
		# Clean up old auto-saves
		_cleanup_old_auto_saves()
		print("SaveLoadManager: Auto-save created: ", auto_save_name)
	
	return success

func get_available_save_slots() -> Array[Dictionary]:
	"""Get list of available save slots with metadata"""
	var save_slots: Array[Dictionary] = []
	
	# Scan save directory
	var dir = DirAccess.open(SAVE_DIRECTORY)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(SAVE_EXTENSION):
				var slot_name = file_name.trim_suffix(SAVE_EXTENSION)
				var metadata = _get_save_metadata(slot_name)
				if metadata.size() > 0:
					save_slots.append({
						"slot_name": slot_name,
						"metadata": metadata
					})
			
			file_name = dir.get_next()
	
	# Sort by timestamp (newest first)
	save_slots.sort_custom(func(a, b): return a.metadata.timestamp > b.metadata.timestamp)
	
	return save_slots

func get_available_auto_saves() -> Array[Dictionary]:
	"""Get list of available auto-saves"""
	var auto_saves: Array[Dictionary] = []
	
	var dir = DirAccess.open(AUTO_SAVE_DIRECTORY)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(SAVE_EXTENSION) and file_name.begins_with("auto_"):
				var auto_save_path = AUTO_SAVE_DIRECTORY + file_name
				var save_data = _read_save_file(auto_save_path)
				if save_data:
					auto_saves.append({
						"file_name": file_name.trim_suffix(SAVE_EXTENSION),
						"timestamp": save_data.timestamp,
						"metadata": save_data.metadata
					})
			
			file_name = dir.get_next()
	
	# Sort by timestamp (newest first)
	auto_saves.sort_custom(func(a, b): return a.timestamp > b.timestamp)
	
	return auto_saves

func delete_save_slot(slot_name: String) -> bool:
	"""Delete a save slot"""
	var file_path = _get_save_file_path(slot_name)
	
	if not FileAccess.file_exists(file_path):
		return false
	
	var dir = DirAccess.open(SAVE_DIRECTORY)
	if dir:
		dir.remove(slot_name + SAVE_EXTENSION)
		# Also remove metadata file if it exists
		var meta_file = slot_name + METADATA_EXTENSION
		if FileAccess.file_exists(SAVE_DIRECTORY + meta_file):
			dir.remove(meta_file)
		
		print("SaveLoadManager: Deleted save slot: ", slot_name)
		return true
	
	return false

# Helper functions
func _is_valid_slot_name(slot_name: String) -> bool:
	"""Validate slot name"""
	if slot_name.is_empty() or slot_name.length() > 50:
		return false
	
	# Check for invalid characters
	var invalid_chars = ["/", "\\", ":", "*", "?", '"', "<", ">", "|"]
	for char in invalid_chars:
		if char in slot_name:
			return false
	
	return true

func _get_save_file_path(slot_name: String) -> String:
	"""Get full path for save file"""
	return SAVE_DIRECTORY + slot_name + SAVE_EXTENSION

func _write_save_file(file_path: String, save_data: SaveData) -> bool:
	"""Write save data to file with optional compression"""
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		return false
	
	var json_string = JSON.stringify(save_data.serialize())
	
	if compression_enabled:
		# Compress data
		var compressed_data = json_string.to_utf8_buffer().compress(FileAccess.COMPRESSION_GZIP)
		file.store_buffer(compressed_data)
		# Rename file to indicate compression
		file.close()
		var dir = DirAccess.open(SAVE_DIRECTORY)
		if dir:
			var compressed_path = file_path + COMPRESSED_EXTENSION
			dir.rename(file_path, compressed_path)
	else:
		file.store_string(json_string)
		file.close()
	
	return true

func _read_save_file(file_path: String) -> SaveData:
	"""Read save data from file with decompression support"""
	# Check if compressed version exists
	var compressed_path = file_path + COMPRESSED_EXTENSION
	var use_compression = FileAccess.file_exists(compressed_path)
	var actual_path = compressed_path if use_compression else file_path
	
	if not FileAccess.file_exists(actual_path):
		return null
	
	var file = FileAccess.open(actual_path, FileAccess.READ)
	if not file:
		return null
	
	var json_string: String
	
	if use_compression:
		# Decompress data
		var compressed_data = file.get_buffer(file.get_length())
		var decompressed_data = compressed_data.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
		json_string = decompressed_data.get_string_from_utf8()
	else:
		json_string = file.get_as_text()
	
	file.close()
	
	# Parse JSON
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		return null
	
	# Create and populate save data
	var save_data = SaveData.new()
	if save_data.deserialize(json.data):
		return save_data
	
	return null

func _serialize_ui_state() -> Dictionary:
	"""Serialize UI state for saving"""
	var ui_state = {
		"current_screen": ui_state_manager.get_current_screen(),
		"navigation_history": ui_state_manager.get_navigation_history(),
		"ui_preferences": ui_state_manager.get_all_ui_preferences(),
		"screen_states": {}
	}
	
	# Save specific screen states that should persist
	var important_screens = ["Dashboard", "MapView", "CoalitionBuilder"]
	for screen in important_screens:
		if ui_state_manager.has_screen_state(screen):
			ui_state.screen_states[screen] = ui_state_manager.get_screen_state(screen)
	
	return ui_state

func _restore_ui_state(ui_state: Dictionary) -> void:
	"""Restore UI state from loaded data"""
	if ui_state.has("ui_preferences"):
		ui_state_manager.set_multiple_preferences(ui_state.ui_preferences)
	
	if ui_state.has("screen_states"):
		for screen_name in ui_state.screen_states.keys():
			ui_state_manager.save_screen_state(screen_name, ui_state.screen_states[screen_name])
	
	# Don't restore navigation history or current screen - let the UI flow naturally

func _create_save_metadata(description: String, game_state: DataModels.GameState) -> Dictionary:
	"""Create metadata for save file"""
	return {
		"description": description,
		"player_party": game_state.player_party.name if game_state.player_party else "Unknown",
		"current_date": game_state.current_date,
		"game_phase": game_state.current_phase,
		"play_time": game_state.total_play_time,
		"version": SAVE_VERSION,
		"created_at": Time.get_datetime_string_from_system()
	}

func _get_save_metadata(slot_name: String) -> Dictionary:
	"""Get metadata for a save slot"""
	var file_path = _get_save_file_path(slot_name)
	var save_data = _read_save_file(file_path)
	
	if save_data:
		return save_data.metadata
	return {}

func _calculate_checksum(save_data: SaveData) -> String:
	"""Calculate checksum for save data integrity"""
	# Simple checksum based on serialized data
	var data_string = JSON.stringify(save_data.game_state) + JSON.stringify(save_data.ui_state)
	return data_string.md5_text()

func _validate_checksum(save_data: SaveData) -> bool:
	"""Validate save data checksum"""
	if save_data.checksum.is_empty():
		return true  # No checksum to validate
	
	var calculated_checksum = _calculate_checksum(save_data)
	return calculated_checksum == save_data.checksum

func _validate_save_version(version: String) -> bool:
	"""Validate save file version compatibility"""
	var version_parts = version.split(".")
	var current_parts = SAVE_VERSION.split(".")
	
	if version_parts.size() != 3 or current_parts.size() != 3:
		return false
	
	# Major version must match, minor and patch can be different
	return version_parts[0] == current_parts[0]

func _create_backup(slot_name: String) -> void:
	"""Create backup of save file"""
	var source_path = _get_save_file_path(slot_name)
	var backup_name = slot_name + "_" + Time.get_datetime_string_from_system().replace(":", "-")
	var backup_path = BACKUP_DIRECTORY + backup_name + SAVE_EXTENSION
	
	var dir = DirAccess.open(SAVE_DIRECTORY)
	if dir and FileAccess.file_exists(source_path):
		dir.copy(source_path, backup_path)
		backup_created.emit(backup_name)
		
		# Clean up old backups
		_cleanup_old_backups()

# Cleanup functions
func _cleanup_old_auto_saves() -> void:
	"""Remove old auto-saves beyond the limit"""
	var auto_saves = get_available_auto_saves()
	
	if auto_saves.size() > MAX_AUTO_SAVES:
		var to_remove = auto_saves.slice(MAX_AUTO_SAVES)
		var dir = DirAccess.open(AUTO_SAVE_DIRECTORY)
		
		for save_info in to_remove:
			if dir:
				dir.remove(save_info.file_name + SAVE_EXTENSION)
				print("SaveLoadManager: Cleaned up old auto-save: ", save_info.file_name)

func _cleanup_old_backups() -> void:
	"""Remove old backups beyond the limit"""
	var backups: Array[Dictionary] = []
	
	var dir = DirAccess.open(BACKUP_DIRECTORY)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(SAVE_EXTENSION):
				var file_path = BACKUP_DIRECTORY + file_name
				var file_time = FileAccess.get_modified_time(file_path)
				backups.append({
					"name": file_name,
					"time": file_time
				})
			
			file_name = dir.get_next()
	
	# Sort by time (newest first)
	backups.sort_custom(func(a, b): return a.time > b.time)
	
	# Remove excess backups
	if backups.size() > MAX_BACKUPS:
		var to_remove = backups.slice(MAX_BACKUPS)
		for backup in to_remove:
			dir.remove(backup.name)
			print("SaveLoadManager: Cleaned up old backup: ", backup.name)

func _on_cleanup_timer() -> void:
	"""Handle periodic cleanup timer"""
	_cleanup_old_auto_saves()
	_cleanup_old_backups()

# Public utility functions
func export_save_data(slot_name: String, export_path: String) -> bool:
	"""Export save data to external location"""
	var source_path = _get_save_file_path(slot_name)
	if not FileAccess.file_exists(source_path):
		return false
	
	var dir = DirAccess.open("user://")
	if dir:
		return dir.copy(source_path, export_path) == OK
	
	return false

func import_save_data(import_path: String, slot_name: String) -> bool:
	"""Import save data from external location"""
	if not FileAccess.file_exists(import_path):
		return false
	
	# Validate imported save first
	var save_data = _read_save_file(import_path)
	if not save_data:
		return false
	
	if not _validate_save_version(save_data.version):
		return false
	
	# Copy to save directory
	var target_path = _get_save_file_path(slot_name)
	var dir = DirAccess.open("user://")
	if dir:
		return dir.copy(import_path, target_path) == OK
	
	return false

# Debug and monitoring
func get_save_system_info() -> Dictionary:
	"""Get information about the save system"""
	var available_slots = get_available_save_slots()
	var auto_saves = get_available_auto_saves()
	
	return {
		"save_version": SAVE_VERSION,
		"compression_enabled": compression_enabled,
		"checksum_validation": checksum_validation,
		"available_slots": available_slots.size(),
		"auto_saves": auto_saves.size(),
		"max_save_slots": MAX_SAVE_SLOTS,
		"max_auto_saves": MAX_AUTO_SAVES
	}

# Cleanup
func _exit_tree() -> void:
	"""Cleanup when manager is destroyed"""
	# Clear singleton reference
	if _instance == self:
		_instance = null
	
	print("SaveLoadManager: Cleaned up")
