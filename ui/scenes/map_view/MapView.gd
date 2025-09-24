extends Control
class_name MapView

# Map view scene with Netherlands geography and regional filtering
# Interactive regional analysis and campaign planning interface

@onready var region_name_label: Label = $MainContainer/LeftPanel/RegionInfoContainer/RegionInfoPanel/RegionInfoContent/RegionNameLabel
@onready var support_label: Label = $MainContainer/LeftPanel/RegionInfoContainer/RegionInfoPanel/RegionInfoContent/SupportLabel
@onready var trend_label: Label = $MainContainer/LeftPanel/RegionInfoContainer/RegionInfoPanel/RegionInfoContent/TrendLabel
@onready var priority_label: Label = $MainContainer/LeftPanel/RegionInfoContainer/RegionInfoPanel/RegionInfoContent/PriorityLabel
@onready var demographics_label: Label = $MainContainer/LeftPanel/RegionInfoContainer/RegionInfoPanel/RegionInfoContent/DemographicsLabel
@onready var actions_button: Button = $MainContainer/LeftPanel/RegionInfoContainer/RegionInfoPanel/RegionInfoContent/ActionsButton

@onready var support_mode_button: Button = $MainContainer/MapContainer/MapToolbar/SupportModeButton
@onready var demographic_mode_button: Button = $MainContainer/MapContainer/MapToolbar/DemographicModeButton
@onready var activity_mode_button: Button = $MainContainer/MapContainer/MapToolbar/ActivityModeButton

@onready var map_canvas: Control = $MainContainer/MapContainer/MapDisplayPanel/MapScrollContainer/MapCanvas

@onready var total_regions_label: Label = $MainContainer/RightPanel/StatsContainer/StatsContent/TotalRegionsLabel
@onready var average_support_label: Label = $MainContainer/RightPanel/StatsContainer/StatsContent/AverageSupportLabel
@onready var strongholds_count_label: Label = $MainContainer/RightPanel/StatsContainer/StatsContent/StrongholdsCountLabel
@onready var opportunities_count_label: Label = $MainContainer/RightPanel/StatsContainer/StatsContent/OpportunitiesCountLabel

# Filter checkboxes
@onready var high_support_check: CheckBox = $MainContainer/LeftPanel/FilterContainer/FilterGrid/SupportLevelContainer/SupportLevelOptions/HighSupportCheck
@onready var medium_support_check: CheckBox = $MainContainer/LeftPanel/FilterContainer/FilterGrid/SupportLevelContainer/SupportLevelOptions/MediumSupportCheck
@onready var low_support_check: CheckBox = $MainContainer/LeftPanel/FilterContainer/FilterGrid/SupportLevelContainer/SupportLevelOptions/LowSupportCheck

var map_controller: MapViewController
var tooltip_manager: TooltipManager
var notification_system: NotificationSystem
var accessibility_manager: AccessibilityManager
var navigation_controller: NavigationController

var region_buttons: Dictionary = {}
var selected_region: String = ""
var current_view_mode: String = "support"
var active_filters: Dictionary = {}

signal region_clicked(region_id: String)
signal campaign_planned(region_id: String, plan: Dictionary)

func _ready():
	# Get managers
	tooltip_manager = get_node("/root/TooltipManager") if has_node("/root/TooltipManager") else null
	notification_system = get_node("/root/NotificationSystem") if has_node("/root/NotificationSystem") else null
	accessibility_manager = get_node("/root/AccessibilityManager") if has_node("/root/AccessibilityManager") else null
	navigation_controller = get_node("/root/NavigationController") if has_node("/root/NavigationController") else null

	# Initialize controller
	map_controller = MapViewController.new()
	map_controller.region_selected.connect(_on_region_selected)
	map_controller.region_data_updated.connect(_on_region_data_updated)
	map_controller.filter_applied.connect(_on_filter_applied)

	# Setup UI
	_update_localization()
	_setup_view_mode_buttons()
	_setup_map_regions()
	_initialize_statistics()

	# Initialize map
	map_controller.initialize_map()

func receive_transition_data(data: Dictionary):
	"""Receive transition data from navigation"""
	if data.has("filter_type") and data.has("filter_value"):
		map_controller.apply_filter(data.filter_type, data.filter_value)

	if data.has("selected_region"):
		_select_region(data.selected_region)

