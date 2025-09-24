extends Node
class_name InputHandler

# Comprehensive keyboard shortcuts and input handling system
# Provides accessibility-compliant navigation and customizable shortcuts for the simulation

# Singleton instance
static var _instance: InputHandler

# Dependencies
var accessibility_manager: AccessibilityManager
var scene_manager: SceneManager
var event_bus: EventBus

# Input state tracking
var input_context: String = "global"  # Current input context
var is_input_enabled: bool = true
var modifiers_pressed: Dictionary = {}
var last_key_press_time: float = 0.0
var key_repeat_delay: float = 0.5
var key_repeat_rate: float = 0.1

# Shortcut definitions
class ShortcutDefinition:
	var key_combination: String  # e.g., "Ctrl+S", "F1", "Alt+Tab"
	var action: String
	var description: String
	var context: String  # "global", "dashboard", "map", etc.
	var accessibility_alternative: String  # Alternative for screen readers
	var enabled: bool
	var custom: bool  # User-customized shortcut

	func _init(key: String = "", act: String = "", desc: String = "", ctx: String = "global"):
		key_combination = key
		action = act
		description = desc
		context = ctx
		accessibility_alternative = ""
		enabled = true
		custom = false

# Input contexts and their active shortcuts
var shortcut_contexts: Dictionary = {}
var global_shortcuts: Dictionary = {}
var user_custom_shortcuts: Dictionary = {}

# Navigation state
var current_focus_element: Control = null
var focus_history: Array[Control] = []
var focus_group_stack: Array[Array] = []

# Accessibility navigation
var tab_navigation_enabled: bool = true
var spatial_navigation_enabled: bool = true
var screen_reader_shortcuts: bool = false

# Input modes
enum NavigationMode {
	TAB,        # Sequential tab navigation
	SPATIAL,    # Arrow key spatial navigation
	SHORTCUT,   # Direct keyboard shortcuts
	VOICE,      # Voice command integration (future)
	GAMEPAD     # Controller navigation (future)
}

var current_navigation_mode: NavigationMode = NavigationMode.TAB
var navigation_wrap_around: bool = true

# Constitutional transparency features
var input_logging_enabled: bool = true
var action_confirmation_required: Array[String] = [
	"trigger_election",
	"save_game",
	"load_game",
	"reset_simulation"
]

# Signals
signal shortcut_triggered(shortcut: String, action: String)
signal navigation_mode_changed(old_mode: NavigationMode, new_mode: NavigationMode)
signal focus_changed(old_element: Control, new_element: Control)
signal input_context_changed(old_context: String, new_context: String)
signal accessibility_shortcut_used(shortcut: String, description: String)

func _ready() -> void:
	# Initialize singleton
	if _instance == null:
		_instance = self
		process_mode = Node.PROCESS_MODE_ALWAYS

		# Initialize dependencies
		_initialize_dependencies()

		# Setup default shortcuts
		_setup_default_shortcuts()

		# Setup input handling
		_setup_input_handling()

		# Load user customizations
		_load_user_shortcuts()

		print("InputHandler: Comprehensive input system initialized")
	else:
		queue_free()

static func get_instance() -> InputHandler:
	"""Get singleton instance of InputHandler"""
	if _instance == null:
		# Create instance if it doesn't exist
		var scene_tree = Engine.get_main_loop() as SceneTree
		if scene_tree:
			_instance = InputHandler.new()
			scene_tree.root.add_child(_instance)
	return _instance

func _initialize_dependencies() -> void:
	"""Initialize references to required systems"""
	accessibility_manager = AccessibilityManager.get_instance()
	scene_manager = SceneManager.get_instance()
	event_bus = EventBus.get_instance()

	# Connect to accessibility changes
	if accessibility_manager:
		accessibility_manager.theme_changed.connect(_on_accessibility_theme_changed)
		accessibility_manager.text_scale_changed.connect(_on_text_scale_changed)

