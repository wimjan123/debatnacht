# UI Component Contracts
# Interface definitions for major UI components and their expected interactions

## Main Screen Controllers ##

class_name DashboardController
extends Control

# Update dashboard KPIs with latest data
# @param polls: float - current poll percentage
# @param seats: int - projected seat count
# @param funds: int - available campaign funds
# @param days_left: int - days until election
func update_kpis(polls: float, seats: int, funds: int, days_left: int) -> void:
	assert(false, "Must implement update_kpis")

# Display daily change summary with explanations
# @param changes: Dictionary - metric_name -> change_amount
# @param explanations: Dictionary - metric_name -> explanation_text
func show_daily_changes(changes: Dictionary, explanations: Dictionary) -> void:
	assert(false, "Must implement show_daily_changes")

# Handle campaign action selection
# @param available_actions: Array[CampaignAction] - valid player choices
# @returns CampaignAction - selected action or null if cancelled
func request_campaign_action(available_actions: Array[CampaignAction]) -> CampaignAction:
	assert(false, "Must implement request_campaign_action")

class_name MapViewController
extends Control

# Update map visualization with filtered data
# @param filter_type: String - "party_support", "issue_salience", "turnout", "demographics"
# @param region_data: Dictionary - region_id -> display_value
# @param legend_info: Dictionary - visualization legend parameters
func update_map_data(filter_type: String, region_data: Dictionary, legend_info: Dictionary) -> void:
	assert(false, "Must implement update_map_data")

# Show detailed region information on hover/click
# @param region_id: String - target region
# @param tooltip_data: RegionTooltipData - information to display
func show_region_tooltip(region_id: String, tooltip_data: RegionTooltipData) -> void:
	assert(false, "Must implement show_region_tooltip")

# Handle filter selection changes
# @returns Dictionary - selected_filter_type -> selected_value
func get_current_filters() -> Dictionary:
	assert(false, "Must implement get_current_filters")

class_name MediaEventController
extends Control

# Display media event interface with questions
# @param media_event: MediaEvent - event data with questions and options
func start_media_event(media_event: MediaEvent) -> void:
	assert(false, "Must implement start_media_event")

# Update real-time audience sentiment during event
# @param current_sentiment: float - audience reaction (-1.0 to 1.0)
# @param audience_reach: int - current viewer estimate
func update_sentiment_display(current_sentiment: float, audience_reach: int) -> void:
	assert(false, "Must implement update_sentiment_display")

# Show post-event summary with outcomes
# @param results: MediaResponse - event outcomes and effects
func show_event_summary(results: MediaResponse) -> void:
	assert(false, "Must implement show_event_summary")

class_name CoalitionBuilderController
extends Control

# Initialize coalition building interface
# @param available_parties: Array[Party] - parties available for coalition
# @param compatibility_matrix: Dictionary - party_pair -> compatibility_score
func setup_coalition_builder(available_parties: Array[Party], compatibility_matrix: Dictionary) -> void:
	assert(false, "Must implement setup_coalition_builder")

# Update coalition validation in real-time
# @param current_coalition: Array[String] - party IDs in current coalition
# @param validation: CoalitionValidation - feasibility and stability info
func update_coalition_validation(current_coalition: Array[String], validation: CoalitionValidation) -> void:
	assert(false, "Must implement update_coalition_validation")

# Handle party card drag and drop operations
# @param party_id: String - party being dragged
# @param drop_zone: String - where party was dropped
# @returns bool - whether drop was successful
func handle_party_drag_drop(party_id: String, drop_zone: String) -> bool:
	assert(false, "Must implement handle_party_drag_drop")

## Shared Component Interfaces ##

class_name TooltipManager
extends Control

# Show explanatory tooltip for any UI element
# @param target_element: Control - UI element being explained
# @param tooltip_data: TooltipData - content to display
func show_tooltip(target_element: Control, tooltip_data: TooltipData) -> void:
	assert(false, "Must implement show_tooltip")

# Show detailed explanation panel
# @param explanation: ExplanationPanel - detailed content
func show_explanation_panel(explanation: ExplanationPanel) -> void:
	assert(false, "Must implement show_explanation_panel")

# Hide all tooltips and explanation panels
func hide_all_tooltips() -> void:
	assert(false, "Must implement hide_all_tooltips")

class_name NotificationSystem
extends Control

# Display non-blocking notification toast
# @param message: String - notification text
# @param type: String - "info", "warning", "success", "error"
# @param duration: float - seconds to display
func show_notification(message: String, type: String, duration: float = 3.0) -> void:
	assert(false, "Must implement show_notification")

# Show modal dialog requiring user acknowledgment
# @param title: String - dialog title
# @param content: String - dialog message
# @param buttons: Array[String] - button options
# @returns String - selected button text
func show_modal_dialog(title: String, content: String, buttons: Array[String]) -> String:
	assert(false, "Must implement show_modal_dialog")

class_name AccessibilityManager
extends Control

# Switch language between Dutch and English
# @param language_code: String - "en" or "nl"
func set_language(language_code: String) -> void:
	assert(false, "Must implement set_language")

# Adjust text scaling for accessibility
# @param scale_factor: float - 0.75 to 2.0 scaling multiplier
func set_text_scale(scale_factor: float) -> void:
	assert(false, "Must implement set_text_scale")

# Enable high contrast theme for visual accessibility
# @param high_contrast: bool - whether to use high contrast colors
func set_high_contrast_mode(high_contrast: bool) -> void:
	assert(false, "Must implement set_high_contrast_mode")

# Set keyboard navigation focus to specific element
# @param target: Control - element to focus
func set_focus_target(target: Control) -> void:
	assert(false, "Must implement set_focus_target")

## Navigation Interface ##

class_name NavigationController
extends Control

# Switch to specified main screen
# @param screen_name: String - target screen identifier
# @param transition_data: Dictionary - optional data for screen initialization
func navigate_to_screen(screen_name: String, transition_data: Dictionary = {}) -> void:
	assert(false, "Must implement navigate_to_screen")

# Update navigation state (disable/enable screen access)
# @param screen_states: Dictionary - screen_name -> enabled_bool
func update_screen_accessibility(screen_states: Dictionary) -> void:
	assert(false, "Must implement update_screen_accessibility")

# Handle back navigation with undo support where applicable
# @returns bool - whether back navigation was successful
func navigate_back() -> bool:
	assert(false, "Must implement navigate_back")

## Input Handling ##

class_name InputHandler
extends Control

# Register keyboard shortcuts for current screen
# @param shortcuts: Dictionary - key_combination -> action_name
func register_keyboard_shortcuts(shortcuts: Dictionary) -> void:
	assert(false, "Must implement register_keyboard_shortcuts")

# Handle context-sensitive help requests (F1 key)
# @param current_element: Control - element requesting help
func show_context_help(current_element: Control) -> void:
	assert(false, "Must implement show_context_help")

# Enable/disable specific input methods
# @param input_type: String - "keyboard", "mouse", "gamepad"
# @param enabled: bool - whether to enable this input method
func set_input_method_enabled(input_type: String, enabled: bool) -> void:
	assert(false, "Must implement set_input_method_enabled")