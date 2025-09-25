extends Node

# Global game state management singleton
# Maintains game state, handles save/load operations, manages state transitions

# Game State (no static singleton needed for autoloads)
var current_game_state: DataModels.GameState
var simulation_api: SimulationAPI
var is_game_initialized: bool = false
var save_version: String = "1.0.0"

# State Management
var state_history: Array[Dictionary] = []
var max_history_entries: int = 50
var auto_save_enabled: bool = true
var auto_save_interval: float = 300.0  # 5 minutes
var last_auto_save_time: float = 0.0

# Serialization
const SAVE_FILE_PATH: String = "user://game_save.json"
const AUTO_SAVE_PATH: String = "user://auto_save.json"
const BACKUP_SAVE_PATH: String = "user://game_save_backup.json"

# State change signals
signal game_state_changed(new_state: DataModels.GameState)
signal game_initialized(game_state: DataModels.GameState)
signal save_completed(success: bool, file_path: String)
signal load_completed(success: bool, game_state: DataModels.GameState)
signal auto_save_triggered()

func _ready() -> void:
	# Autoload initialization
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Initialize simulation API connection
	_initialize_simulation_api()

	# Start auto-save timer
	_setup_auto_save()

# No static singleton needed - Godot autoloads handle this

func _initialize_simulation_api() -> void:
	"""Initialize connection to simulation API"""
	# For now, use the fake simulation implementation
	simulation_api = FakeSimulation.new()
	print("GameStateManager: Simulation API initialized")

func _setup_auto_save() -> void:
	"""Setup automatic save timer"""
	if auto_save_enabled:
		var timer = Timer.new()
		timer.wait_time = auto_save_interval
		timer.autostart = true
		timer.timeout.connect(_on_auto_save_timer)
		add_child(timer)

func initialize_new_game(scenario_config: Dictionary = {}) -> void:
	"""Initialize a new game with optional scenario configuration"""
	print("GameStateManager: Initializing new game")
	
	# Create new game state
	current_game_state = DataModels.GameState.new()
	
	# Apply scenario configuration
	if scenario_config.has("parties"):
		current_game_state.available_parties = scenario_config.parties
	if scenario_config.has("start_date"):
		current_game_state.current_date = scenario_config.start_date
	if scenario_config.has("election_date"):
		current_game_state.next_election_date = scenario_config.election_date
	
	# Initialize with simulation API
	if simulation_api:
		simulation_api.initialize_game_state(current_game_state)
	
	# Mark as initialized
	is_game_initialized = true
	
	# Create initial state snapshot
	_create_state_snapshot("Game Initialized")
	
	# Emit signals
	game_initialized.emit(current_game_state)
	game_state_changed.emit(current_game_state)
	
	print("GameStateManager: New game initialized successfully")

func get_current_state() -> DataModels.GameState:
	"""Get current game state"""
	return current_game_state

func update_game_state(new_state: DataModels.GameState, description: String = "State Updated") -> void:
	"""Update the current game state with change tracking"""
	if not is_game_initialized:
		print("Warning: Attempting to update game state before initialization")
		return
	
	# Create snapshot of current state before updating
	_create_state_snapshot(description)
	
	# Update current state
	current_game_state = new_state
	
	# Notify simulation API of state change
	if simulation_api:
		simulation_api.update_game_state(current_game_state)
	
	# Emit state change signal
	game_state_changed.emit(current_game_state)
	
	print("GameStateManager: State updated - ", description)

func apply_campaign_action(action: DataModels.CampaignAction) -> bool:
	"""Apply a campaign action to the game state"""
	if not is_game_initialized or not simulation_api:
		return false
	
	# Process action through simulation API
	var result = simulation_api.process_campaign_action(action)
	
	if result.success:
		# Update state with results
		update_game_state(result.new_game_state, "Campaign Action: " + action.action_type)
		return result.success
	
	return false