func _setup_default_shortcuts() -> void:
	"""Setup default keyboard shortcuts for all contexts"""

	# Global shortcuts (available everywhere)
	global_shortcuts = {
		"F1": ShortcutDefinition.new("F1", "show_help", "Show help and keyboard shortcuts", "global"),
		"F11": ShortcutDefinition.new("F11", "toggle_fullscreen", "Toggle fullscreen mode", "global"),
		"Escape": ShortcutDefinition.new("Escape", "back_or_cancel", "Go back or cancel current action", "global"),
		"Ctrl+S": ShortcutDefinition.new("Ctrl+S", "quick_save", "Quick save game state", "global"),
		"Ctrl+L": ShortcutDefinition.new("Ctrl+L", "quick_load", "Quick load last save", "global"),
		"Ctrl+Z": ShortcutDefinition.new("Ctrl+Z", "undo_action", "Undo last action", "global"),
		"Ctrl+Y": ShortcutDefinition.new("Ctrl+Y", "redo_action", "Redo action", "global"),
		"Ctrl+Q": ShortcutDefinition.new("Ctrl+Q", "quit_application", "Quit application", "global"),
		"Alt+Enter": ShortcutDefinition.new("Alt+Enter", "toggle_accessibility_mode", "Toggle accessibility features", "global"),

		# Navigation shortcuts
		"Tab": ShortcutDefinition.new("Tab", "navigate_next", "Navigate to next element", "global"),
		"Shift+Tab": ShortcutDefinition.new("Shift+Tab", "navigate_previous", "Navigate to previous element", "global"),
		"Home": ShortcutDefinition.new("Home", "navigate_first", "Navigate to first element", "global"),
		"End": ShortcutDefinition.new("End", "navigate_last", "Navigate to last element", "global"),

		# Screen reader compatibility
		"Ctrl+Alt+R": ShortcutDefinition.new("Ctrl+Alt+R", "read_current_focus", "Read current focused element", "global"),
		"Ctrl+Alt+H": ShortcutDefinition.new("Ctrl+Alt+H", "read_help_text", "Read help text for current context", "global")
	}

	# Dashboard context shortcuts
	shortcut_contexts["dashboard"] = {
		"D": ShortcutDefinition.new("D", "focus_dashboard", "Focus on dashboard view", "dashboard"),
		"1": ShortcutDefinition.new("1", "focus_approval_rating", "Focus on approval rating", "dashboard"),
		"2": ShortcutDefinition.new("2", "focus_poll_results", "Focus on poll results", "dashboard"),
		"3": ShortcutDefinition.new("3", "focus_campaign_resources", "Focus on campaign resources", "dashboard"),
		"4": ShortcutDefinition.new("4", "focus_upcoming_events", "Focus on upcoming events", "dashboard"),
		"R": ShortcutDefinition.new("R", "refresh_dashboard", "Refresh dashboard data", "dashboard"),
		"Ctrl+E": ShortcutDefinition.new("Ctrl+E", "export_dashboard", "Export dashboard as report", "dashboard")
	}

	# Map view context shortcuts
	shortcut_contexts["map"] = {
		"M": ShortcutDefinition.new("M", "focus_map", "Focus on map view", "map"),
		"Plus": ShortcutDefinition.new("Plus", "zoom_in", "Zoom in on map", "map"),
		"Minus": ShortcutDefinition.new("Minus", "zoom_out", "Zoom out on map", "map"),
		"0": ShortcutDefinition.new("0", "reset_zoom", "Reset map zoom", "map"),
		"Arrow_Up": ShortcutDefinition.new("Arrow_Up", "pan_north", "Pan map north", "map"),
		"Arrow_Down": ShortcutDefinition.new("Arrow_Down", "pan_south", "Pan map south", "map"),
		"Arrow_Left": ShortcutDefinition.new("Arrow_Left", "pan_west", "Pan map west", "map"),
		"Arrow_Right": ShortcutDefinition.new("Arrow_Right", "pan_east", "Pan map east", "map"),
		"F": ShortcutDefinition.new("F", "toggle_filters", "Toggle map filters", "map"),
		"L": ShortcutDefinition.new("L", "toggle_legend", "Toggle map legend", "map")
	}

	# Media event context shortcuts
	shortcut_contexts["media"] = {
		"Space": ShortcutDefinition.new("Space", "play_pause_media", "Play/pause media event", "media"),
		"Enter": ShortcutDefinition.new("Enter", "respond_to_event", "Respond to media event", "media"),
		"1": ShortcutDefinition.new("1", "response_option_1", "Select response option 1", "media"),
		"2": ShortcutDefinition.new("2", "response_option_2", "Select response option 2", "media"),
		"3": ShortcutDefinition.new("3", "response_option_3", "Select response option 3", "media"),
		"4": ShortcutDefinition.new("4", "response_option_4", "Select response option 4", "media"),
		"I": ShortcutDefinition.new("I", "show_event_info", "Show detailed event information", "media"),
		"H": ShortcutDefinition.new("H", "show_response_history", "Show response history", "media")
	}

	# Coalition builder context shortcuts
	shortcut_contexts["coalition"] = {
		"C": ShortcutDefinition.new("C", "focus_coalition_builder", "Focus on coalition builder", "coalition"),
		"A": ShortcutDefinition.new("A", "add_party_to_coalition", "Add selected party to coalition", "coalition"),
		"R": ShortcutDefinition.new("R", "remove_party_from_coalition", "Remove selected party from coalition", "coalition"),
		"Enter": ShortcutDefinition.new("Enter", "finalize_coalition", "Finalize coalition agreement", "coalition"),
		"Delete": ShortcutDefinition.new("Delete", "clear_coalition", "Clear current coalition", "coalition"),
		"S": ShortcutDefinition.new("S", "show_coalition_stats", "Show coalition statistics", "coalition"),
		"N": ShortcutDefinition.new("N", "negotiate_policy", "Negotiate policy agreement", "coalition")
	}

	# Settings context shortcuts
	shortcut_contexts["settings"] = {
		"G": ShortcutDefinition.new("G", "general_settings", "General settings", "settings"),
		"A": ShortcutDefinition.new("A", "accessibility_settings", "Accessibility settings", "settings"),
		"K": ShortcutDefinition.new("K", "keyboard_shortcuts", "Keyboard shortcuts settings", "settings"),
		"L": ShortcutDefinition.new("L", "language_settings", "Language settings", "settings"),
		"P": ShortcutDefinition.new("P", "performance_settings", "Performance settings", "settings"),
		"Enter": ShortcutDefinition.new("Enter", "apply_settings", "Apply current settings", "settings"),
		"Ctrl+R": ShortcutDefinition.new("Ctrl+R", "reset_to_defaults", "Reset to default settings", "settings")
	}

