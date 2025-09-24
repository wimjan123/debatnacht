extends Control
class_name Dashboard

# Dashboard scene connected to DashboardController for campaign management
# Displays KPIs, available actions, polling data, and regional information

@onready var polling_value: Label = $MainContainer/LeftPanel/KPIContainer/KPIGrid/PollingCard/VBox/PollingValue
@onready var polling_trend: Label = $MainContainer/LeftPanel/KPIContainer/KPIGrid/PollingCard/VBox/PollingTrend
@onready var seats_value: Label = $MainContainer/LeftPanel/KPIContainer/KPIGrid/SeatsCard/VBox/SeatsValue
@onready var funds_value: Label = $MainContainer/LeftPanel/KPIContainer/KPIGrid/FundsCard/VBox/FundsValue
@onready var days_value: Label = $MainContainer/LeftPanel/KPIContainer/KPIGrid/DaysCard/VBox/DaysValue
@onready var actions_remaining: Label = $MainContainer/LeftPanel/ActionsContainer/ActionsRemaining
@onready var actions_list: VBoxContainer = $MainContainer/LeftPanel/ActionsContainer/ActionsList
@onready var media_list: VBoxContainer = $MainContainer/RightPanel/MediaContainer/MediaList
@onready var coalition_info: RichTextLabel = $MainContainer/RightPanel/CoalitionContainer/CoalitionInfo

@onready var overview_button: Button = $MainContainer/CentralPanel/ViewModeContainer/OverviewButton
@onready var detailed_button: Button = $MainContainer/CentralPanel/ViewModeContainer/DetailedButton
@onready var regional_button: Button = $MainContainer/CentralPanel/ViewModeContainer/RegionalButton

@onready var overview_content: Control = $MainContainer/CentralPanel/ContentArea/ContentStack/OverviewContent
@onready var detailed_content: Control = $MainContainer/CentralPanel/ContentArea/ContentStack/DetailedContent
@onready var regional_content: Control = $MainContainer/CentralPanel/ContentArea/ContentStack/RegionalContent

@onready var trend_analysis: RichTextLabel = $MainContainer/CentralPanel/ContentArea/ContentStack/DetailedContent/TrendAnalysis
@onready var regional_grid: GridContainer = $MainContainer/CentralPanel/ContentArea/ContentStack/RegionalContent/RegionalGrid

var dashboard_controller: DashboardController
var tooltip_manager: TooltipManager
var notification_system: NotificationSystem
var accessibility_manager: AccessibilityManager
var navigation_controller: NavigationController

var current_view_mode: String = "overview"
var kpi_cards: Dictionary = {}
var tutorial_mode: bool = false

signal action_selected(action: CampaignAction)
signal region_selected(region_name: String)
signal media_event_clicked(event: MediaEvent)

func _ready():
	# Get managers
	tooltip_manager = get_node("/root/TooltipManager") if has_node("/root/TooltipManager") else null
	notification_system = get_node("/root/NotificationSystem") if has_node("/root/NotificationSystem") else null
	accessibility_manager = get_node("/root/AccessibilityManager") if has_node("/root/AccessibilityManager") else null
	navigation_controller = get_node("/root/NavigationController") if has_node("/root/NavigationController") else null

	# Initialize controller
	dashboard_controller = DashboardController.new()
	dashboard_controller.kpi_updated.connect(_on_kpi_updated)
	dashboard_controller.campaign_action_available.connect(_on_campaign_action_available)
	dashboard_controller.phase_transition.connect(_on_phase_transition)
	dashboard_controller.dashboard_ready.connect(_on_dashboard_ready)

	# Setup UI
	_setup_kpi_cards()
	_setup_tooltips()
	_setup_view_mode_buttons()
	_update_localization()

	# Initialize dashboard
	dashboard_controller.initialize_dashboard()

func _setup_kpi_cards():
	"""Setup references to KPI display cards"""
	kpi_cards = {
		"national_polling": {
			"value": polling_value,
			"trend": polling_trend,
			"panel": $MainContainer/LeftPanel/KPIContainer/KPIGrid/PollingCard
		},
		"projected_seats": {
			"value": seats_value,
			"panel": $MainContainer/LeftPanel/KPIContainer/KPIGrid/SeatsCard
		},
		"campaign_funds": {
			"value": funds_value,
			"panel": $MainContainer/LeftPanel/KPIContainer/KPIGrid/FundsCard
		},
		"days_remaining": {
			"value": days_value,
			"panel": $MainContainer/LeftPanel/KPIContainer/KPIGrid/DaysCard
		}
	}