func advance_time(days: int) -> void:
	"""Advance game time and process time-based events"""
	if not is_game_initialized or not simulation_api:
		return
	
	# Process time advancement through simulation
	var result = simulation_api.advance_time(current_game_state, days)
	
	if result.success:
		update_game_state(result.new_game_state, "Time Advanced: +" + str(days) + " days")

func _create_state_snapshot(description: String) -> void:
	"""Create a snapshot of current state for undo/redo functionality"""
	if not current_game_state:
		return
	
	var snapshot = {
		"timestamp": Time.get_unix_time_from_system(),
		"description": description,
		"state_data": current_game_state.serialize()
	}
	
	state_history.append(snapshot)
	
	# Limit history size
	if state_history.size() > max_history_entries:
		state_history.pop_front()

func can_undo() -> bool:
	"""Check if undo operation is available"""
	return state_history.size() > 1  # Need at least 2 entries (current + previous)

func undo_last_action() -> bool:
	"""Undo the last state change"""
	if not can_undo():
		return false
	
	# Remove current state
	state_history.pop_back()
	
	# Get previous state
	var previous_snapshot = state_history.back()
	if previous_snapshot:
		# Restore previous state
		current_game_state = DataModels.GameState.new()
		current_game_state.deserialize(previous_snapshot.state_data)
		
		# Update simulation API
		if simulation_api:
			simulation_api.update_game_state(current_game_state)
		
		# Emit state change
		game_state_changed.emit(current_game_state)
		
		print("GameStateManager: Undone action - ", previous_snapshot.description)
		return true
	
	return false

func get_state_history() -> Array[String]:
	"""Get list of state change descriptions for UI display"""
	var descriptions: Array[String] = []
	for snapshot in state_history:
		descriptions.append(snapshot.description)
	return descriptions

# Save/Load System
func save_game(file_path: String = SAVE_FILE_PATH, create_backup: bool = true) -> bool:
	"""Save current game state to file"""
	if not is_game_initialized or not current_game_state:
		print("Error: No game state to save")
		save_completed.emit(false, file_path)
		return false
	
	# Create backup if requested and save file exists
	if create_backup and FileAccess.file_exists(file_path):
		_create_save_backup(file_path)
	
	# Prepare save data
	var save_data = {
		"version": save_version,
		"timestamp": Time.get_unix_time_from_system(),
		"game_state": current_game_state.serialize(),
		"state_history": _serialize_state_history(),
		"metadata": _create_save_metadata()
	}
	
	# Write to file
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		print("Error: Could not open save file for writing: ", file_path)
		save_completed.emit(false, file_path)
		return false
	
	file.store_string(JSON.stringify(save_data))
	file.close()
	
	print("GameStateManager: Game saved successfully to ", file_path)
	save_completed.emit(true, file_path)
	return true

func load_game(file_path: String = SAVE_FILE_PATH) -> bool:
	"""Load game state from file"""
	if not FileAccess.file_exists(file_path):
		print("Error: Save file does not exist: ", file_path)
		load_completed.emit(false, null)
		return false
	
	# Read save file
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("Error: Could not open save file for reading: ", file_path)
		load_completed.emit(false, null)
		return false
	
	var save_data_string = file.get_as_text()
	file.close()
	
	# Parse JSON
	var json = JSON.new()
	var parse_result = json.parse(save_data_string)
	if parse_result != OK:
		print("Error: Invalid save file format")
		load_completed.emit(false, null)
		return false
	
	var save_data = json.data
	
	# Validate save version
	if not _validate_save_version(save_data.get("version", "")):
		print("Error: Incompatible save version")
		load_completed.emit(false, null)
		return false
	
	# Deserialize game state
	current_game_state = DataModels.GameState.new()
	var deserialize_success = current_game_state.deserialize(save_data.game_state)
	
	if not deserialize_success:
		print("Error: Failed to deserialize game state")
		load_completed.emit(false, null)
		return false
	
	# Restore state history
	_deserialize_state_history(save_data.get("state_history", []))
	
	# Update simulation API
	if simulation_api:
		simulation_api.update_game_state(current_game_state)
	
	# Mark as initialized
	is_game_initialized = true
	
	print("GameStateManager: Game loaded successfully from ", file_path)
	load_completed.emit(true, current_game_state)
	game_state_changed.emit(current_game_state)
	return true