func _setup_input_handling() -> void:
	"""Setup input event handling"""
	# Ensure we receive input events
	set_process_input(true)
	set_process_unhandled_input(true)

# Input event processing
func _input(event: InputEvent) -> void:
	"""Handle input events with accessibility and shortcuts"""
	if not is_input_enabled:
		return

	# Handle modifier key tracking
	if event is InputEventKey:
		_track_modifier_keys(event)

	# Handle shortcuts
	if event is InputEventKey and event.pressed:
		var shortcut_string = _event_to_shortcut_string(event)
		if _handle_shortcut(shortcut_string):
			get_viewport().set_input_as_handled()
			return

	# Handle navigation
	if event is InputEventKey and event.pressed:
		if _handle_navigation_input(event):
			get_viewport().set_input_as_handled()
			return

func _unhandled_input(event: InputEvent) -> void:
	"""Handle unhandled input for global shortcuts"""
	if not is_input_enabled:
		return

	# Try global shortcuts on unhandled input
	if event is InputEventKey and event.pressed:
		var shortcut_string = _event_to_shortcut_string(event)
		if global_shortcuts.has(shortcut_string):
			_execute_shortcut_action(global_shortcuts[shortcut_string])
			get_viewport().set_input_as_handled()

func _track_modifier_keys(event: InputEventKey) -> void:
	"""Track modifier key states for complex shortcuts"""
	match event.keycode:
		KEY_CTRL:
			modifiers_pressed["ctrl"] = event.pressed
		KEY_ALT:
			modifiers_pressed["alt"] = event.pressed
		KEY_SHIFT:
			modifiers_pressed["shift"] = event.pressed
		KEY_META:  # Windows/Cmd key
			modifiers_pressed["meta"] = event.pressed