func _setup_tooltips():
	"""Setup explanatory tooltips for constitutional transparency"""
	if not tooltip_manager:
		return

	# Polling KPI tooltip
	var polling_tooltip = tooltip_manager.create_metric_tooltip(
		"poll_percentage",
		25.5,
		{"methodology": "weighted_average", "sample_size": 1200}
	)
	tooltip_manager.register_tooltip_target(kpi_cards.national_polling.panel, polling_tooltip)

	# Seats projection tooltip
	var seats_tooltip = tooltip_manager.create_metric_tooltip(
		"projected_seats",
		38,
		{"calculation": "dhondt_method", "confidence": "medium"}
	)
	tooltip_manager.register_tooltip_target(kpi_cards.projected_seats.panel, seats_tooltip)

	# Campaign funds tooltip
	var funds_tooltip = tooltip_manager.create_metric_tooltip(
		"campaign_funds",
		150000,
		{"source": "donations_and_subsidies", "restrictions": "legal_compliance"}
	)
	tooltip_manager.register_tooltip_target(kpi_cards.campaign_funds.panel, funds_tooltip)

func _setup_view_mode_buttons():
	"""Setup view mode button group behavior"""
	var button_group = ButtonGroup.new()
	overview_button.button_group = button_group
	detailed_button.button_group = button_group
	regional_button.button_group = button_group

func _update_localization():
	"""Update all text with current localization"""
	# KPI Labels
	$MainContainer/LeftPanel/KPIContainer/KPITitle.text = tr("dashboard.kpi_title")
	$MainContainer/LeftPanel/KPIContainer/KPIGrid/PollingCard/VBox/PollingLabel.text = tr("dashboard.national_polling")
	$MainContainer/LeftPanel/KPIContainer/KPIGrid/SeatsCard/VBox/SeatsLabel.text = tr("dashboard.projected_seats")
	$MainContainer/LeftPanel/KPIContainer/KPIGrid/SeatsCard/VBox/SeatsNote.text = tr("dashboard.out_of_150")
	$MainContainer/LeftPanel/KPIContainer/KPIGrid/FundsCard/VBox/FundsLabel.text = tr("dashboard.campaign_funds")
	$MainContainer/LeftPanel/KPIContainer/KPIGrid/DaysCard/VBox/DaysLabel.text = tr("dashboard.days_remaining")
	$MainContainer/LeftPanel/KPIContainer/KPIGrid/DaysCard/VBox/DaysNote.text = tr("dashboard.days_to_election")

	# Actions section
	$MainContainer/LeftPanel/ActionsContainer/ActionsTitle.text = tr("dashboard.recommended_actions")

	# View mode buttons
	overview_button.text = tr("dashboard.overview")
	detailed_button.text = tr("dashboard.detailed")
	regional_button.text = tr("dashboard.regional")

	# Content titles
	$MainContainer/CentralPanel/ContentArea/ContentStack/OverviewContent/OverviewTitle.text = tr("dashboard.campaign_overview")
	$MainContainer/CentralPanel/ContentArea/ContentStack/DetailedContent/DetailedTitle.text = tr("dashboard.detailed_analysis")
	$MainContainer/CentralPanel/ContentArea/ContentStack/RegionalContent/RegionalTitle.text = tr("dashboard.regional_breakdown")

	# Right panel
	$MainContainer/RightPanel/MediaContainer/MediaTitle.text = tr("dashboard.media_events")
	$MainContainer/RightPanel/CoalitionContainer/CoalitionTitle.text = tr("dashboard.coalition_status")

func receive_transition_data(data: Dictionary):
	"""Receive transition data from navigation"""
	if data.has("tutorial_mode"):
		tutorial_mode = data.tutorial_mode
		dashboard_controller.set_tutorial_mode(tutorial_mode)

	if data.has("selected_region"):
		_set_regional_focus(data.selected_region)

# Dashboard controller event handlers

func _on_kpi_updated(kpi_type: String, new_value: Variant):
	"""Handle KPI updates from controller"""
	match kpi_type:
		"national_polling":
			_update_polling_display(new_value)
		"projected_seats":
			_update_seats_display(new_value)
		"campaign_funds":
			_update_funds_display(new_value)
		"days_remaining":
			_update_days_display(new_value)
		"polling_trend":
			_update_polling_trend(new_value)
		"actions_remaining":
			_update_actions_remaining(new_value)
		"regional_polling":
			_update_regional_data(new_value)
		"media_sentiment":
			_update_media_sentiment(new_value)