func _validate_save_version(version: String) -> bool:
	"""Validate save file version compatibility"""
	# Simple version validation - could be more sophisticated
	var version_parts = version.split(".")
	var current_parts = save_version.split(".")
	
	if version_parts.size() != 3 or current_parts.size() != 3:
		return false
	
	# Major version must match
	return version_parts[0] == current_parts[0]

func _create_save_backup(original_path: String) -> void:
	"""Create backup of existing save file"""
	var dir = DirAccess.open("user://")
	if dir:
		dir.copy(original_path, BACKUP_SAVE_PATH)

func _create_save_metadata() -> Dictionary:
	"""Create metadata for save file"""
	return {
		"player_party": current_game_state.player_party.name if current_game_state.player_party else "Unknown",
		"current_date": current_game_state.current_date,
		"game_phase": current_game_state.current_phase,
		"play_time": current_game_state.total_play_time
	}

func _serialize_state_history() -> Array:
	"""Serialize state history for saving"""
	var serialized_history: Array = []
	# Only save last 10 history entries to keep save file size reasonable
	var start_index = max(0, state_history.size() - 10)
	
	for i in range(start_index, state_history.size()):
		serialized_history.append(state_history[i])
	
	return serialized_history

func _deserialize_state_history(history_data: Array) -> void:
	"""Deserialize state history from loaded data"""
	state_history.clear()
	for entry in history_data:
		state_history.append(entry)

# Auto-save functionality
func _on_auto_save_timer() -> void:
	"""Handle auto-save timer timeout"""
	if auto_save_enabled and is_game_initialized:
		auto_save_triggered.emit()
		save_game(AUTO_SAVE_PATH, false)  # Don't create backup for auto-saves

func set_auto_save_enabled(enabled: bool) -> void:
	"""Enable or disable auto-save functionality"""
	auto_save_enabled = enabled

func set_auto_save_interval(seconds: float) -> void:
	"""Set auto-save interval in seconds"""
	auto_save_interval = seconds
	# Update existing timer if present
	for child in get_children():
		if child is Timer:
			child.wait_time = auto_save_interval
			break

# Utility functions
func get_save_file_info(file_path: String) -> Dictionary:
	"""Get information about a save file without fully loading it"""
	if not FileAccess.file_exists(file_path):
		return {}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {}
	
	var save_data_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(save_data_string)
	if parse_result != OK:
		return {}
	
	var save_data = json.data
	return {
		"version": save_data.get("version", "Unknown"),
		"timestamp": save_data.get("timestamp", 0),
		"metadata": save_data.get("metadata", {})
	}

func has_auto_save() -> bool:
	"""Check if auto-save file exists"""
	return FileAccess.file_exists(AUTO_SAVE_PATH)

func has_save_file() -> bool:
	"""Check if main save file exists"""
	return FileAccess.file_exists(SAVE_FILE_PATH)

func delete_save_file(file_path: String = SAVE_FILE_PATH) -> bool:
	"""Delete a save file"""
	var dir = DirAccess.open("user://")
	if dir and FileAccess.file_exists(file_path):
		dir.remove(file_path)
		return true
	return false

func _exit_tree() -> void:
	"""Cleanup when manager is destroyed"""
	if auto_save_enabled and is_game_initialized:
		# Final auto-save on exit
		save_game(AUTO_SAVE_PATH, false)
	
	# Clear singleton reference
	# Autoload cleanup handled by Godot