func _event_to_shortcut_string(event: InputEventKey) -> String:
	"""Convert input event to shortcut string representation"""
	var parts: Array[String] = []

	# Add modifiers
	if event.ctrl_pressed or modifiers_pressed.get("ctrl", false):
		parts.append("Ctrl")
	if event.alt_pressed or modifiers_pressed.get("alt", false):
		parts.append("Alt")
	if event.shift_pressed or modifiers_pressed.get("shift", false):
		parts.append("Shift")
	if event.meta_pressed or modifiers_pressed.get("meta", false):
		parts.append("Meta")

	# Add main key
	var key_name = _keycode_to_string(event.keycode)
	parts.append(key_name)

	return "+".join(parts)

func _keycode_to_string(keycode: int) -> String:
	"""Convert keycode to readable string"""
	match keycode:
		KEY_SPACE: return "Space"
		KEY_ENTER: return "Enter"
		KEY_TAB: return "Tab"
		KEY_ESCAPE: return "Escape"
		KEY_HOME: return "Home"
		KEY_END: return "End"
		KEY_PAGEUP: return "PageUp"
		KEY_PAGEDOWN: return "PageDown"
		KEY_DELETE: return "Delete"
		KEY_BACKSPACE: return "Backspace"
		KEY_UP: return "Arrow_Up"
		KEY_DOWN: return "Arrow_Down"
		KEY_LEFT: return "Arrow_Left"
		KEY_RIGHT: return "Arrow_Right"
		KEY_F1: return "F1"
		KEY_F2: return "F2"
		KEY_F3: return "F3"
		KEY_F4: return "F4"
		KEY_F5: return "F5"
		KEY_F6: return "F6"
		KEY_F7: return "F7"
		KEY_F8: return "F8"
		KEY_F9: return "F9"
		KEY_F10: return "F10"
		KEY_F11: return "F11"
		KEY_F12: return "F12"
		KEY_EQUAL: return "Plus"
		KEY_MINUS: return "Minus"
		_:
			# Convert printable characters
			if keycode >= KEY_A and keycode <= KEY_Z:
				return char(keycode)
			elif keycode >= KEY_0 and keycode <= KEY_9:
				return char(keycode)
			else:
				return "Key" + str(keycode)

# Shortcut handling
func _handle_shortcut(shortcut_string: String) -> bool:
	"""Handle shortcut execution"""
	var shortcut_def: ShortcutDefinition = null

	# Check context-specific shortcuts first
	var context_shortcuts = shortcut_contexts.get(input_context, {})
	if context_shortcuts.has(shortcut_string):
		shortcut_def = context_shortcuts[shortcut_string]

	# Check global shortcuts
	if not shortcut_def and global_shortcuts.has(shortcut_string):
		shortcut_def = global_shortcuts[shortcut_string]

	# Check user custom shortcuts
	if not shortcut_def and user_custom_shortcuts.has(shortcut_string):
		shortcut_def = user_custom_shortcuts[shortcut_string]

	if shortcut_def and shortcut_def.enabled:
		_execute_shortcut_action(shortcut_def)
		return true

	return false

