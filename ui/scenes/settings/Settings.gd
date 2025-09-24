extends Control
class_name SettingsScene

# Settings scene controller
# Handles game settings, accessibility options, and user preferences

# UI References - MainContainer structure
@onready var settings_title: Label = $MainContainer/HeaderContainer/SettingsTitle

# Settings Content (TabContainer)
@onready var settings_tabs: TabContainer = $MainContainer/SettingsContent/SettingsTabs

# General Settings Tab
@onready var language_option: OptionButton = $MainContainer/SettingsContent/SettingsTabs/GeneralSettings/GeneralScrollContainer/GeneralContent/LanguageContainer/LanguageOption
@onready var difficulty_option: OptionButton = $MainContainer/SettingsContent/SettingsTabs/GeneralSettings/GeneralScrollContainer/GeneralContent/DifficultyContainer/DifficultyOption
@onready var autosave_check: CheckBox = $MainContainer/SettingsContent/SettingsTabs/GeneralSettings/GeneralScrollContainer/GeneralContent/GameplayContainer/AutosaveCheck
@onready var tutorials_check: CheckBox = $MainContainer/SettingsContent/SettingsTabs/GeneralSettings/GeneralScrollContainer/GeneralContent/GameplayContainer/TutorialsCheck
@onready var tooltips_check: CheckBox = $MainContainer/SettingsContent/SettingsTabs/GeneralSettings/GeneralScrollContainer/GeneralContent/GameplayContainer/TooltipsCheck

# Accessibility Settings Tab
@onready var theme_option: OptionButton = $MainContainer/SettingsContent/SettingsTabs/AccessibilitySettings/AccessibilityScrollContainer/AccessibilityContent/VisualContainer/ThemeOption
@onready var text_size_slider: HSlider = $MainContainer/SettingsContent/SettingsTabs/AccessibilitySettings/AccessibilityScrollContainer/AccessibilityContent/VisualContainer/TextSizeContainer/TextSizeSlider
@onready var text_size_value: Label = $MainContainer/SettingsContent/SettingsTabs/AccessibilitySettings/AccessibilityScrollContainer/AccessibilityContent/VisualContainer/TextSizeContainer/TextSizeValue
@onready var contrast_slider: HSlider = $MainContainer/SettingsContent/SettingsTabs/AccessibilitySettings/AccessibilityScrollContainer/AccessibilityContent/VisualContainer/ContrastContainer/ContrastSlider
@onready var contrast_value: Label = $MainContainer/SettingsContent/SettingsTabs/AccessibilitySettings/AccessibilityScrollContainer/AccessibilityContent/VisualContainer/ContrastContainer/ContrastValue
@onready var screen_reader_check: CheckBox = $MainContainer/SettingsContent/SettingsTabs/AccessibilitySettings/AccessibilityScrollContainer/AccessibilityContent/AssistiveContainer/ScreenReaderCheck
@onready var keyboard_nav_check: CheckBox = $MainContainer/SettingsContent/SettingsTabs/AccessibilitySettings/AccessibilityScrollContainer/AccessibilityContent/AssistiveContainer/KeyboardNavCheck
@onready var audio_cues_check: CheckBox = $MainContainer/SettingsContent/SettingsTabs/AccessibilitySettings/AccessibilityScrollContainer/AccessibilityContent/AssistiveContainer/AudioCuesCheck

