extends Control
class_name MediaEventScene

# Media event scene with sentiment display and response selection
# Interactive interface for handling media events and measuring response impact

@onready var event_title: Label = $MainContainer/HeaderContainer/EventTitle
@onready var event_type_label: Label = $MainContainer/HeaderContainer/EventTypeUrgency/EventTypeLabel
@onready var urgency_label: Label = $MainContainer/HeaderContainer/EventTypeUrgency/UrgencyLabel
@onready var time_pressure_label: Label = $MainContainer/HeaderContainer/TimePressureContainer/TimePressureLabel
@onready var event_description: RichTextLabel = $MainContainer/ContentContainer/LeftPanel/EventDescriptionPanel/EventDescription
@onready var sentiment_bar: ProgressBar = $MainContainer/ContentContainer/LeftPanel/SentimentContainer/SentimentMeter/SentimentBar
@onready var sentiment_label: Label = $MainContainer/ContentContainer/LeftPanel/SentimentContainer/SentimentMeter/SentimentLabel
@onready var response_options_list: VBoxContainer = $MainContainer/ContentContainer/RightPanel/ResponseOptionsContainer/ResponseOptionsList
@onready var response_preview: RichTextLabel = $MainContainer/ContentContainer/RightPanel/ResponsePreviewContainer/ResponsePreviewPanel/ResponsePreviewContent/PreviewText
@onready var sentiment_impact_label: Label = $MainContainer/ContentContainer/RightPanel/ResponsePreviewContainer/ResponsePreviewPanel/ResponsePreviewContent/ImpactContainer/SentimentImpactLabel
@onready var risk_level_label: Label = $MainContainer/ContentContainer/RightPanel/ResponsePreviewContainer/ResponsePreviewPanel/ResponsePreviewContent/ImpactContainer/RiskLevelLabel
@onready var submit_button: Button = $MainContainer/ActionContainer/SubmitResponseButton
@onready var back_button: Button = $MainContainer/ActionContainer/BackButton
@onready var help_button: Button = $MainContainer/ActionContainer/RequestHelpButton

var media_controller: MediaEventController
var tooltip_manager: TooltipManager
var notification_system: NotificationSystem
var accessibility_manager: AccessibilityManager
var navigation_controller: NavigationController

var current_event: MediaEvent
var available_responses: Array[MediaResponse] = []
var selected_response: MediaResponse = null
var response_buttons: Array[Button] = []

signal response_completed(outcome: Dictionary)
signal help_requested(event: MediaEvent)

func _ready():
	# Get managers
	tooltip_manager = get_node("/root/TooltipManager") if has_node("/root/TooltipManager") else null
	notification_system = get_node("/root/NotificationSystem") if has_node("/root/NotificationSystem") else null
	accessibility_manager = get_node("/root/AccessibilityManager") if has_node("/root/AccessibilityManager") else null
	navigation_controller = get_node("/root/NavigationController") if has_node("/root/NavigationController") else null

	# Initialize controller
	media_controller = MediaEventController.new()
	media_controller.media_event_presented.connect(_on_media_event_presented)
	media_controller.response_submitted.connect(_on_response_submitted)
	media_controller.sentiment_updated.connect(_on_sentiment_updated)
	media_controller.media_event_completed.connect(_on_media_event_completed)

	# Setup UI
	_update_localization()
	_setup_tooltips()

	# Initialize media system
	media_controller.initialize_media_system()

func receive_transition_data(data: Dictionary):
	"""Receive transition data from navigation"""
	if data.has("media_event"):
		var event = data.media_event as MediaEvent
		if event:
			_present_media_event(event)

func _present_media_event(event: MediaEvent):
	"""Present media event to user"""
	current_event = event
	media_controller.present_media_event(event)

func _on_media_event_presented(event: MediaEvent, options: Array[MediaResponse]):
	"""Handle media event presentation"""
	current_event = event
	available_responses = options

	# Update event display
	_update_event_display(event)

	# Create response option buttons
	_create_response_buttons(options)

	# Update sentiment display
	_update_current_sentiment()