func _update_polling_display(percentage: float):
	"""Update polling percentage display"""
	polling_value.text = "%.1f%%" % percentage

	# Color-code based on performance
	if percentage >= 25.0:
		polling_value.add_theme_color_override("font_color", Color.GREEN)
	elif percentage >= 15.0:
		polling_value.add_theme_color_override("font_color", Color.YELLOW)
	else:
		polling_value.add_theme_color_override("font_color", Color.RED)

func _update_polling_trend(trend: float):
	"""Update polling trend indicator"""
	if abs(trend) < 0.1:
		polling_trend.text = tr("dashboard.no_change")
		polling_trend.add_theme_color_override("font_color", Color.WHITE)
	elif trend > 0:
		polling_trend.text = "+%.1f%%" % trend
		polling_trend.add_theme_color_override("font_color", Color.GREEN)
	else:
		polling_trend.text = "%.1f%%" % trend
		polling_trend.add_theme_color_override("font_color", Color.RED)

func _update_seats_display(seats: int):
	"""Update seat projection display"""
	seats_value.text = str(seats)

	# Color-code based on majority status
	if seats >= 76:  # Majority in 150-seat parliament
		seats_value.add_theme_color_override("font_color", Color.GREEN)
	elif seats >= 50:
		seats_value.add_theme_color_override("font_color", Color.YELLOW)
	else:
		seats_value.add_theme_color_override("font_color", Color.RED)

func _update_funds_display(funds: int):
	"""Update campaign funds display"""
	funds_value.text = "€%s" % _format_currency(funds)

	# Color-code based on fund level
	if funds >= 100000:
		funds_value.add_theme_color_override("font_color", Color.GREEN)
	elif funds >= 25000:
		funds_value.add_theme_color_override("font_color", Color.YELLOW)
	else:
		funds_value.add_theme_color_override("font_color", Color.RED)

func _update_days_display(days: int):
	"""Update days remaining display"""
	days_value.text = str(days)

	# Color-code based on urgency
	if days <= 7:
		days_value.add_theme_color_override("font_color", Color.RED)
	elif days <= 30:
		days_value.add_theme_color_override("font_color", Color.YELLOW)
	else:
		days_value.add_theme_color_override("font_color", Color.WHITE)

func _update_actions_remaining(remaining: int):
	"""Update actions remaining display"""
	actions_remaining.text = tr("dashboard.actions_remaining_count") % remaining

func _format_currency(amount: int) -> String:
	"""Format currency with thousand separators"""
	var str_amount = str(amount)
	var result = ""
	var count = 0

	for i in range(str_amount.length() - 1, -1, -1):
		result = str_amount[i] + result
		count += 1
		if count % 3 == 0 and i > 0:
			result = "," + result

	return result

func _on_campaign_action_available(action: CampaignAction):
	"""Handle new available campaign action"""
	_add_action_to_list(action)

func _add_action_to_list(action: CampaignAction):
	"""Add action button to recommended actions list"""
	var action_button = Button.new()
	action_button.text = tr("action." + action.action_type) + " (€%s)" % _format_currency(action.cost)
	action_button.tooltip_text = tr("action.description." + action.action_type)

	# Color-code by cost
	if action.cost <= 10000:
		action_button.modulate = Color.GREEN
	elif action.cost <= 25000:
		action_button.modulate = Color.YELLOW
	else:
		action_button.modulate = Color.RED

	action_button.pressed.connect(_on_action_selected.bind(action))
	actions_list.add_child(action_button)

	# Limit number of displayed actions
	if actions_list.get_child_count() > 5:
		actions_list.get_child(0).queue_free()

func _on_action_selected(action: CampaignAction):
	"""Handle action selection"""
	action_selected.emit(action)

	# Show action confirmation dialog
	_show_action_confirmation(action)

func _show_action_confirmation(action: CampaignAction):
	"""Show confirmation dialog for campaign action"""
	var confirmation_text = tr("dashboard.action_confirm") % [
		tr("action." + action.action_type),
		_format_currency(action.cost)
	]

	if notification_system:
		var buttons = ["common.confirm", "common.cancel"]
		var result = await notification_system.show_modal_dialog(
			tr("dashboard.action_title"),
			confirmation_text,
			buttons
		)

		if result == "common.confirm":
			_execute_action(action)

func _execute_action(action: CampaignAction):
	"""Execute selected campaign action"""
	var result = dashboard_controller.execute_campaign_action(action)

	if notification_system:
		notification_system.show_campaign_notification(result)

	# Refresh dashboard after action
	dashboard_controller.refresh_dashboard_data()