# Audio Settings Tab
@onready var master_volume_slider: HSlider = $MainContainer/SettingsContent/SettingsTabs/AudioSettings/AudioScrollContainer/AudioContent/VolumeContainer/MasterVolumeContainer/MasterVolumeSlider
@onready var master_volume_value: Label = $MainContainer/SettingsContent/SettingsTabs/AudioSettings/AudioScrollContainer/AudioContent/VolumeContainer/MasterVolumeContainer/MasterVolumeValue
@onready var sfx_volume_slider: HSlider = $MainContainer/SettingsContent/SettingsTabs/AudioSettings/AudioScrollContainer/AudioContent/VolumeContainer/SFXVolumeContainer/SFXVolumeSlider
@onready var sfx_volume_value: Label = $MainContainer/SettingsContent/SettingsTabs/AudioSettings/AudioScrollContainer/AudioContent/VolumeContainer/SFXVolumeContainer/SFXVolumeValue
@onready var music_volume_slider: HSlider = $MainContainer/SettingsContent/SettingsTabs/AudioSettings/AudioScrollContainer/AudioContent/VolumeContainer/MusicVolumeContainer/MusicVolumeSlider
@onready var music_volume_value: Label = $MainContainer/SettingsContent/SettingsTabs/AudioSettings/AudioScrollContainer/AudioContent/VolumeContainer/MusicVolumeContainer/MusicVolumeValue
@onready var mute_audio_check: CheckBox = $MainContainer/SettingsContent/SettingsTabs/AudioSettings/AudioScrollContainer/AudioContent/AudioOptionsContainer/MuteAudioCheck

# Performance Settings Tab  
@onready var vsync_check: CheckBox = $MainContainer/SettingsContent/SettingsTabs/PerformanceSettings/PerformanceScrollContainer/PerformanceContent/DisplayContainer/VsyncCheck
@onready var fps_limit_option: OptionButton = $MainContainer/SettingsContent/SettingsTabs/PerformanceSettings/PerformanceScrollContainer/PerformanceContent/DisplayContainer/FPSLimitContainer/FPSLimitOption
@onready var window_mode_option: OptionButton = $MainContainer/SettingsContent/SettingsTabs/PerformanceSettings/PerformanceScrollContainer/PerformanceContent/DisplayContainer/WindowModeContainer/WindowModeOption
@onready var multithreading_check: CheckBox = $MainContainer/SettingsContent/SettingsTabs/PerformanceSettings/PerformanceScrollContainer/PerformanceContent/OptimizationContainer/MultithreadingCheck

# Privacy Settings Tab
@onready var analytics_check: CheckBox = $MainContainer/SettingsContent/SettingsTabs/PrivacySettings/PrivacyScrollContainer/PrivacyContent/DataContainer/AnalyticsCheck
@onready var crash_reporting_check: CheckBox = $MainContainer/SettingsContent/SettingsTabs/PrivacySettings/PrivacyScrollContainer/PrivacyContent/DataContainer/CrashReportingCheck
@onready var data_transparency_button: Button = $MainContainer/SettingsContent/SettingsTabs/PrivacySettings/PrivacyScrollContainer/PrivacyContent/TransparencyContainer/DataTransparencyButton
@onready var export_data_button: Button = $MainContainer/SettingsContent/SettingsTabs/PrivacySettings/PrivacyScrollContainer/PrivacyContent/TransparencyContainer/ExportDataButton
@onready var delete_data_button: Button = $MainContainer/SettingsContent/SettingsTabs/PrivacySettings/PrivacyScrollContainer/PrivacyContent/TransparencyContainer/DeleteDataButton

# Action Buttons
@onready var back_button: Button = $MainContainer/ActionContainer/BackButton
@onready var reset_defaults_button: Button = $MainContainer/ActionContainer/ResetDefaultsButton
@onready var apply_button: Button = $MainContainer/ActionContainer/ApplyButton
@onready var help_button: Button = $MainContainer/ActionContainer/HelpButton

# Settings State
var settings_data: Dictionary = {}
var original_settings: Dictionary = {}
var settings_changed: bool = false

# Scene Dependencies
var localization_manager: LocalizationManager
var tooltip_manager: TooltipManager
var notification_system: NotificationSystem
var navigation_controller: NavigationController
var accessibility_manager: AccessibilityManager

func _ready() -> void:
	# Get singleton references
	localization_manager = LocalizationManager.get_instance()
	tooltip_manager = TooltipManager.get_instance()
	notification_system = NotificationSystem.get_instance()
	navigation_controller = NavigationController.get_instance()
	accessibility_manager = AccessibilityManager.get_instance()
	
	# Initialize settings interface
	_load_current_settings()
	_initialize_settings_ui()
	_setup_signal_connections()
	_setup_tooltips()
	_setup_accessibility_features()

