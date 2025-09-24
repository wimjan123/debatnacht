extends Node
class_name UIStateManager

# UI-specific state management
# Handles screen-specific state, UI preferences, navigation history

# Singleton instance
static var _instance: UIStateManager

# UI State
var current_screen: String = ""
var navigation_history: Array[String] = []
var screen_states: Dictionary = {}  # Screen name -> state data
var ui_preferences: Dictionary = {}
var modal_stack: Array[String] = []  # Track open modals/dialogs

# Navigation constants
const MAX_HISTORY_SIZE: int = 20
const MAIN_MENU_SCREEN: String = "MainMenu"
const DASHBOARD_SCREEN: String = "Dashboard"

# UI State signals
signal screen_changed(old_screen: String, new_screen: String)
signal screen_state_saved(screen_name: String, state_data: Dictionary)
signal modal_opened(modal_name: String)
signal modal_closed(modal_name: String)
signal ui_preferences_changed(preferences: Dictionary)

func _ready() -> void:
	# Initialize singleton
	if _instance == null:
		_instance = self
		process_mode = Node.PROCESS_MODE_ALWAYS
		
		# Load UI preferences
		_load_ui_preferences()
		
		# Initialize with main menu
		current_screen = MAIN_MENU_SCREEN
	else:
		queue_free()

static func get_instance() -> UIStateManager:
	"""Get singleton instance of UIStateManager"""
	if _instance == null:
		# Create instance if it doesn't exist
		var scene_tree = Engine.get_main_loop() as SceneTree
		if scene_tree:
			_instance = UIStateManager.new()
			scene_tree.root.add_child(_instance)
	return _instance

# Screen Management
func navigate_to_screen(screen_name: String, save_current_state: bool = true) -> void:
	"""Navigate to a new screen with optional state preservation"""
	var old_screen = current_screen
	
	# Save current screen state if requested
	if save_current_state and not current_screen.is_empty():
		_auto_save_current_screen_state()
	
	# Update navigation history
	_add_to_navigation_history(current_screen)
	
	# Change screen
	current_screen = screen_name
	
	# Emit signal
	screen_changed.emit(old_screen, screen_name)
	
	print("UIStateManager: Navigated from ", old_screen, " to ", screen_name)

func get_current_screen() -> String:
	"""Get current screen name"""
	return current_screen

func can_go_back() -> bool:
	"""Check if navigation back is possible"""
	return navigation_history.size() > 0

func go_back() -> String:
	"""Navigate back to previous screen"""
	if not can_go_back():
		return current_screen
	
	var previous_screen = navigation_history.pop_back()
	navigate_to_screen(previous_screen, true)
	return previous_screen

func clear_navigation_history() -> void:
	"""Clear navigation history (useful for major state changes)"""
	navigation_history.clear()

func get_navigation_history() -> Array[String]:
	"""Get copy of navigation history"""
	return navigation_history.duplicate()

func _add_to_navigation_history(screen_name: String) -> void:
	"""Add screen to navigation history with size limit"""
	if not screen_name.is_empty():
		navigation_history.append(screen_name)
		
		# Limit history size
		if navigation_history.size() > MAX_HISTORY_SIZE:
			navigation_history.pop_front()

# Screen State Management
func save_screen_state(screen_name: String, state_data: Dictionary) -> void:
	"""Save state data for a specific screen"""
	screen_states[screen_name] = state_data.duplicate(true)
	screen_state_saved.emit(screen_name, state_data)
	
	print("UIStateManager: Saved state for screen: ", screen_name)

func get_screen_state(screen_name: String) -> Dictionary:
	"""Get saved state data for a screen"""
	return screen_states.get(screen_name, {})

func has_screen_state(screen_name: String) -> bool:
	"""Check if screen has saved state"""
	return screen_states.has(screen_name)

func clear_screen_state(screen_name: String) -> void:
	"""Clear saved state for a screen"""
	if screen_states.has(screen_name):
		screen_states.erase(screen_name)

func clear_all_screen_states() -> void:
	"""Clear all saved screen states"""
	screen_states.clear()