func _on_phase_transition(new_phase: String):
	"""Handle game phase transition"""
	if notification_system:
		var message = tr("dashboard.phase_transition") % tr("phase." + new_phase)
		notification_system.show_notification(message, "info", 5.0)

	# Update UI for new phase
	_update_phase_ui(new_phase)

func _update_phase_ui(phase: String):
	"""Update UI elements based on game phase"""
	match phase:
		"election":
			# Hide campaign actions during election
			$MainContainer/LeftPanel/ActionsContainer.visible = false
		"coalition":
			# Show coalition building interface
			_show_coalition_interface()
		"parliament":
			# Show parliamentary interface
			_show_parliamentary_interface()

func _on_dashboard_ready():
	"""Handle dashboard initialization completion"""
	dashboard_controller.refresh_dashboard_data()

# View mode handlers

func _on_overview_button_pressed():
	"""Switch to overview view mode"""
	_set_view_mode("overview")

func _on_detailed_button_pressed():
	"""Switch to detailed view mode"""
	_set_view_mode("detailed")

func _on_regional_button_pressed():
	"""Switch to regional view mode"""
	_set_view_mode("regional")

func _set_view_mode(mode: String):
	"""Set dashboard view mode"""
	current_view_mode = mode
	dashboard_controller.set_view_mode(mode)

	# Hide all content panels
	overview_content.visible = false
	detailed_content.visible = false
	regional_content.visible = false

	# Show selected panel
	match mode:
		"overview":
			overview_content.visible = true
		"detailed":
			detailed_content.visible = true
			_load_detailed_view()
		"regional":
			regional_content.visible = true
			_load_regional_view()

func _load_detailed_view():
	"""Load detailed analysis view"""
	var trend_text = tr("dashboard.trend_loading")
	trend_analysis.text = trend_text

	# This would be populated by controller data
	await get_tree().create_timer(0.1).timeout
	trend_text = tr("dashboard.trend_placeholder")
	trend_analysis.text = trend_text

func _load_regional_view():
	"""Load regional breakdown view"""
	# Clear existing regional data
	for child in regional_grid.get_children():
		child.queue_free()

	# Add regional panels (placeholder)
	var regions = ["Noord-Holland", "Zuid-Holland", "Utrecht", "Gelderland", "Noord-Brabant", "Limburg"]

	for region in regions:
		var region_panel = Panel.new()
		region_panel.custom_minimum_size = Vector2(150, 100)

		var vbox = VBoxContainer.new()
		region_panel.add_child(vbox)
		vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)

		var region_label = Label.new()
		region_label.text = region
		vbox.add_child(region_label)

		var support_label = Label.new()
		support_label.text = "23.5%"  # Placeholder
		support_label.add_theme_font_size_override("font_size", 18)
		vbox.add_child(support_label)

		regional_grid.add_child(region_panel)

func _set_regional_focus(region_name: String):
	"""Set focus on specific region"""
	dashboard_controller.set_regional_filter(region_name)
	region_selected.emit(region_name)

# Media and coalition updates

func _update_regional_data(regional_data: Variant):
	"""Update regional breakdown display"""
	if current_view_mode == "regional":
		_load_regional_view()

func _update_media_sentiment(sentiment: float):
	"""Update media sentiment display"""
	# Update media section with sentiment indicator
	pass

func _show_coalition_interface():
	"""Show coalition building interface"""
	coalition_info.text = tr("dashboard.coalition_building_available")

func _show_parliamentary_interface():
	"""Show parliamentary voting interface"""
	coalition_info.text = tr("dashboard.parliament_active")

# Input handling

func _input(event):
	"""Handle input for keyboard navigation"""
	if event.is_action_pressed("show_help"):
		_show_dashboard_help()
		get_viewport().set_input_as_handled()

func _show_dashboard_help():
	"""Show dashboard help information"""
	var help_content = tr("dashboard.help.overview") + "\n\n"
	help_content += tr("dashboard.help.kpis") + "\n"
	help_content += tr("dashboard.help.actions") + "\n"
	help_content += tr("dashboard.help.views")

	if notification_system:
		notification_system.show_modal_dialog(
			tr("dashboard.help.title"),
			help_content,
			["common.ok"]
		)

# Constitutional compliance

func _notification(what):
	"""Handle system notifications"""
	match what:
		NOTIFICATION_TRANSLATION_CHANGED:
			_update_localization()

func get_transparency_data() -> Dictionary:
	"""Get transparency data for constitutional compliance"""
	return dashboard_controller.get_transparency_data() if dashboard_controller else {}

func validate_data_integrity() -> bool:
	"""Validate dashboard data integrity"""
	return dashboard_controller.validate_data_integrity() if dashboard_controller else false