func _load_current_settings() -> void:
	"""Load current settings from configuration"""
	# Load settings from game configuration (stub implementation)
	settings_data = {
		# General Settings
		"language": "en",
		"difficulty": "normal",
		"autosave": true,
		"tutorials": true,
		"tooltips": true,
		
		# Accessibility Settings
		"theme": "default",
		"text_size": 100,  # Percentage
		"contrast": 100,   # Percentage
		"screen_reader": false,
		"keyboard_nav": true,
		"audio_cues": false,
		
		# Audio Settings
		"master_volume": 80,
		"sfx_volume": 75,
		"music_volume": 60,
		"mute_audio": false,
		
		# Performance Settings
		"vsync": true,
		"fps_limit": 60,
		"window_mode": "windowed",
		"multithreading": true,
		
		# Privacy Settings
		"analytics": false,  # Default to privacy-first
		"crash_reporting": true
	}
	
	# Store original settings for comparison
	original_settings = settings_data.duplicate(true)

func _initialize_settings_ui() -> void:
	"""Initialize all settings UI elements with current values"""
	settings_title.text = localization_manager.get_text("settings.title")
	
	# Initialize General Settings
	_initialize_general_settings()
	
	# Initialize Accessibility Settings
	_initialize_accessibility_settings()
	
	# Initialize Audio Settings
	_initialize_audio_settings()
	
	# Initialize Performance Settings
	_initialize_performance_settings()
	
	# Initialize Privacy Settings
	_initialize_privacy_settings()

func _initialize_general_settings() -> void:
	"""Initialize general settings controls"""
	# Language dropdown
	language_option.clear()
	language_option.add_item(localization_manager.get_text("settings.language_english"), 0)
	language_option.add_item(localization_manager.get_text("settings.language_dutch"), 1)
	language_option.selected = 0 if settings_data.language == "en" else 1
	
	# Difficulty dropdown
	difficulty_option.clear()
	difficulty_option.add_item(localization_manager.get_text("settings.difficulty_easy"), 0)
	difficulty_option.add_item(localization_manager.get_text("settings.difficulty_normal"), 1)
	difficulty_option.add_item(localization_manager.get_text("settings.difficulty_hard"), 2)
	
	match settings_data.difficulty:
		"easy":
			difficulty_option.selected = 0
		"hard":
			difficulty_option.selected = 2
		_:
			difficulty_option.selected = 1
	
	# Gameplay checkboxes
	autosave_check.button_pressed = settings_data.autosave
	tutorials_check.button_pressed = settings_data.tutorials
	tooltips_check.button_pressed = settings_data.tooltips

func _initialize_accessibility_settings() -> void:
	"""Initialize accessibility settings controls"""
	# Theme dropdown
	theme_option.clear()
	theme_option.add_item(localization_manager.get_text("settings.theme_default"), 0)
	theme_option.add_item(localization_manager.get_text("settings.theme_high_contrast"), 1)
	theme_option.add_item(localization_manager.get_text("settings.theme_dark"), 2)
	
	match settings_data.theme:
		"high_contrast":
			theme_option.selected = 1
		"dark":
			theme_option.selected = 2
		_:
			theme_option.selected = 0
	
	# Text size slider (80% - 150%)
	text_size_slider.min_value = 80
	text_size_slider.max_value = 150
	text_size_slider.value = settings_data.text_size
	_update_text_size_display()
	
	# Contrast slider (80% - 150%)
	contrast_slider.min_value = 80
	contrast_slider.max_value = 150
	contrast_slider.value = settings_data.contrast
	_update_contrast_display()
	
	# Assistive technology checkboxes
	screen_reader_check.button_pressed = settings_data.screen_reader
	keyboard_nav_check.button_pressed = settings_data.keyboard_nav
	audio_cues_check.button_pressed = settings_data.audio_cues