func _execute_shortcut_action(shortcut_def: ShortcutDefinition) -> void:
	"""Execute the action for a shortcut"""
	var action = shortcut_def.action

	# Log action for constitutional transparency
	if input_logging_enabled:
		_log_input_action(shortcut_def)

	# Check if action requires confirmation
	if action in action_confirmation_required:
		_request_action_confirmation(shortcut_def)
		return

	# Execute action
	_perform_shortcut_action(action, shortcut_def)

	# Emit signals
	shortcut_triggered.emit(shortcut_def.key_combination, action)

	# Accessibility feedback
	if screen_reader_shortcuts and not shortcut_def.accessibility_alternative.is_empty():
		accessibility_shortcut_used.emit(shortcut_def.key_combination, shortcut_def.accessibility_alternative)

func _perform_shortcut_action(action: String, shortcut_def: ShortcutDefinition) -> void:
	"""Perform the actual shortcut action"""
	match action:
		# Global actions
		"show_help":
			_show_keyboard_help()
		"toggle_fullscreen":
			_toggle_fullscreen()
		"back_or_cancel":
			_handle_back_or_cancel()
		"quick_save":
			_trigger_quick_save()
		"quick_load":
			_trigger_quick_load()
		"undo_action":
			_trigger_undo()
		"redo_action":
			_trigger_redo()
		"quit_application":
			_request_quit_confirmation()
		"toggle_accessibility_mode":
			_toggle_accessibility_mode()

		# Navigation actions
		"navigate_next":
			_navigate_next_element()
		"navigate_previous":
			_navigate_previous_element()
		"navigate_first":
			_navigate_first_element()
		"navigate_last":
			_navigate_last_element()
		"read_current_focus":
			_read_current_focus()
		"read_help_text":
			_read_help_text()

		# Context-specific actions
		_:
			# Delegate to context-specific handlers or event bus
			_handle_context_specific_action(action, shortcut_def)

func _handle_context_specific_action(action: String, shortcut_def: ShortcutDefinition) -> void:
	"""Handle context-specific actions through event bus"""
	if event_bus:
		event_bus.publish(EventBus.SHORTCUT_TRIGGERED, {
			"action": action,
			"context": input_context,
			"shortcut": shortcut_def.key_combination,
			"description": shortcut_def.description
		}, EventBus.EventCategory.INPUT)

# Navigation system
func _handle_navigation_input(event: InputEventKey) -> bool:
	"""Handle keyboard navigation input"""
	match current_navigation_mode:
		NavigationMode.TAB:
			return _handle_tab_navigation(event)
		NavigationMode.SPATIAL:
			return _handle_spatial_navigation(event)
		NavigationMode.SHORTCUT:
			return false  # Handled by shortcut system
		_:
			return false

func _handle_tab_navigation(event: InputEventKey) -> bool:
	"""Handle tab-based sequential navigation"""
	if not tab_navigation_enabled:
		return false

	match event.keycode:
		KEY_TAB:
			if event.shift_pressed:
				_navigate_previous_element()
			else:
				_navigate_next_element()
			return true
		KEY_HOME:
			_navigate_first_element()
			return true
		KEY_END:
			_navigate_last_element()
			return true

	return false

func _handle_spatial_navigation(event: InputEventKey) -> bool:
	"""Handle spatial arrow key navigation"""
	if not spatial_navigation_enabled:
		return false

	match event.keycode:
		KEY_UP:
			_navigate_spatial_direction(Vector2.UP)
			return true
		KEY_DOWN:
			_navigate_spatial_direction(Vector2.DOWN)
			return true
		KEY_LEFT:
			_navigate_spatial_direction(Vector2.LEFT)
			return true
		KEY_RIGHT:
			_navigate_spatial_direction(Vector2.RIGHT)
			return true

	return false

