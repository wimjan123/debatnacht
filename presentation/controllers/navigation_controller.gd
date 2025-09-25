extends Control
class_name NavigationController

# Navigation controller for screen transitions and state management
# Handles routing between main game screens with accessibility support

var current_screen: String = "main_menu"
var screen_history: Array[String] = []
var screen_states: Dictionary = {}
var transition_data: Dictionary = {}

# Screen scene paths
var screen_scenes: Dictionary = {
	"main_menu": "res://ui/scenes/main_menu/MainMenu.tscn",
	"dashboard": "res://ui/scenes/dashboard/Dashboard.tscn",
	"map": "res://ui/scenes/map_view/MapView.tscn",
	"media": "res://ui/scenes/media_events/DataModels.MediaEvent.tscn",
	"coalition": "res://ui/scenes/coalition_builder/CoalitionBuilder.tscn",
	"parliament": "res://ui/scenes/parliament/ParliamentView.tscn",
	"social": "res://ui/scenes/social_media/SocialMediaConsole.tscn",
	"results": "res://ui/scenes/results/DataModels.ElectionResults.tscn",
	"settings": "res://ui/scenes/settings/Settings.tscn"
}

# Screen accessibility requirements
var screen_accessibility: Dictionary = {
	"main_menu": true,
	"dashboard": true,
	"map": true,
	"media": true,
	"coalition": false,  # Unlocked when coalition phase begins
	"parliament": false,  # Unlocked when parliament phase begins
	"social": true,
	"results": false,  # Unlocked when election completes
	"settings": true
}

signal screen_changed(from_screen: String, to_screen: String)
signal transition_started(screen_name: String)
signal transition_completed(screen_name: String)
signal navigation_blocked(screen_name: String, reason: String)

func _ready():
	# Initialize default screen states
	for screen in screen_scenes.keys():
		screen_states[screen] = screen_accessibility.get(screen, false)

func navigate_to_screen(screen_name: String, transition_data_param: Dictionary = {}) -> void:
	"""Switch to specified main screen"""
	# Validate screen name
	if not screen_scenes.has(screen_name):
		push_error("Unknown screen: " + screen_name)
		navigation_blocked.emit(screen_name, "unknown_screen")
		return

	# Check if screen is accessible
	if not screen_states.get(screen_name, false):
		var reason = tr("navigation.screen_locked") % tr("screen." + screen_name)
		navigation_blocked.emit(screen_name, reason)
		return

	# Store transition data
	transition_data = transition_data_param

	# Add current screen to history (for back navigation)
	if current_screen != "" and current_screen != screen_name:
		screen_history.append(current_screen)
		# Limit history size
		if screen_history.size() > 10:
			screen_history.pop_front()

	var from_screen = current_screen
	current_screen = screen_name

	transition_started.emit(screen_name)

	# Perform transition
	await _perform_screen_transition(from_screen, screen_name)

	transition_completed.emit(screen_name)
	screen_changed.emit(from_screen, screen_name)

func update_screen_accessibility(screen_states_param: Dictionary) -> void:
	"""Update screen accessibility (disable/enable screen access)"""
	for screen_name in screen_states_param.keys():
		if screen_scenes.has(screen_name):
			screen_states[screen_name] = screen_states_param[screen_name]

func navigate_back() -> bool:
	"""Handle back navigation with undo support where applicable"""
	if screen_history.is_empty():
		return false

	var previous_screen = screen_history.pop_back()

	# Check if previous screen is still accessible
	if not screen_states.get(previous_screen, false):
		# Try next screen in history
		return navigate_back()

	await navigate_to_screen(previous_screen)
	return true

func get_current_screen() -> String:
	"""Get current active screen name"""
	return current_screen

func get_screen_title(screen_name: String) -> String:
	"""Get localized screen title"""
	return tr("screen.title." + screen_name)

func get_screen_description(screen_name: String) -> String:
	"""Get localized screen description for accessibility"""
	return tr("screen.description." + screen_name)