func _initialize_audio_settings() -> void:
	"""Initialize audio settings controls"""
	# Volume sliders (0-100)
	master_volume_slider.min_value = 0
	master_volume_slider.max_value = 100
	master_volume_slider.value = settings_data.master_volume
	_update_master_volume_display()
	
	sfx_volume_slider.min_value = 0
	sfx_volume_slider.max_value = 100
	sfx_volume_slider.value = settings_data.sfx_volume
	_update_sfx_volume_display()
	
	music_volume_slider.min_value = 0
	music_volume_slider.max_value = 100
	music_volume_slider.value = settings_data.music_volume
	_update_music_volume_display()
	
	# Mute checkbox
	mute_audio_check.button_pressed = settings_data.mute_audio

func _initialize_performance_settings() -> void:
	"""Initialize performance settings controls"""
	# VSync checkbox
	vsync_check.button_pressed = settings_data.vsync
	
	# FPS limit dropdown
	fps_limit_option.clear()
	fps_limit_option.add_item("30 FPS", 30)
	fps_limit_option.add_item("60 FPS", 60)
	fps_limit_option.add_item("120 FPS", 120)
	fps_limit_option.add_item(localization_manager.get_text("settings.fps_unlimited"), 0)
	
	match settings_data.fps_limit:
		30:
			fps_limit_option.selected = 0
		60:
			fps_limit_option.selected = 1
		120:
			fps_limit_option.selected = 2
		_:
			fps_limit_option.selected = 3
	
	# Window mode dropdown
	window_mode_option.clear()
	window_mode_option.add_item(localization_manager.get_text("settings.window_windowed"), 0)
	window_mode_option.add_item(localization_manager.get_text("settings.window_fullscreen"), 1)
	window_mode_option.add_item(localization_manager.get_text("settings.window_borderless"), 2)
	
	match settings_data.window_mode:
		"fullscreen":
			window_mode_option.selected = 1
		"borderless":
			window_mode_option.selected = 2
		_:
			window_mode_option.selected = 0
	
	# Multithreading checkbox
	multithreading_check.button_pressed = settings_data.multithreading

func _initialize_privacy_settings() -> void:
	"""Initialize privacy settings controls"""
	# Privacy checkboxes
	analytics_check.button_pressed = settings_data.analytics
	crash_reporting_check.button_pressed = settings_data.crash_reporting

func _setup_signal_connections() -> void:
	"""Connect all UI element signals to handlers"""
	# General Settings signals
	language_option.item_selected.connect(_on_language_changed)
	difficulty_option.item_selected.connect(_on_difficulty_changed)
	autosave_check.toggled.connect(_on_autosave_toggled)
	tutorials_check.toggled.connect(_on_tutorials_toggled)
	tooltips_check.toggled.connect(_on_tooltips_toggled)
	
	# Accessibility Settings signals
	theme_option.item_selected.connect(_on_theme_changed)
	text_size_slider.value_changed.connect(_on_text_size_changed)
	contrast_slider.value_changed.connect(_on_contrast_changed)
	screen_reader_check.toggled.connect(_on_screen_reader_toggled)
	keyboard_nav_check.toggled.connect(_on_keyboard_nav_toggled)
	audio_cues_check.toggled.connect(_on_audio_cues_toggled)
	
	# Audio Settings signals
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	mute_audio_check.toggled.connect(_on_mute_audio_toggled)
	
	# Performance Settings signals
	vsync_check.toggled.connect(_on_vsync_toggled)
	fps_limit_option.item_selected.connect(_on_fps_limit_changed)
	window_mode_option.item_selected.connect(_on_window_mode_changed)
	multithreading_check.toggled.connect(_on_multithreading_toggled)
	
	# Privacy Settings signals
	analytics_check.toggled.connect(_on_analytics_toggled)
	crash_reporting_check.toggled.connect(_on_crash_reporting_toggled)
	data_transparency_button.pressed.connect(_on_data_transparency_pressed)
	export_data_button.pressed.connect(_on_export_data_pressed)
	delete_data_button.pressed.connect(_on_delete_data_pressed)