func _setup_view_mode_buttons():
	"""Setup view mode button group"""
	var button_group = ButtonGroup.new()
	support_mode_button.button_group = button_group
	demographic_mode_button.button_group = button_group
	activity_mode_button.button_group = button_group

func _setup_map_regions():
	"""Setup interactive map regions"""
	var all_regions = map_controller.get_all_regions()

	# Create region buttons on map canvas
	for region in all_regions:
		_create_region_button(region)

func _create_region_button(region: GeographicRegion):
	"""Create interactive button for map region"""
	var region_button = Button.new()
	region_button.name = region.region_id
	region_button.text = region.region_name
	region_button.custom_minimum_size = Vector2(80, 50)

	# Position button (simplified positioning - would use actual geographic coordinates)
	var position = _get_region_position(region.region_id)
	region_button.position = position

	# Style based on region data
	_style_region_button(region_button, region)

	# Connect signals
	region_button.pressed.connect(_on_region_button_pressed.bind(region.region_id))
	region_button.mouse_entered.connect(_on_region_button_hovered.bind(region.region_id))

	# Add tooltip
	if tooltip_manager:
		var tooltip_data = _create_region_tooltip(region)
		tooltip_manager.register_tooltip_target(region_button, tooltip_data)

	map_canvas.add_child(region_button)
	region_buttons[region.region_id] = region_button

func _get_region_position(region_id: String) -> Vector2:
	"""Get approximate position for region on map"""
	# Simplified positioning for Dutch provinces
	var positions = {
		"noord_holland": Vector2(200, 150),
		"zuid_holland": Vector2(150, 200),
		"utrecht": Vector2(200, 200),
		"gelderland": Vector2(300, 250),
		"overijssel": Vector2(350, 150),
		"flevoland": Vector2(250, 150),
		"friesland": Vector2(250, 50),
		"groningen": Vector2(350, 50),
		"drenthe": Vector2(300, 100),
		"noord_brabant": Vector2(200, 350),
		"limburg": Vector2(300, 400),
		"zeeland": Vector2(100, 300)
	}

	return positions.get(region_id, Vector2(400, 300))

func _style_region_button(button: Button, region: GeographicRegion):
	"""Style region button based on current view mode and data"""
	var region_data = map_controller.get_region_data(region.region_id)

	match current_view_mode:
		"support":
			_style_by_support_level(button, region_data)
		"demographics":
			_style_by_demographics(button, region_data)
		"campaign_activity":
			_style_by_activity(button, region_data)

func _style_by_support_level(button: Button, region_data: Dictionary):
	"""Style button by support level"""
	var support = region_data.get("player_support", 0.0)
	var priority = region_data.get("priority", "stable")

	match priority:
		"stronghold":
			button.modulate = Color.GREEN
		"opportunity":
			button.modulate = Color.BLUE
		"target":
			button.modulate = Color.YELLOW
		"at_risk":
			button.modulate = Color.RED
		_:
			button.modulate = Color.GRAY

func _style_by_demographics(button: Button, region_data: Dictionary):
	"""Style button by demographic characteristics"""
	# This would style based on demographic data
	button.modulate = Color.CYAN

func _style_by_activity(button: Button, region_data: Dictionary):
	"""Style button by campaign activity"""
	# This would style based on recent campaign activity
	button.modulate = Color.MAGENTA

func _create_region_tooltip(region: GeographicRegion) -> TooltipData:
	"""Create tooltip data for region"""
	if not tooltip_manager:
		return null

	var region_data = map_controller.get_region_data(region.region_id)
	var tooltip = TooltipData.new()

	tooltip.title = region.region_name
	tooltip.explanation = tr("map.region_tooltip.explanation") % region.region_name
	tooltip.contributing_factors = [
		tr("map.region_tooltip.support") % region_data.get("player_support", 0.0),
		tr("map.region_tooltip.trend") % region_data.get("trend", 0.0),
		tr("map.region_tooltip.priority") % tr("map.priority." + region_data.get("priority", "stable"))
	]

	return tooltip

func _initialize_statistics():
	"""Initialize regional statistics display"""
	_update_statistics()