func _navigate_next_element() -> void:
	"""Navigate to next focusable element"""
	var focusables = _get_focusable_elements()
	if focusables.is_empty():
		return

	var current_index = focusables.find(current_focus_element)
	var next_index = (current_index + 1) % focusables.size() if navigation_wrap_around else min(current_index + 1, focusables.size() - 1)

	_set_focus_element(focusables[next_index])

func _navigate_previous_element() -> void:
	"""Navigate to previous focusable element"""
	var focusables = _get_focusable_elements()
	if focusables.is_empty():
		return

	var current_index = focusables.find(current_focus_element)
	var prev_index = (current_index - 1 + focusables.size()) % focusables.size() if navigation_wrap_around else max(current_index - 1, 0)

	_set_focus_element(focusables[prev_index])

func _navigate_first_element() -> void:
	"""Navigate to first focusable element"""
	var focusables = _get_focusable_elements()
	if not focusables.is_empty():
		_set_focus_element(focusables[0])

func _navigate_last_element() -> void:
	"""Navigate to last focusable element"""
	var focusables = _get_focusable_elements()
	if not focusables.is_empty():
		_set_focus_element(focusables[-1])

func _navigate_spatial_direction(direction: Vector2) -> void:
	"""Navigate in spatial direction"""
	if not current_focus_element:
		_navigate_first_element()
		return

	var current_pos = current_focus_element.global_position + current_focus_element.size / 2
	var focusables = _get_focusable_elements()
	var best_element: Control = null
	var best_distance = INF

	for element in focusables:
		if element == current_focus_element:
			continue

		var element_pos = element.global_position + element.size / 2
		var offset = element_pos - current_pos

		# Check if element is in the desired direction
		if direction.dot(offset.normalized()) < 0.7:  # ~45 degree tolerance
			continue

		var distance = offset.length()
		if distance < best_distance:
			best_distance = distance
			best_element = element

	if best_element:
		_set_focus_element(best_element)

func _get_focusable_elements() -> Array[Control]:
	"""Get all focusable elements in current scene"""
	var focusables: Array[Control] = []
	var scene = get_tree().current_scene

	if scene:
		_collect_focusable_recursive(scene, focusables)

	# Sort by tab order or position
	focusables.sort_custom(_compare_focus_order)

	return focusables

func _collect_focusable_recursive(node: Node, focusables: Array[Control]) -> void:
	"""Recursively collect focusable controls"""
	if node is Control:
		var control = node as Control
		if control.visible and not control.disabled and control.focus_mode != Control.FOCUS_NONE:
			focusables.append(control)

	for child in node.get_children():
		_collect_focusable_recursive(child, focusables)

func _compare_focus_order(a: Control, b: Control) -> bool:
	"""Compare controls for focus order (top-left to bottom-right)"""
	# First by Y position (top to bottom)
	if abs(a.global_position.y - b.global_position.y) > 20:  # 20px threshold for same "row"
		return a.global_position.y < b.global_position.y

	# Then by X position (left to right)
	return a.global_position.x < b.global_position.x

func _set_focus_element(element: Control) -> void:
	"""Set focus to specific element with accessibility feedback"""
	if element == current_focus_element:
		return

	var old_element = current_focus_element

	# Update focus history
	if current_focus_element and focus_history.find(current_focus_element) == -1:
		focus_history.append(current_focus_element)
		if focus_history.size() > 10:  # Limit history size
			focus_history.pop_front()

	# Set new focus
	current_focus_element = element
	element.grab_focus()

	# Emit signal
	focus_changed.emit(old_element, element)

	# Accessibility feedback
	if accessibility_manager:
		accessibility_manager.announce_focus_change(element)

# Global action handlers
func _show_keyboard_help() -> void:
	"""Show keyboard shortcuts help dialog"""
	# Would create and show help dialog
	print("InputHandler: Keyboard shortcuts help requested")