func _setup_accessibility_features() -> void:
	"""Setup enhanced accessibility features"""
	# Ensure keyboard navigation works properly between tabs
	for i in range(settings_tabs.get_tab_count()):
		var tab_content = settings_tabs.get_tab_control(i)
		if tab_content:
			# Set up focus navigation within each tab
			_setup_tab_focus_navigation(tab_content)
	
	# Apply current accessibility settings
	_apply_accessibility_settings_immediately()

func _setup_tab_focus_navigation(tab_content: Control) -> void:
	"""Setup focus navigation for a specific tab"""
	# Get all focusable controls in the tab
	var focusable_controls = _get_focusable_controls(tab_content)
	
	# Set up sequential focus navigation
	for i in range(focusable_controls.size()):
		var current = focusable_controls[i]
		var next_index = (i + 1) % focusable_controls.size()
		var prev_index = (i - 1 + focusable_controls.size()) % focusable_controls.size()
		
		current.focus_neighbor_bottom = focusable_controls[next_index].get_path()
		current.focus_neighbor_top = focusable_controls[prev_index].get_path()

func _get_focusable_controls(parent: Node) -> Array[Control]:
	"""Recursively get all focusable controls in a parent node"""
	var controls: Array[Control] = []
	
	for child in parent.get_children():
		if child is Control and child.focus_mode != Control.FOCUS_NONE:
			controls.append(child)
		
		# Recursively check children
		controls.append_array(_get_focusable_controls(child))
	
	return controls

func _apply_accessibility_settings_immediately() -> void:
	"""Apply accessibility settings that can be changed immediately"""
	if accessibility_manager:
		accessibility_manager.apply_text_scaling(settings_data.text_size / 100.0)
		accessibility_manager.apply_contrast_adjustment(settings_data.contrast / 100.0)
		accessibility_manager.set_keyboard_navigation_enabled(settings_data.keyboard_nav)

func _setup_tooltips() -> void:
	"""Setup educational tooltips for settings options"""
	tooltip_manager.add_tooltip(language_option, "tooltip.language_explanation")
	tooltip_manager.add_tooltip(difficulty_option, "tooltip.difficulty_explanation")
	tooltip_manager.add_tooltip(theme_option, "tooltip.theme_explanation")
	tooltip_manager.add_tooltip(text_size_slider, "tooltip.text_size_explanation")
	tooltip_manager.add_tooltip(screen_reader_check, "tooltip.screen_reader_explanation")
	tooltip_manager.add_tooltip(analytics_check, "tooltip.analytics_explanation")
	tooltip_manager.add_tooltip(data_transparency_button, "tooltip.transparency_explanation")

# Settings change handlers
func _mark_settings_changed() -> void:
	"""Mark settings as changed and update UI accordingly"""
	settings_changed = true
	apply_button.disabled = false

func _on_language_changed(index: int) -> void:
	settings_data.language = "en" if index == 0 else "nl"
	_mark_settings_changed()

func _on_difficulty_changed(index: int) -> void:
	var difficulties = ["easy", "normal", "hard"]
	settings_data.difficulty = difficulties[index]
	_mark_settings_changed()

func _on_autosave_toggled(pressed: bool) -> void:
	settings_data.autosave = pressed
	_mark_settings_changed()

func _on_tutorials_toggled(pressed: bool) -> void:
	settings_data.tutorials = pressed
	_mark_settings_changed()

func _on_tooltips_toggled(pressed: bool) -> void:
	settings_data.tooltips = pressed
	_mark_settings_changed()

func _on_theme_changed(index: int) -> void:
	var themes = ["default", "high_contrast", "dark"]
	settings_data.theme = themes[index]
	_mark_settings_changed()

func _on_text_size_changed(value: float) -> void:
	settings_data.text_size = int(value)
	_update_text_size_display()
	_apply_accessibility_settings_immediately()
	_mark_settings_changed()