func _auto_save_current_screen_state() -> void:
	"""Automatically save current screen state (override in screen controllers)"""
	# This is a placeholder - individual screens should override this behavior
	# by connecting to the screen_changed signal and saving their own state
	pass

# Modal Management
func open_modal(modal_name: String) -> void:
	"""Register a modal as opened"""
	modal_stack.append(modal_name)
	modal_opened.emit(modal_name)
	
	print("UIStateManager: Modal opened: ", modal_name)

func close_modal(modal_name: String) -> void:
	"""Register a modal as closed"""
	var index = modal_stack.find(modal_name)
	if index >= 0:
		modal_stack.remove_at(index)
		modal_closed.emit(modal_name)
		
		print("UIStateManager: Modal closed: ", modal_name)

func close_top_modal() -> String:
	"""Close the topmost modal"""
	if modal_stack.size() > 0:
		var modal_name = modal_stack.pop_back()
		modal_closed.emit(modal_name)
		return modal_name
	return ""

func get_top_modal() -> String:
	"""Get the name of the topmost modal"""
	if modal_stack.size() > 0:
		return modal_stack.back()
	return ""

func has_open_modals() -> bool:
	"""Check if any modals are currently open"""
	return modal_stack.size() > 0

func clear_all_modals() -> void:
	"""Clear all open modals (emergency close)"""
	for modal_name in modal_stack:
		modal_closed.emit(modal_name)
	modal_stack.clear()

# UI Preferences Management
func set_ui_preference(key: String, value) -> void:
	"""Set a UI preference value"""
	ui_preferences[key] = value
	_save_ui_preferences()
	ui_preferences_changed.emit(ui_preferences)

func get_ui_preference(key: String, default_value = null):
	"""Get a UI preference value"""
	return ui_preferences.get(key, default_value)

func has_ui_preference(key: String) -> bool:
	"""Check if UI preference exists"""
	return ui_preferences.has(key)

func remove_ui_preference(key: String) -> void:
	"""Remove a UI preference"""
	if ui_preferences.has(key):
		ui_preferences.erase(key)
		_save_ui_preferences()
		ui_preferences_changed.emit(ui_preferences)

func get_all_ui_preferences() -> Dictionary:
	"""Get all UI preferences"""
	return ui_preferences.duplicate(true)

func set_multiple_preferences(preferences: Dictionary) -> void:
	"""Set multiple UI preferences at once"""
	for key in preferences.keys():
		ui_preferences[key] = preferences[key]
	
	_save_ui_preferences()
	ui_preferences_changed.emit(ui_preferences)

# Specific UI State Helpers
func save_dashboard_state(kpi_selections: Array, filter_settings: Dictionary, view_mode: String) -> void:
	"""Save dashboard-specific state"""
	var dashboard_state = {
		"kpi_selections": kpi_selections,
		"filter_settings": filter_settings,
		"view_mode": view_mode,
		"timestamp": Time.get_unix_time_from_system()
	}
	save_screen_state(DASHBOARD_SCREEN, dashboard_state)

func get_dashboard_state() -> Dictionary:
	"""Get dashboard-specific state"""
	return get_screen_state(DASHBOARD_SCREEN)

func save_map_view_state(selected_region: String, zoom_level: float, filter_mode: String) -> void:
	"""Save map view specific state"""
	var map_state = {
		"selected_region": selected_region,
		"zoom_level": zoom_level,
		"filter_mode": filter_mode,
		"timestamp": Time.get_unix_time_from_system()
	}
	save_screen_state("MapView", map_state)

func save_coalition_builder_state(selected_parties: Array, negotiations: Dictionary) -> void:
	"""Save coalition builder specific state"""
	var coalition_state = {
		"selected_parties": selected_parties,
		"negotiations": negotiations,
		"timestamp": Time.get_unix_time_from_system()
	}
	save_screen_state("CoalitionBuilder", coalition_state)

func save_media_event_state(current_event: Dictionary, response_history: Array) -> void:
	"""Save media event specific state"""
	var media_state = {
		"current_event": current_event,
		"response_history": response_history,
		"timestamp": Time.get_unix_time_from_system()
	}
	save_screen_state("MediaEvent", media_state)

