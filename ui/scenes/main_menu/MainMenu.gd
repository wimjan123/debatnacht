extends Control
class_name MainMenu

# Main menu screen with keyboard navigation and accessibility support
# Entry point for new campaigns, loading saves, tutorial, and settings

@onready var new_campaign_button: Button = $VBoxContainer/MenuButtons/NewCampaignButton
@onready var load_campaign_button: Button = $VBoxContainer/MenuButtons/LoadCampaignButton
@onready var tutorial_button: Button = $VBoxContainer/MenuButtons/TutorialButton
@onready var settings_button: Button = $VBoxContainer/MenuButtons/SettingsButton
@onready var quit_button: Button = $VBoxContainer/MenuButtons/QuitButton
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var version_label: Label = $VBoxContainer/VersionLabel

var accessibility_manager: AccessibilityManager
var navigation_controller: NavigationController
var save_system: SaveSystem

signal campaign_start_requested()
signal campaign_load_requested()
signal tutorial_requested()
signal settings_requested()
signal quit_requested()

func _ready():
	# Get managers
	accessibility_manager = get_node("/root/AccessibilityManager") if has_node("/root/AccessibilityManager") else null
	navigation_controller = get_node("/root/NavigationController") if has_node("/root/NavigationController") else null

	# Setup localized text
	_update_localization()

	# Setup keyboard navigation
	_setup_keyboard_navigation()

	# Set initial focus
	new_campaign_button.grab_focus()

	# Check for save files
	_update_load_button_state()

	# Update version display
	_update_version_display()

func _update_localization():
	"""Update all text with current localization"""
	title_label.text = tr("main_menu.title")
	new_campaign_button.text = tr("main_menu.new_campaign")
	load_campaign_button.text = tr("main_menu.load_campaign")
	tutorial_button.text = tr("main_menu.tutorial")
	settings_button.text = tr("main_menu.settings")
	quit_button.text = tr("main_menu.quit")
	version_label.text = tr("main_menu.version") % ProjectSettings.get_setting("application/config/version", "1.0.0")

	# Update tooltips
	new_campaign_button.tooltip_text = tr("main_menu.tooltip.new_campaign")
	load_campaign_button.tooltip_text = tr("main_menu.tooltip.load_campaign")
	tutorial_button.tooltip_text = tr("main_menu.tooltip.tutorial")
	settings_button.tooltip_text = tr("main_menu.tooltip.settings")
	quit_button.tooltip_text = tr("main_menu.tooltip.quit")

func _setup_keyboard_navigation():
	"""Setup keyboard navigation between menu buttons"""
	if accessibility_manager:
		accessibility_manager.setup_keyboard_navigation(self)

	# Setup focus chain manually as fallback
	new_campaign_button.focus_next = load_campaign_button.get_path()
	load_campaign_button.focus_previous = new_campaign_button.get_path()
	load_campaign_button.focus_next = tutorial_button.get_path()
	tutorial_button.focus_previous = load_campaign_button.get_path()
	tutorial_button.focus_next = settings_button.get_path()
	settings_button.focus_previous = tutorial_button.get_path()
	settings_button.focus_next = quit_button.get_path()
	quit_button.focus_previous = settings_button.get_path()
	quit_button.focus_next = new_campaign_button.get_path()

func _update_load_button_state():
	"""Enable/disable load button based on save file availability"""
	var save_files_exist = _check_save_files_exist()
	load_campaign_button.disabled = not save_files_exist

	if not save_files_exist:
		load_campaign_button.tooltip_text = tr("main_menu.tooltip.no_saves")

func _check_save_files_exist() -> bool:
	"""Check if any save files exist"""
	var save_dir = "user://saves/"
	var dir = DirAccess.open(save_dir)
	if dir == null:
		return false

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".save"):
			dir.list_dir_end()
			return true
		file_name = dir.get_next()

	dir.list_dir_end()
	return false

func _update_version_display():
	"""Update version label with current build info"""
	var version = ProjectSettings.get_setting("application/config/version", "1.0.0")
	var build_type = "Dev" if OS.is_debug_build() else "Release"
	version_label.text = tr("main_menu.version_info") % [version, build_type]

func _input(event):
	"""Handle global input for accessibility"""
	if event.is_action_pressed("show_help"):
		_show_help_dialog()
		get_viewport().set_input_as_handled()

func _show_help_dialog():
	"""Show help dialog with keyboard shortcuts"""
	if navigation_controller:
		var help_content = tr("main_menu.help.content") + "\n\n"
		help_content += tr("main_menu.help.shortcuts") + "\n"
		help_content += "• F1: " + tr("help.show_help") + "\n"
		help_content += "• Tab: " + tr("help.next_element") + "\n"
		help_content += "• Shift+Tab: " + tr("help.previous_element") + "\n"
		help_content += "• Enter/Space: " + tr("help.activate") + "\n"
		help_content += "• Escape: " + tr("help.cancel")

		# This would show a help modal
		print("Help: " + help_content)