func _on_contrast_changed(value: float) -> void:
	settings_data.contrast = int(value)
	_update_contrast_display()
	_apply_accessibility_settings_immediately()
	_mark_settings_changed()

func _on_screen_reader_toggled(pressed: bool) -> void:
	settings_data.screen_reader = pressed
	_mark_settings_changed()

func _on_keyboard_nav_toggled(pressed: bool) -> void:
	settings_data.keyboard_nav = pressed
	_apply_accessibility_settings_immediately()
	_mark_settings_changed()

func _on_audio_cues_toggled(pressed: bool) -> void:
	settings_data.audio_cues = pressed
	_mark_settings_changed()

func _on_master_volume_changed(value: float) -> void:
	settings_data.master_volume = int(value)
	_update_master_volume_display()
	_mark_settings_changed()

func _on_sfx_volume_changed(value: float) -> void:
	settings_data.sfx_volume = int(value)
	_update_sfx_volume_display()
	_mark_settings_changed()

func _on_music_volume_changed(value: float) -> void:
	settings_data.music_volume = int(value)
	_update_music_volume_display()
	_mark_settings_changed()

func _on_mute_audio_toggled(pressed: bool) -> void:
	settings_data.mute_audio = pressed
	_mark_settings_changed()

func _on_vsync_toggled(pressed: bool) -> void:
	settings_data.vsync = pressed
	_mark_settings_changed()

func _on_fps_limit_changed(index: int) -> void:
	var fps_limits = [30, 60, 120, 0]  # 0 = unlimited
	settings_data.fps_limit = fps_limits[index]
	_mark_settings_changed()

func _on_window_mode_changed(index: int) -> void:
	var modes = ["windowed", "fullscreen", "borderless"]
	settings_data.window_mode = modes[index]
	_mark_settings_changed()

func _on_multithreading_toggled(pressed: bool) -> void:
	settings_data.multithreading = pressed
	_mark_settings_changed()

func _on_analytics_toggled(pressed: bool) -> void:
	settings_data.analytics = pressed
	_mark_settings_changed()

func _on_crash_reporting_toggled(pressed: bool) -> void:
	settings_data.crash_reporting = pressed
	_mark_settings_changed()

# Display update functions
func _update_text_size_display() -> void:
	text_size_value.text = str(settings_data.text_size) + "%"

func _update_contrast_display() -> void:
	contrast_value.text = str(settings_data.contrast) + "%"

func _update_master_volume_display() -> void:
	master_volume_value.text = str(settings_data.master_volume) + "%"

func _update_sfx_volume_display() -> void:
	sfx_volume_value.text = str(settings_data.sfx_volume) + "%"

func _update_music_volume_display() -> void:
	music_volume_value.text = str(settings_data.music_volume) + "%"

# Action button handlers
func _on_back_button_pressed() -> void:
	"""Handle back button navigation with unsaved changes check"""
	if settings_changed:
		# Show confirmation dialog for unsaved changes
		notification_system.show_notification("settings.unsaved_changes_warning")
		# Would show proper confirmation dialog in full implementation
	else:
		navigation_controller.navigate_to_previous_scene()

func _on_reset_defaults_button_pressed() -> void:
	"""Reset all settings to default values"""
	# Show confirmation dialog
	notification_system.show_notification("settings.reset_defaults_confirm")
	# Would show proper confirmation dialog, then call _reset_to_defaults()

func _reset_to_defaults() -> void:
	"""Actually reset settings to defaults"""
	# Reset all settings to default values
	settings_data = {
		"language": "en",
		"difficulty": "normal",
		"autosave": true,
		"tutorials": true,
		"tooltips": true,
		"theme": "default",
		"text_size": 100,
		"contrast": 100,
		"screen_reader": false,
		"keyboard_nav": true,
		"audio_cues": false,
		"master_volume": 80,
		"sfx_volume": 75,
		"music_volume": 60,
		"mute_audio": false,
		"vsync": true,
		"fps_limit": 60,
		"window_mode": "windowed",
		"multithreading": true,
		"analytics": false,
		"crash_reporting": true
	}
	
	# Reinitialize UI with defaults
	_initialize_settings_ui()
	_mark_settings_changed()