# Persistence
const UI_PREFERENCES_FILE: String = "user://ui_preferences.json"

func _save_ui_preferences() -> void:
	"""Save UI preferences to file"""
	var file = FileAccess.open(UI_PREFERENCES_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(ui_preferences))
		file.close()

func _load_ui_preferences() -> void:
	"""Load UI preferences from file"""
	if not FileAccess.file_exists(UI_PREFERENCES_FILE):
		# Initialize with defaults
		ui_preferences = _get_default_ui_preferences()
		return
	
	var file = FileAccess.open(UI_PREFERENCES_FILE, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			ui_preferences = json.data
		else:
			ui_preferences = _get_default_ui_preferences()
	else:
		ui_preferences = _get_default_ui_preferences()

func _get_default_ui_preferences() -> Dictionary:
	"""Get default UI preferences"""
	return {
		# Dashboard preferences
		"dashboard_default_view": "overview",
		"dashboard_auto_refresh": true,
		"dashboard_refresh_interval": 30,
		
		# Map view preferences
		"map_default_zoom": 1.0,
		"map_show_tooltips": true,
		"map_animation_speed": "normal",
		
		# Coalition builder preferences
		"coalition_show_compatibility": true,
		"coalition_auto_validate": true,
		
		# Media event preferences
		"media_show_sentiment": true,
		"media_auto_play_events": false,
		
		# Navigation preferences
		"navigation_remember_state": true,
		"navigation_confirm_exits": true,
		
		# Accessibility preferences
		"ui_reduce_motion": false,
		"ui_high_contrast": false,
		"ui_large_text": false,
		"ui_screen_reader_mode": false
	}

# Screen-specific utility functions
func is_on_main_screen() -> bool:
	"""Check if currently on main menu screen"""
	return current_screen == MAIN_MENU_SCREEN

func is_on_dashboard() -> bool:
	"""Check if currently on dashboard screen"""
	return current_screen == DASHBOARD_SCREEN

func is_in_game() -> bool:
	"""Check if currently in a game (not on main menu)"""
	return current_screen != MAIN_MENU_SCREEN and not current_screen.is_empty()

# State validation and cleanup
func validate_screen_state(screen_name: String) -> bool:
	"""Validate that screen state is still valid"""
	var state = get_screen_state(screen_name)
	if state.is_empty():
		return true  # Empty state is always valid
	
	# Check timestamp - states older than 1 hour might be stale
	var current_time = Time.get_unix_time_from_system()
	var state_time = state.get("timestamp", 0)
	var age_seconds = current_time - state_time
	
	# Consider states older than 1 hour as potentially stale
	return age_seconds < 3600

func cleanup_stale_states() -> void:
	"""Remove stale screen states"""
	var screens_to_remove: Array[String] = []
	
	for screen_name in screen_states.keys():
		if not validate_screen_state(screen_name):
			screens_to_remove.append(screen_name)
	
	for screen_name in screens_to_remove:
		clear_screen_state(screen_name)
		print("UIStateManager: Cleaned stale state for: ", screen_name)

# Debug and utility functions
func get_state_summary() -> Dictionary:
	"""Get summary of current UI state for debugging"""
	return {
		"current_screen": current_screen,
		"navigation_history_size": navigation_history.size(),
		"saved_screen_states": screen_states.keys(),
		"open_modals": modal_stack,
		"preferences_count": ui_preferences.size()
	}

func print_state_debug() -> void:
	"""Print debug information about current state"""
	print("=== UIStateManager Debug ===")
	print("Current Screen: ", current_screen)
	print("Navigation History: ", navigation_history)
	print("Screen States: ", screen_states.keys())
	print("Open Modals: ", modal_stack)
	print("Preferences: ", ui_preferences.keys())
	print("===========================")

# Cleanup
func _exit_tree() -> void:
	"""Cleanup when manager is destroyed"""
	# Save current preferences
	_save_ui_preferences()
	
	# Clear singleton reference
	if _instance == self:
		_instance = null