func is_screen_accessible(screen_name: String) -> bool:
	"""Check if screen is currently accessible"""
	return screen_states.get(screen_name, false)

func get_accessible_screens() -> Array[String]:
	"""Get list of currently accessible screens"""
	var accessible = []
	for screen in screen_states.keys():
		if screen_states[screen]:
			accessible.append(screen)
	return accessible

func set_game_phase(phase: String) -> void:
	"""Update screen accessibility based on game phase"""
	match phase:
		"campaign":
			screen_states["coalition"] = false
			screen_states["parliament"] = false
			screen_states["results"] = false
		"election":
			screen_states["dashboard"] = false  # No more campaign actions
			screen_states["media"] = false
			screen_states["results"] = true
		"coalition":
			screen_states["coalition"] = true
			screen_states["dashboard"] = false
		"parliament":
			screen_states["parliament"] = true
			screen_states["coalition"] = false
		_:
			push_warning("Unknown game phase: " + phase)

func create_navigation_menu() -> Control:
	"""Create accessible navigation menu"""
	var menu = VBoxContainer.new()

	# Add navigation buttons for accessible screens
	for screen_name in get_accessible_screens():
		if screen_name == "main_menu":
			continue  # Skip main menu in game navigation

		var button = Button.new()
		button.text = get_screen_title(screen_name)
		button.tooltip_text = get_screen_description(screen_name)
		button.pressed.connect(_on_navigation_button_pressed.bind(screen_name))

		# Highlight current screen
		if screen_name == current_screen:
			button.disabled = true

		menu.add_child(button)

	# Add back button if history exists
	if not screen_history.is_empty():
		var back_button = Button.new()
		back_button.text = tr("navigation.back")
		back_button.pressed.connect(_on_back_button_pressed)
		menu.add_child(back_button)

	return menu

func get_transition_data() -> Dictionary:
	"""Get transition data passed to current screen"""
	return transition_data

func clear_transition_data() -> void:
	"""Clear stored transition data"""
	transition_data.clear()

func _perform_screen_transition(from_screen: String, to_screen: String) -> void:
	"""Perform animated screen transition"""
	var current_scene = get_tree().current_scene

	# Fade out current screen
	if current_scene:
		var fade_out_tween = create_tween()
		fade_out_tween.tween_property(current_scene, "modulate:a", 0.0, 0.2)
		await fade_out_tween.finished

	# Load new screen
	var new_scene_path = screen_scenes[to_screen]
	var result = get_tree().change_scene_to_file(new_scene_path)

	if result != OK:
		push_error("Failed to load screen: " + to_screen)
		return

	# Wait for scene to be ready
	await get_tree().process_frame

	# Fade in new screen
	var new_scene = get_tree().current_scene
	if new_scene:
		new_scene.modulate.a = 0.0
		var fade_in_tween = create_tween()
		fade_in_tween.tween_property(new_scene, "modulate:a", 1.0, 0.2)
		await fade_in_tween.finished

		# Pass transition data to new screen if it supports it
		if new_scene.has_method("receive_transition_data"):
			new_scene.receive_transition_data(transition_data)

func _on_navigation_button_pressed(screen_name: String) -> void:
	"""Handle navigation button press"""
	navigate_to_screen(screen_name)

func _on_back_button_pressed() -> void:
	"""Handle back button press"""
	navigate_back()

# Campaign-specific navigation helpers

func navigate_to_dashboard(data: Dictionary = {}) -> void:
	"""Navigate to dashboard with optional data"""
	navigate_to_screen("dashboard", data)

func navigate_to_map(filter_type: String = "", filter_value: String = "") -> void:
	"""Navigate to map with specific filter"""
	var data = {}
	if filter_type != "":
		data["filter_type"] = filter_type
		data["filter_value"] = filter_value
	navigate_to_screen("map", data)