func _update_event_display(event: MediaEvent):
	"""Update event information display"""
	event_title.text = event.title
	event_type_label.text = tr("media.event_type." + event.event_type)
	event_description.text = event.description

	# Update urgency display
	match event.urgency_level:
		"low":
			urgency_label.text = tr("media.urgency_low")
			urgency_label.add_theme_color_override("font_color", Color.GREEN)
		"medium":
			urgency_label.text = tr("media.urgency_medium")
			urgency_label.add_theme_color_override("font_color", Color.YELLOW)
		"high":
			urgency_label.text = tr("media.urgency_high")
			urgency_label.add_theme_color_override("font_color", Color.RED)

	# Update time pressure
	if event.time_pressure > 0:
		time_pressure_label.text = tr("media.time_pressure_hours") % event.time_pressure
	else:
		time_pressure_label.text = tr("media.no_time_pressure")

func _create_response_buttons(options: Array[MediaResponse]):
	"""Create buttons for response options"""
	# Clear existing buttons
	for button in response_buttons:
		button.queue_free()
	response_buttons.clear()

	# Create new buttons
	for i in range(options.size()):
		var response = options[i]
		var button = Button.new()

		button.text = response.response_text
		button.custom_minimum_size = Vector2(0, 60)
		button.autowrap = true

		# Style button based on response type
		_style_response_button(button, response)

		# Connect signals
		button.pressed.connect(_on_response_button_pressed.bind(response))
		button.mouse_entered.connect(_on_response_button_hovered.bind(response))

		# Add tooltip
		if tooltip_manager:
			var tooltip_data = _create_response_tooltip(response)
			tooltip_manager.register_tooltip_target(button, tooltip_data)

		response_options_list.add_child(button)
		response_buttons.append(button)

func _style_response_button(button: Button, response: MediaResponse):
	"""Style response button based on type and risk"""
	# Color-code by risk level
	match response.risk_level:
		"low":
			button.modulate = Color(0.9, 1.0, 0.9)  # Light green
		"medium":
			button.modulate = Color(1.0, 1.0, 0.9)  # Light yellow
		"high":
			button.modulate = Color(1.0, 0.9, 0.9)  # Light red

	# Special styling for constitutional compliance
	if response.constitutional_compliance:
		button.add_theme_color_override("font_color", Color.BLUE)

func _create_response_tooltip(response: MediaResponse) -> TooltipData:
	"""Create tooltip data for response option"""
	if not tooltip_manager:
		return null

	var tooltip = TooltipData.new()
	tooltip.title = tr("media.response_tooltip.title")
	tooltip.explanation = response.explanation
	tooltip.contributing_factors = [
		tr("media.response_tooltip.sentiment") % response.sentiment_change,
		tr("media.response_tooltip.risk") % tr("media.risk." + response.risk_level),
		tr("media.response_tooltip.type") % tr("media.response_type." + response.response_type)
	]

	return tooltip

func _on_response_button_pressed(response: MediaResponse):
	"""Handle response button press"""
	selected_response = response

	# Update all buttons to show selection
	for i in range(response_buttons.size()):
		var button = response_buttons[i]
		var button_response = available_responses[i]

		if button_response == response:
			button.button_pressed = true
		else:
			button.button_pressed = false

	# Update preview
	_update_response_preview(response)

	# Enable submit button
	submit_button.disabled = false

func _on_response_button_hovered(response: MediaResponse):
	"""Handle response button hover for preview"""
	if selected_response == null:
		_update_response_preview(response)