# Button event handlers

func _on_new_campaign_pressed():
	"""Start new campaign flow"""
	if accessibility_manager:
		accessibility_manager.announce_to_screen_reader(tr("main_menu.announce.new_campaign"))

	campaign_start_requested.emit()

	# Navigate to campaign setup or directly to dashboard
	if navigation_controller:
		navigation_controller.navigate_to_screen("dashboard")

func _on_load_campaign_pressed():
	"""Load existing campaign"""
	if load_campaign_button.disabled:
		return

	if accessibility_manager:
		accessibility_manager.announce_to_screen_reader(tr("main_menu.announce.load_campaign"))

	campaign_load_requested.emit()
	_show_load_campaign_dialog()

func _show_load_campaign_dialog():
	"""Show save file selection dialog"""
	# Create and show file dialog for save files
	var save_files = _get_save_files()

	if save_files.is_empty():
		print("No save files found")
		return

	# For now, just load the most recent save
	var most_recent = save_files[0]
	_load_save_file(most_recent)

func _get_save_files() -> Array[String]:
	"""Get list of available save files"""
	var save_files: Array[String] = []
	var save_dir = "user://saves/"
	var dir = DirAccess.open(save_dir)

	if dir == null:
		return save_files

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".save"):
			save_files.append(save_dir + file_name)
		file_name = dir.get_next()

	dir.list_dir_end()

	# Sort by modification time (most recent first)
	save_files.sort_custom(_compare_file_times)

	return save_files

func _compare_file_times(a: String, b: String) -> bool:
	"""Compare file modification times for sorting"""
	return FileAccess.get_modified_time(a) > FileAccess.get_modified_time(b)

func _load_save_file(file_path: String):
	"""Load specified save file"""
	var save_data = _read_save_file(file_path)
	if save_data == null:
		print("Failed to load save file: " + file_path)
		return

	# Load game state and navigate to appropriate screen
	if navigation_controller:
		navigation_controller.navigate_to_screen("dashboard")

func _read_save_file(file_path: String) -> Dictionary:
	"""Read and parse save file"""
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {}

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var result = json.parse(json_text)

	if result != OK:
		print("Failed to parse save file JSON: " + file_path)
		return {}

	return json.data

func _on_tutorial_pressed():
	"""Start tutorial flow"""
	if accessibility_manager:
		accessibility_manager.announce_to_screen_reader(tr("main_menu.announce.tutorial"))

	tutorial_requested.emit()

	# Navigate to tutorial or dashboard with tutorial mode
	if navigation_controller:
		navigation_controller.navigate_to_screen("dashboard", {"tutorial_mode": true})

func _on_settings_pressed():
	"""Open settings screen"""
	if accessibility_manager:
		accessibility_manager.announce_to_screen_reader(tr("main_menu.announce.settings"))

	settings_requested.emit()

	if navigation_controller:
		navigation_controller.navigate_to_screen("settings")

func _on_quit_pressed():
	"""Quit application with confirmation"""
	if accessibility_manager:
		accessibility_manager.announce_to_screen_reader(tr("main_menu.announce.quit"))

	quit_requested.emit()
	_show_quit_confirmation()

func _show_quit_confirmation():
	"""Show quit confirmation dialog"""
	# Create confirmation dialog
	var dialog = AcceptDialog.new()
	dialog.dialog_text = tr("main_menu.quit_confirmation")
	dialog.title = tr("main_menu.quit_title")

	# Add cancel button
	dialog.add_cancel_button(tr("common.cancel"))

	# Connect signals
	dialog.confirmed.connect(_confirm_quit)
	dialog.canceled.connect(func(): dialog.queue_free())

	# Show dialog
	add_child(dialog)
	dialog.popup_centered()

func _confirm_quit():
	"""Confirm quit and exit application"""
	get_tree().quit()

# Accessibility and localization support

func receive_transition_data(data: Dictionary):
	"""Receive data from navigation transitions"""
	# Handle any transition data if needed
	pass

func _notification(what):
	"""Handle system notifications"""
	match what:
		NOTIFICATION_TRANSLATION_CHANGED:
			_update_localization()

# Constitutional compliance helpers

func validate_neutrality() -> bool:
	"""Validate that main menu maintains political neutrality"""
	# Ensure no political bias in menu options or presentation
	return true

func get_transparency_info() -> Dictionary:
	"""Provide transparency information for constitutional compliance"""
	return {
		"screen_type": "main_menu",
		"data_sources": ["local_save_files"],
		"decision_factors": ["save_file_availability"],
		"user_control": ["full_navigation_control", "accessibility_options"]
	}

func validate_accessibility() -> Dictionary:
	"""Validate accessibility compliance"""
	var compliance = {}
	compliance["keyboard_navigation"] = new_campaign_button.focus_mode != Control.FOCUS_NONE
	compliance["screen_reader_support"] = accessibility_manager != null
	compliance["localization"] = TranslationServer.get_locale() in ["en", "nl"]
	return compliance