func _update_statistics():
	"""Update statistics panel"""
	var all_regions = map_controller.get_all_regions()
	total_regions_label.text = tr("map.total_regions_count") % all_regions.size()

	# Calculate statistics
	var total_support = 0.0
	var strongholds = 0
	var opportunities = 0

	for region in all_regions:
		var region_data = map_controller.get_region_data(region.region_id)
		var support = region_data.get("player_support", 0.0)
		var priority = region_data.get("priority", "stable")

		total_support += support

		match priority:
			"stronghold":
				strongholds += 1
			"opportunity":
				opportunities += 1

	var average_support = total_support / all_regions.size()
	average_support_label.text = tr("map.average_support_value") % average_support
	strongholds_count_label.text = tr("map.strongholds_count_value") % strongholds
	opportunities_count_label.text = tr("map.opportunities_count_value") % opportunities

func _update_localization():
	"""Update all text with current localization"""
	# Filter labels
	$MainContainer/LeftPanel/FilterContainer/FilterTitle.text = tr("map.filters")

	# Statistics labels
	$MainContainer/RightPanel/StatsContainer/StatsTitle.text = tr("map.statistics")
	$MainContainer/RightPanel/LegendContainer/LegendTitle.text = tr("map.legend")

	# Legend labels
	$MainContainer/RightPanel/LegendContainer/LegendContent/StrongholdLegend/StrongholdLabel.text = tr("map.stronghold")
	$MainContainer/RightPanel/LegendContainer/LegendContent/OpportunityLegend/OpportunityLabel.text = tr("map.opportunity")
	$MainContainer/RightPanel/LegendContainer/LegendContent/TargetLegend/TargetLabel.text = tr("map.target")
	$MainContainer/RightPanel/LegendContainer/LegendContent/AtRiskLegend/AtRiskLabel.text = tr("map.at_risk")

	# Action buttons
	actions_button.text = tr("map.plan_campaign")

# Event handlers

func _on_region_button_pressed(region_id: String):
	"""Handle region button press"""
	_select_region(region_id)
	map_controller.handle_region_click(region_id)

func _on_region_button_hovered(region_id: String):
	"""Handle region button hover"""
	map_controller.handle_region_hover(region_id)

func _select_region(region_id: String):
	"""Select region and update info panel"""
	selected_region = region_id

	# Update region button styles
	for button_region_id in region_buttons.keys():
		var button = region_buttons[button_region_id]
		if button_region_id == region_id:
			button.add_theme_color_override("font_color", Color.WHITE)
		else:
			button.remove_theme_color_override("font_color")

	# Request region data
	map_controller.select_region(region_id)

func _on_region_selected(region_data: Dictionary):
	"""Handle region selection from controller"""
	_update_region_info_panel(region_data)

func _update_region_info_panel(region_data: Dictionary):
	"""Update region information panel"""
	if region_data.is_empty():
		return

	var region = region_data.get("region")
	if not region:
		return

	region_name_label.text = region.region_name

	var support = region_data.get("player_support", 0.0)
	support_label.text = tr("map.support_level_value") % support

	var trend = region_data.get("trend", 0.0)
	var trend_text = ""
	if trend > 0.1:
		trend_text = tr("map.trend_positive") % trend
		trend_label.add_theme_color_override("font_color", Color.GREEN)
	elif trend < -0.1:
		trend_text = tr("map.trend_negative") % abs(trend)
		trend_label.add_theme_color_override("font_color", Color.RED)
	else:
		trend_text = tr("map.trend_stable")
		trend_label.add_theme_color_override("font_color", Color.WHITE)
	trend_label.text = trend_text

	var priority = region_data.get("priority", "stable")
	priority_label.text = tr("map.priority_value") % tr("map.priority." + priority)

	# Enable campaign planning
	actions_button.disabled = false

func _on_region_data_updated(region_id: String, data: Dictionary):
	"""Handle region data update from controller"""
	if region_id in region_buttons:
		var button = region_buttons[region_id]
		var region = data.get("region")
		if region:
			_style_region_button(button, region)

	# Update statistics
	_update_statistics()

func _on_filter_applied(filter_type: String, filter_value: String):
	"""Handle filter application"""
	active_filters[filter_type] = filter_value
	_update_filtered_display()

func _update_filtered_display():
	"""Update display based on active filters"""
	# Update region button visibility/styling based on filters
	for region_id in region_buttons.keys():
		var button = region_buttons[region_id]
		var should_show = _region_passes_filters(region_id)
		button.visible = should_show