func navigate_to_media_event(event: DataModels.MediaEvent) -> void:
	"""Navigate to media event screen"""
	var data = {"media_event": event}
	navigate_to_screen("media", data)

func navigate_to_coalition_builder(available_parties: Array = []) -> void:
	"""Navigate to coalition builder"""
	var data = {}
	if not available_parties.is_empty():
		data["available_parties"] = available_parties
	navigate_to_screen("coalition", data)

func navigate_to_election_results(election: DataModels.Election) -> void:
	"""Navigate to election results screen"""
	var data = {"election": election}
	navigate_to_screen("results", data)

func navigate_to_settings(initial_tab: String = "") -> void:
	"""Navigate to settings screen"""
	var data = {}
	if initial_tab != "":
		data["initial_tab"] = initial_tab
	navigate_to_screen("settings", data)

# Accessibility integration

func setup_keyboard_shortcuts() -> void:
	"""Setup global keyboard shortcuts for navigation"""
	# These would be handled by input map
	var shortcuts = {
		"navigate_dashboard": "F2",
		"navigate_map": "F3",
		"navigate_media": "F4",
		"navigate_coalition": "F5",
		"navigate_parliament": "F6",
		"navigate_settings": "F10",
		"navigate_back": "Alt+Left"
	}

	# Store for accessibility help
	set_meta("keyboard_shortcuts", shortcuts)

func get_keyboard_shortcuts() -> Dictionary:
	"""Get navigation keyboard shortcuts"""
	return get_meta("keyboard_shortcuts", {})

func announce_screen_change(screen_name: String) -> void:
	"""Announce screen change for accessibility"""
	var announcement = tr("navigation.arrived_at") % get_screen_title(screen_name)
	# This would integrate with screen reader
	print("Navigation announcement: " + announcement)

# Constitutional compliance

func validate_navigation_transparency() -> bool:
	"""Validate that navigation is transparent and explainable"""
	# All screens should have clear titles and descriptions
	for screen in screen_scenes.keys():
		var title = get_screen_title(screen)
		var description = get_screen_description(screen)

		if title == "" or description == "":
			return false

	return true

func get_navigation_help() -> String:
	"""Get help text for navigation system"""
	var help = tr("navigation.help.intro") + "\n\n"

	help += tr("navigation.help.screens") + "\n"
	for screen in get_accessible_screens():
		help += "• " + get_screen_title(screen) + ": " + get_screen_description(screen) + "\n"

	help += "\n" + tr("navigation.help.shortcuts") + "\n"
	for action in get_keyboard_shortcuts().keys():
		var shortcut = get_keyboard_shortcuts()[action]
		help += "• " + shortcut + ": " + tr("navigation.shortcut." + action) + "\n"

	return help

# Integration with game state

func update_from_game_state(game_state: DataModels.GameState) -> void:
	"""Update navigation based on current game state"""
	if not game_state:
		return

	# Update screen accessibility based on game phase
	set_game_phase(game_state.game_phase)

	# Update screen states based on game progress
	if game_state.game_phase == "campaign":
		# All campaign screens available
		screen_states["dashboard"] = true
		screen_states["map"] = true
		screen_states["media"] = true
		screen_states["social"] = true

	elif game_state.game_phase == "coalition":
		# Coalition phase screens
		screen_states["coalition"] = true
		screen_states["parliament"] = true

	elif game_state.game_phase == "election":
		# DataModels.Election results available
		screen_states["results"] = true

# Screen state persistence

func save_navigation_state() -> Dictionary:
	"""Save navigation state for game save"""
	return {
		"current_screen": current_screen,
		"screen_history": screen_history.duplicate(),
		"screen_states": screen_states.duplicate()
	}

func load_navigation_state(state: Dictionary) -> void:
	"""Load navigation state from game save"""
	if state.has("current_screen"):
		current_screen = state.current_screen
	if state.has("screen_history"):
		screen_history = state.screen_history.duplicate()
	if state.has("screen_states"):
		screen_states = state.screen_states.duplicate()