func _on_apply_button_pressed() -> void:
	"""Apply all settings changes"""
	_apply_all_settings()
	notification_system.show_notification("settings.applied_successfully")
	
	# Update original settings and mark as unchanged
	original_settings = settings_data.duplicate(true)
	settings_changed = false
	apply_button.disabled = true

func _apply_all_settings() -> void:
	"""Apply all current settings to the game"""
	# Apply language settings
	localization_manager.set_language(settings_data.language)
	
	# Apply accessibility settings
	if accessibility_manager:
		accessibility_manager.apply_theme(settings_data.theme)
		accessibility_manager.apply_text_scaling(settings_data.text_size / 100.0)
		accessibility_manager.apply_contrast_adjustment(settings_data.contrast / 100.0)
		accessibility_manager.set_screen_reader_enabled(settings_data.screen_reader)
		accessibility_manager.set_keyboard_navigation_enabled(settings_data.keyboard_nav)
		accessibility_manager.set_audio_cues_enabled(settings_data.audio_cues)
	
	# Apply audio settings
	_apply_audio_settings()
	
	# Apply performance settings
	_apply_performance_settings()
	
	# Save settings to file
	_save_settings_to_file()

func _apply_audio_settings() -> void:
	"""Apply audio settings"""
	# Apply volume settings to audio buses
	var master_bus_index = AudioServer.get_bus_index("Master")
	if master_bus_index >= 0:
		if settings_data.mute_audio:
			AudioServer.set_bus_volume_db(master_bus_index, -80.0)  # Effectively muted
		else:
			var volume_db = linear_to_db(settings_data.master_volume / 100.0)
			AudioServer.set_bus_volume_db(master_bus_index, volume_db)
	
	# Apply SFX and Music volume (if buses exist)
	var sfx_bus_index = AudioServer.get_bus_index("SFX")
	if sfx_bus_index >= 0:
		var volume_db = linear_to_db(settings_data.sfx_volume / 100.0)
		AudioServer.set_bus_volume_db(sfx_bus_index, volume_db)
	
	var music_bus_index = AudioServer.get_bus_index("Music")
	if music_bus_index >= 0:
		var volume_db = linear_to_db(settings_data.music_volume / 100.0)
		AudioServer.set_bus_volume_db(music_bus_index, volume_db)

func _apply_performance_settings() -> void:
	"""Apply performance settings"""
	# Apply VSync setting
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if settings_data.vsync else DisplayServer.VSYNC_DISABLED
	)
	
	# Apply FPS limit
	if settings_data.fps_limit > 0:
		Engine.max_fps = settings_data.fps_limit
	else:
		Engine.max_fps = 0  # Unlimited
	
	# Apply window mode
	match settings_data.window_mode:
		"fullscreen":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		"borderless":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _save_settings_to_file() -> void:
	"""Save current settings to configuration file"""
	var config_file = ConfigFile.new()
	
	# Save each category of settings
	for key in settings_data.keys():
		config_file.set_value("settings", key, settings_data[key])
	
	# Save to file
	var error = config_file.save("user://settings.cfg")
	if error != OK:
		print("Error saving settings: ", error)

func _on_help_button_pressed() -> void:
	"""Handle help button"""
	# Would show settings help
	notification_system.show_notification("notification.help_coming_soon")

# Privacy-related handlers
func _on_data_transparency_pressed() -> void:
	"""Show data transparency information"""
	notification_system.show_notification("privacy.transparency_info")
	# Would show detailed data usage information

func _on_export_data_pressed() -> void:
	"""Export user data"""
	notification_system.show_notification("privacy.data_export_started")
	# Would generate and download user data export

func _on_delete_data_pressed() -> void:
	"""Delete user data with confirmation"""
	notification_system.show_notification("privacy.delete_data_confirm")
	# Would show serious confirmation dialog for data deletion