func _region_passes_filters(region_id: String) -> bool:
	"""Check if region passes current filter criteria"""
	# This would implement actual filter logic
	return true

# Filter event handlers

func _on_filter_changed():
	"""Handle filter checkbox changes"""
	var applied_filters = []

	# Check support level filters
	if high_support_check.button_pressed:
		applied_filters.append("high_support")
	if medium_support_check.button_pressed:
		applied_filters.append("medium_support")
	if low_support_check.button_pressed:
		applied_filters.append("low_support")

	# Apply combined filters
	if applied_filters.size() > 0:
		map_controller.apply_filter("support_level", ",".join(applied_filters))

func _on_apply_filter_pressed():
	"""Handle apply filter button press"""
	_on_filter_changed()

func _on_clear_filter_pressed():
	"""Handle clear filter button press"""
	# Clear all checkboxes
	high_support_check.button_pressed = false
	medium_support_check.button_pressed = false
	low_support_check.button_pressed = false

	# Clear controller filter
	map_controller.clear_filter()

	# Show all regions
	for button in region_buttons.values():
		button.visible = true

# View mode handlers

func _on_support_mode_pressed():
	"""Switch to support view mode"""
	current_view_mode = "support"
	map_controller.set_view_mode("support")
	_refresh_region_styling()

func _on_demographic_mode_pressed():
	"""Switch to demographic view mode"""
	current_view_mode = "demographics"
	map_controller.set_view_mode("demographics")
	_refresh_region_styling()

func _on_activity_mode_pressed():
	"""Switch to campaign activity view mode"""
	current_view_mode = "campaign_activity"
	map_controller.set_view_mode("campaign_activity")
	_refresh_region_styling()

func _refresh_region_styling():
	"""Refresh styling of all region buttons"""
	var all_regions = map_controller.get_all_regions()
	for region in all_regions:
		if region.region_id in region_buttons:
			var button = region_buttons[region.region_id]
			_style_region_button(button, region)

func _on_legend_button_pressed():
	"""Handle legend button press"""
	# Toggle legend visibility or show legend dialog
	var legend_content = $MainContainer/RightPanel/LegendContainer
	legend_content.visible = not legend_content.visible

# Campaign planning

func _on_plan_campaign_pressed():
	"""Handle campaign planning button press"""
	if selected_region == "":
		return

	# Show campaign planning dialog
	_show_campaign_planning_dialog()

func _show_campaign_planning_dialog():
	"""Show campaign planning dialog for selected region"""
	var budget = 50000  # This would come from game state
	var campaign_plan = map_controller.plan_regional_campaign(selected_region, budget)

	var dialog_content = tr("map.campaign_plan_title") % selected_region + "\n\n"
	dialog_content += tr("map.plan_total_cost") % campaign_plan.total_cost + "\n"
	dialog_content += tr("map.plan_expected_impact") % campaign_plan.expected_impact.polling_boost + "\n\n"
	dialog_content += tr("map.plan_actions") + "\n"

	for action in campaign_plan.actions:
		dialog_content += "• " + tr("action." + action.action_type) + " (€" + str(action.cost) + ")\n"

	if notification_system:
		var result = await notification_system.show_modal_dialog(
			tr("map.campaign_planning"),
			dialog_content,
			["map.execute_plan", "common.cancel"]
		)

		if result == "map.execute_plan":
			campaign_planned.emit(selected_region, campaign_plan)

# Input handling

func _input(event):
	"""Handle input for keyboard navigation"""
	if event.is_action_pressed("show_help"):
		_show_help_dialog()
		get_viewport().set_input_as_handled()

func _show_help_dialog():
	"""Show help dialog with map usage instructions"""
	var help_content = tr("map.help.overview") + "\n\n"
	help_content += tr("map.help.regions") + "\n"
	help_content += tr("map.help.filters") + "\n"
	help_content += tr("map.help.view_modes") + "\n"
	help_content += tr("map.help.campaign_planning")

	if notification_system:
		notification_system.show_modal_dialog(
			tr("map.help.title"),
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
	return map_controller.get_transparency_data() if map_controller else {}

func validate_geographic_accuracy() -> bool:
	"""Validate that geographic representation is accurate"""
	return map_controller.validate_geographic_accuracy() if map_controller else false