func _update_response_preview(response: MediaResponse):
	"""Update response preview panel"""
	response_preview.text = "[b]" + tr("media.preview_response") + "[/b]\n\n" + response.explanation

	# Update impact indicators
	var sentiment_change = response.sentiment_change
	var impact_text = ""
	if sentiment_change > 0:
		impact_text = tr("media.positive_impact") % sentiment_change
		sentiment_impact_label.add_theme_color_override("font_color", Color.GREEN)
	elif sentiment_change < 0:
		impact_text = tr("media.negative_impact") % abs(sentiment_change)
		sentiment_impact_label.add_theme_color_override("font_color", Color.RED)
	else:
		impact_text = tr("media.neutral_impact")
		sentiment_impact_label.add_theme_color_override("font_color", Color.WHITE)

	sentiment_impact_label.text = impact_text

	# Update risk level
	risk_level_label.text = tr("media.risk_display") % tr("media.risk." + response.risk_level)
	match response.risk_level:
		"low":
			risk_level_label.add_theme_color_override("font_color", Color.GREEN)
		"medium":
			risk_level_label.add_theme_color_override("font_color", Color.YELLOW)
		"high":
			risk_level_label.add_theme_color_override("font_color", Color.RED)

func _update_current_sentiment():
	"""Update current media sentiment display"""
	# Get current sentiment from controller
	var current_sentiment = 0.0  # This would come from media_controller
	if media_controller.simulation_api:
		current_sentiment = media_controller.simulation_api.get_media_sentiment()

	# Convert to 0-100 range for progress bar
	var sentiment_percentage = (current_sentiment + 1.0) * 50.0
	sentiment_bar.value = sentiment_percentage

	# Update sentiment label
	var sentiment_text = ""
	if current_sentiment > 0.3:
		sentiment_text = tr("media.sentiment.very_positive")
		sentiment_bar.add_theme_color_override("fill", Color.GREEN)
	elif current_sentiment > 0.1:
		sentiment_text = tr("media.sentiment.positive")
		sentiment_bar.add_theme_color_override("fill", Color.LIGHT_GREEN)
	elif current_sentiment > -0.1:
		sentiment_text = tr("media.sentiment.neutral")
		sentiment_bar.add_theme_color_override("fill", Color.GRAY)
	elif current_sentiment > -0.3:
		sentiment_text = tr("media.sentiment.negative")
		sentiment_bar.add_theme_color_override("fill", Color.ORANGE)
	else:
		sentiment_text = tr("media.sentiment.very_negative")
		sentiment_bar.add_theme_color_override("fill", Color.RED)

	sentiment_label.text = sentiment_text

func _update_localization():
	"""Update all text with current localization"""
	# Header
	$MainContainer/HeaderContainer/TimePressureContainer/TimePressureLabel.text = tr("media.time_pressure")

	# Left panel
	$MainContainer/ContentContainer/LeftPanel/EventDescriptionTitle.text = tr("media.event_description")
	$MainContainer/ContentContainer/LeftPanel/SentimentContainer/SentimentTitle.text = tr("media.current_sentiment")

	# Right panel
	$MainContainer/ContentContainer/RightPanel/ResponseOptionsTitle.text = tr("media.response_options")
	$MainContainer/ContentContainer/RightPanel/ResponsePreviewContainer/ResponsePreviewTitle.text = tr("media.response_preview")

	# Action buttons
	back_button.text = tr("common.back")
	submit_button.text = tr("media.submit_response")
	help_button.text = tr("media.request_help")

func _setup_tooltips():
	"""Setup explanatory tooltips for constitutional transparency"""
	if not tooltip_manager:
		return

	# Sentiment meter tooltip
	var sentiment_tooltip = TooltipData.new()
	sentiment_tooltip.title = tr("media.tooltip.sentiment_title")
	sentiment_tooltip.explanation = tr("media.tooltip.sentiment_explanation")
	sentiment_tooltip.contributing_factors = [
		tr("media.tooltip.sentiment_factor1"),
		tr("media.tooltip.sentiment_factor2"),
		tr("media.tooltip.sentiment_factor3")
	]
	tooltip_manager.register_tooltip_target(sentiment_bar.get_parent(), sentiment_tooltip)

# Button event handlers