func _toggle_fullscreen() -> void:
	"""Toggle fullscreen mode"""
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _handle_back_or_cancel() -> void:
	"""Handle back/cancel action contextually"""
	if scene_manager:
		# Navigate back in history or close dialogs
		print("InputHandler: Back/cancel action")

func _trigger_quick_save() -> void:
	"""Trigger quick save"""
	if event_bus:
		event_bus.publish(EventBus.SAVE_REQUESTED, {"type": "quick_save"}, EventBus.EventCategory.GAME)

func _trigger_quick_load() -> void:
	"""Trigger quick load"""
	if event_bus:
		event_bus.publish(EventBus.LOAD_REQUESTED, {"type": "quick_load"}, EventBus.EventCategory.GAME)

func _trigger_undo() -> void:
	"""Trigger undo action"""
	if event_bus:
		event_bus.publish(EventBus.UNDO_REQUESTED, {}, EventBus.EventCategory.GAME)

func _trigger_redo() -> void:
	"""Trigger redo action"""
	if event_bus:
		event_bus.publish(EventBus.REDO_REQUESTED, {}, EventBus.EventCategory.GAME)

func _request_quit_confirmation() -> void:
	"""Request quit confirmation"""
	if event_bus:
		event_bus.publish(EventBus.QUIT_REQUESTED, {}, EventBus.EventCategory.SYSTEM)

func _toggle_accessibility_mode() -> void:
	"""Toggle accessibility features"""
	if accessibility_manager:
		accessibility_manager.toggle_enhanced_mode()

func _read_current_focus() -> void:
	"""Read current focus for screen readers"""
	if current_focus_element and accessibility_manager:
		accessibility_manager.read_element(current_focus_element)

func _read_help_text() -> void:
	"""Read help text for current context"""
	if accessibility_manager:
		accessibility_manager.read_context_help(input_context)

# Context management
func set_input_context(context: String) -> void:
	"""Change input context for context-specific shortcuts"""
	var old_context = input_context
	input_context = context

	input_context_changed.emit(old_context, context)

	print("InputHandler: Context changed to: ", context)

func get_available_shortcuts(context: String = "") -> Dictionary:
	"""Get available shortcuts for context"""
	var ctx = context if not context.is_empty() else input_context
	var shortcuts = {}

	# Add global shortcuts
	for key in global_shortcuts.keys():
		shortcuts[key] = global_shortcuts[key]

	# Add context shortcuts
	var context_shortcuts = shortcut_contexts.get(ctx, {})
	for key in context_shortcuts.keys():
		shortcuts[key] = context_shortcuts[key]

	# Add custom shortcuts
	for key in user_custom_shortcuts.keys():
		var custom_shortcut = user_custom_shortcuts[key]
		if custom_shortcut.context == "global" or custom_shortcut.context == ctx:
			shortcuts[key] = custom_shortcut

	return shortcuts

# Customization
func add_custom_shortcut(key_combination: String, action: String, description: String, context: String = "global") -> bool:
	"""Add user-defined custom shortcut"""
	# Validate key combination doesn't conflict
	if global_shortcuts.has(key_combination) or shortcut_contexts.get(context, {}).has(key_combination):
		return false  # Conflict with existing shortcut

	var shortcut = ShortcutDefinition.new(key_combination, action, description, context)
	shortcut.custom = true
	user_custom_shortcuts[key_combination] = shortcut

	_save_user_shortcuts()
	return true

func remove_custom_shortcut(key_combination: String) -> bool:
	"""Remove user-defined shortcut"""
	if user_custom_shortcuts.has(key_combination):
		user_custom_shortcuts.erase(key_combination)
		_save_user_shortcuts()
		return true
	return false

func _save_user_shortcuts() -> void:
	"""Save user customizations to file"""
	var file = FileAccess.open("user://input_shortcuts.json", FileAccess.WRITE)
	if file:
		var data = {}
		for key in user_custom_shortcuts.keys():
			var shortcut = user_custom_shortcuts[key]
			data[key] = {
				"action": shortcut.action,
				"description": shortcut.description,
				"context": shortcut.context,
				"enabled": shortcut.enabled
			}

		file.store_string(JSON.stringify(data))
		file.close()