func _on_submit_response_pressed():
	"""Handle submit response button press"""
	if not selected_response:
		return

	# Show confirmation dialog
	if notification_system:
		var confirmation_text = tr("media.response_confirmation") % selected_response.response_text
		var result = await notification_system.show_modal_dialog(
			tr("media.confirm_title"),
			confirmation_text,
			["common.confirm", "common.cancel"]
		)

		if result == "common.confirm":
			_submit_response()

func _submit_response():
	"""Submit selected response"""
	if not selected_response or not media_controller:
		return

	# Submit response through controller
	var outcome = media_controller.submit_response(selected_response)

	if outcome.success:
		if notification_system:
			notification_system.show_notification(
				tr("media.response_submitted"),
				"success",
				3.0
			)
	else:
		if notification_system:
			notification_system.show_notification(
				tr("media.response_failed"),
				"error",
				3.0
			)

func _on_response_submitted(response: MediaResponse):
	"""Handle response submission signal"""
	# Response has been processed
	pass

func _on_sentiment_updated(new_sentiment: float, change: float):
	"""Handle sentiment update"""
	_update_current_sentiment()

	# Show sentiment change notification
	if abs(change) > 0.05:  # Significant change
		var change_text = ""
		if change > 0:
			change_text = tr("media.sentiment_improved") % change
		else:
			change_text = tr("media.sentiment_declined") % abs(change)

		if notification_system:
			var notification_type = "success" if change > 0 else "warning"
			notification_system.show_notification(change_text, notification_type, 4.0)

func _on_media_event_completed(event: MediaEvent, outcome: Dictionary):
	"""Handle media event completion"""
	response_completed.emit(outcome)

	# Navigate back to dashboard after delay
	await get_tree().create_timer(2.0).timeout

	if navigation_controller:
		navigation_controller.navigate_to_screen("dashboard")

func _on_back_button_pressed():
	"""Handle back button press"""
	if navigation_controller:
		navigation_controller.navigate_back()

func _on_request_help_pressed():
	"""Handle help request button press"""
	help_requested.emit(current_event)
	_show_help_dialog()

func _show_help_dialog():
	"""Show help dialog with media strategy guidance"""
	var help_content = tr("media.help.overview") + "\n\n"

	help_content += tr("media.help.response_types") + "\n"
	help_content += "• " + tr("media.help.prepared") + "\n"
	help_content += "• " + tr("media.help.personal") + "\n"
	help_content += "• " + tr("media.help.policy") + "\n\n"

	help_content += tr("media.help.risk_levels") + "\n"
	help_content += "• " + tr("media.help.low_risk") + "\n"
	help_content += "• " + tr("media.help.medium_risk") + "\n"
	help_content += "• " + tr("media.help.high_risk") + "\n\n"

	help_content += tr("media.help.constitutional") + "\n"
	help_content += tr("media.help.transparency_bonus")

	if notification_system:
		notification_system.show_modal_dialog(
			tr("media.help.title"),
			help_content,
			["common.ok"]
		)

# Input handling

func _input(event):
	"""Handle input for keyboard navigation"""
	if event.is_action_pressed("show_help"):
		_show_help_dialog()
		get_viewport().set_input_as_handled()

# Constitutional compliance

func _notification(what):
	"""Handle system notifications"""
	match what:
		NOTIFICATION_TRANSLATION_CHANGED:
			_update_localization()

func get_transparency_data() -> Dictionary:
	"""Get transparency data for constitutional compliance"""
	return media_controller.get_transparency_data() if media_controller else {}

func validate_educational_value() -> Dictionary:
	"""Validate that media events provide educational value"""
	return {
		"response_explanations": available_responses.size() > 0,
		"impact_preview": selected_response != null,
		"risk_awareness": true,
		"sentiment_tracking": true,
		"help_available": true,
		"transparency_options": _has_transparency_option()
	}

func _has_transparency_option() -> bool:
	"""Check if transparency response option is available"""
	for response in available_responses:
		if response.constitutional_compliance:
			return true
	return false