func _load_user_shortcuts() -> void:
	"""Load user customizations from file"""
	var file = FileAccess.open("user://input_shortcuts.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()

		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			var data = json.data
			for key in data.keys():
				var shortcut_data = data[key]
				var shortcut = ShortcutDefinition.new(
					key,
					shortcut_data.action,
					shortcut_data.description,
					shortcut_data.context
				)
				shortcut.custom = true
				shortcut.enabled = shortcut_data.get("enabled", true)
				user_custom_shortcuts[key] = shortcut

# Accessibility integration
func _on_accessibility_theme_changed(theme_name: String) -> void:
	"""Handle accessibility theme changes"""
	if theme_name == "high_contrast":
		screen_reader_shortcuts = true
	else:
		screen_reader_shortcuts = false

func _on_text_scale_changed(scale: float) -> void:
	"""Handle text scale changes"""
	# Adjust navigation timing for larger text
	if scale > 1.2:
		key_repeat_delay = 0.7
		key_repeat_rate = 0.15
	else:
		key_repeat_delay = 0.5
		key_repeat_rate = 0.1

# Constitutional transparency
func _log_input_action(shortcut_def: ShortcutDefinition) -> void:
	"""Log input actions for transparency"""
	if event_bus:
		event_bus.publish(EventBus.INPUT_ACTION_LOGGED, {
			"shortcut": shortcut_def.key_combination,
			"action": shortcut_def.action,
			"context": input_context,
			"timestamp": Time.get_unix_time_from_system()
		}, EventBus.EventCategory.AUDIT)

func _request_action_confirmation(shortcut_def: ShortcutDefinition) -> void:
	"""Request confirmation for sensitive actions"""
	if event_bus:
		event_bus.publish(EventBus.ACTION_CONFIRMATION_REQUESTED, {
			"action": shortcut_def.action,
			"description": shortcut_def.description,
			"shortcut": shortcut_def.key_combination
		}, EventBus.EventCategory.UI)

# Public API
func enable_input() -> void:
	"""Enable input processing"""
	is_input_enabled = true

func disable_input() -> void:
	"""Disable input processing"""
	is_input_enabled = false

func set_navigation_mode(mode: NavigationMode) -> void:
	"""Set navigation mode"""
	var old_mode = current_navigation_mode
	current_navigation_mode = mode
	navigation_mode_changed.emit(old_mode, mode)

func get_input_status() -> Dictionary:
	"""Get comprehensive input system status"""
	return {
		"input_enabled": is_input_enabled,
		"current_context": input_context,
		"navigation_mode": current_navigation_mode,
		"current_focus": current_focus_element.get_path() if current_focus_element else "",
		"available_shortcuts": get_available_shortcuts().keys().size(),
		"custom_shortcuts": user_custom_shortcuts.size()
	}

# Debug functionality
func print_input_debug() -> void:
	"""Print debug information about input system"""
	print("=== InputHandler Debug ===")
	print("Input enabled: ", is_input_enabled)
	print("Context: ", input_context)
	print("Navigation mode: ", current_navigation_mode)
	print("Current focus: ", current_focus_element.get_path() if current_focus_element else "None")
	print("Available shortcuts: ", get_available_shortcuts().keys().size())
	print("Custom shortcuts: ", user_custom_shortcuts.size())
	print("==========================")

# Cleanup
func _exit_tree() -> void:
	"""Cleanup when manager is destroyed"""
	# Save any unsaved customizations
	_save_user_shortcuts()

	# Clear focus references
	current_focus_element = null
	focus_history.clear()

	# Clear singleton reference
	if _instance == self:
		_instance = null

	print("InputHandler: Cleaned up")