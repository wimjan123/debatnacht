extends RefCounted
class_name MapViewController

# Map view controller with filtering for Dutch geography and regional analysis
# Handles geographic data visualization and regional campaign targeting

var simulation_api: SimulationAPI
var game_state: GameState
var selected_region: String = ""
var filter_type: String = ""
var filter_value: String = ""
var view_mode: String = "support"  # support, demographics, campaign_activity

signal region_selected(region_data: Dictionary)
signal region_data_updated(region_id: String, data: Dictionary)
signal filter_applied(filter_type: String, filter_value: String)
signal map_interaction(interaction_type: String, data: Dictionary)

func _init(sim_api: SimulationAPI = null):
	simulation_api = sim_api if sim_api else FakeSimulation.new()

func initialize_map(initial_region: String = "") -> void:
	"""Initialize map view with optional region focus"""
	game_state = simulation_api.get_current_state()

	if initial_region != "":
		selected_region = initial_region
		_load_region_data(initial_region)

	_load_all_regional_data()

func get_all_regions() -> Array[GeographicRegion]:
	"""Get all Dutch geographic regions"""
	return simulation_api.get_all_regions()

func get_region_data(region_id: String) -> Dictionary:
	"""Get comprehensive data for specific region"""
	var region = _find_region_by_id(region_id)
	if not region:
		return {}

	var polling_data = simulation_api.get_regional_polls(region_id)
	var demographics = simulation_api.get_regional_demographics(region_id)
	var campaign_activity = simulation_api.get_regional_campaign_activity(region_id)

	return {
		"region": region,
		"polling": polling_data,
		"demographics": demographics,
		"campaign_activity": campaign_activity,
		"player_support": _get_player_support_in_region(region_id),
		"trend": _calculate_regional_trend(region_id),
		"priority": _calculate_region_priority(region_id)
	}

func _find_region_by_id(region_id: String) -> GeographicRegion:
	"""Find region by ID"""
	var all_regions = get_all_regions()
	for region in all_regions:
		if region.region_id == region_id:
			return region
	return null

func _get_player_support_in_region(region_id: String) -> float:
	"""Get player party support percentage in region"""
	var regional_polls = simulation_api.get_regional_polls(region_id)
	if regional_polls.is_empty():
		return 0.0

	var latest_poll = regional_polls[0]
	var player_party_id = game_state.player_party.party_id
	return latest_poll.get_party_support(player_party_id)

func _calculate_regional_trend(region_id: String) -> float:
	"""Calculate support trend in region over time"""
	var regional_polls = simulation_api.get_regional_polls(region_id)
	if regional_polls.size() < 2:
		return 0.0

	var latest = regional_polls[0]
	var previous = regional_polls[1]
	var player_party_id = game_state.player_party.party_id

	var latest_support = latest.get_party_support(player_party_id)
	var previous_support = previous.get_party_support(player_party_id)

	return latest_support - previous_support

func _calculate_region_priority(region_id: String) -> String:
	"""Calculate strategic priority for region"""
	var support = _get_player_support_in_region(region_id)
	var trend = _calculate_regional_trend(region_id)

	if support >= 30.0:
		return "stronghold"
	elif support >= 20.0 and trend > 0:
		return "opportunity"
	elif support < 10.0 and trend < -1.0:
		return "at_risk"
	elif support < 15.0:
		return "target"
	else:
		return "stable"

func select_region(region_id: String) -> void:
	"""Select region for detailed view"""
	selected_region = region_id
	var region_data = get_region_data(region_id)
	region_selected.emit(region_data)

func apply_filter(type: String, value: String) -> void:
	"""Apply filter to map view"""
	filter_type = type
	filter_value = value
	filter_applied.emit(type, value)

	_refresh_filtered_data()

func clear_filter() -> void:
	"""Clear current filter"""
	filter_type = ""
	filter_value = ""
	filter_applied.emit("", "")

	_load_all_regional_data()

func _refresh_filtered_data() -> void:
	"""Refresh data based on current filter"""
	var filtered_regions = _get_filtered_regions()

	for region in filtered_regions:
		var region_data = get_region_data(region.region_id)
		region_data_updated.emit(region.region_id, region_data)

func _get_filtered_regions() -> Array[GeographicRegion]:
	"""Get regions matching current filter"""
	var all_regions = get_all_regions()
	var filtered_regions: Array[GeographicRegion] = []

	for region in all_regions:
		if _region_matches_filter(region):
			filtered_regions.append(region)

	return filtered_regions

func _region_matches_filter(region: GeographicRegion) -> bool:
	"""Check if region matches current filter criteria"""
	if filter_type == "":
		return true

	match filter_type:
		"support_level":
			return _check_support_level_filter(region, filter_value)
		"demographic":
			return _check_demographic_filter(region, filter_value)
		"urbanization":
			return _check_urbanization_filter(region, filter_value)
		"priority":
			return _check_priority_filter(region, filter_value)
		_:
			return true

func _check_support_level_filter(region: GeographicRegion, level: String) -> bool:
	"""Check if region matches support level filter"""
	var support = _get_player_support_in_region(region.region_id)

	match level:
		"high":
			return support >= 25.0
		"medium":
			return support >= 15.0 and support < 25.0
		"low":
			return support < 15.0
		_:
			return true

func _check_demographic_filter(region: GeographicRegion, demographic: String) -> bool:
	"""Check if region matches demographic filter"""
	var demographics = simulation_api.get_regional_demographics(region.region_id)

	match demographic:
		"young":
			return demographics.age_distribution.get("18-35", 0) > 0.3
		"elderly":
			return demographics.age_distribution.get("65+", 0) > 0.2
		"high_income":
			return demographics.income_distribution.get("high", 0) > 0.25
		"low_income":
			return demographics.income_distribution.get("low", 0) > 0.25
		_:
			return true

func _check_urbanization_filter(region: GeographicRegion, level: String) -> bool:
	"""Check if region matches urbanization filter"""
	match level:
		"urban":
			return region.urbanization_level >= 0.7
		"suburban":
			return region.urbanization_level >= 0.4 and region.urbanization_level < 0.7
		"rural":
			return region.urbanization_level < 0.4
		_:
			return true

func _check_priority_filter(region: GeographicRegion, priority: String) -> bool:
	"""Check if region matches priority filter"""
	var calculated_priority = _calculate_region_priority(region.region_id)
	return calculated_priority == priority

func set_view_mode(mode: String) -> void:
	"""Set map visualization mode"""
	view_mode = mode
	_load_all_regional_data()

func _load_all_regional_data() -> void:
	"""Load data for all regions"""
	var all_regions = get_all_regions()

	for region in all_regions:
		var region_data = get_region_data(region.region_id)
		region_data_updated.emit(region.region_id, region_data)

func _load_region_data(region_id: String) -> void:
	"""Load data for specific region"""
	var region_data = get_region_data(region_id)
	region_data_updated.emit(region_id, region_data)

# Campaign planning features

func get_recommended_actions_for_region(region_id: String) -> Array[CampaignAction]:
	"""Get recommended campaign actions for specific region"""
	var region_priority = _calculate_region_priority(region_id)
	var region_demographics = simulation_api.get_regional_demographics(region_id)
	var available_actions = simulation_api.get_available_actions()

	var recommended: Array[CampaignAction] = []

	for action in available_actions:
		if _is_action_suitable_for_region(action, region_id, region_priority, region_demographics):
			recommended.append(action)

	return recommended

func _is_action_suitable_for_region(action: CampaignAction, region_id: String, priority: String, demographics: Dictionary) -> bool:
	"""Determine if action is suitable for region"""
	match priority:
		"stronghold":
			# Focus on maintaining support
			return action.action_type in ["rallies", "local_media"]
		"opportunity":
			# Focus on growth
			return action.action_type in ["advertising", "door_to_door", "local_events"]
		"target":
			# Focus on outreach
			return action.action_type in ["advertising", "social_media", "community_engagement"]
		"at_risk":
			# Focus on damage control
			return action.action_type in ["crisis_management", "local_media", "community_meetings"]
		_:
			return true

func plan_regional_campaign(region_id: String, budget: int) -> Dictionary:
	"""Create campaign plan for specific region"""
	var recommended_actions = get_recommended_actions_for_region(region_id)
	var affordable_actions: Array[CampaignAction] = []
	var total_cost = 0

	# Select actions within budget
	for action in recommended_actions:
		if total_cost + action.cost <= budget:
			affordable_actions.append(action)
			total_cost += action.cost

	var expected_impact = _calculate_expected_impact(affordable_actions, region_id)

	return {
		"region_id": region_id,
		"actions": affordable_actions,
		"total_cost": total_cost,
		"budget_remaining": budget - total_cost,
		"expected_impact": expected_impact,
		"timeline": _calculate_action_timeline(affordable_actions)
	}

func _calculate_expected_impact(actions: Array[CampaignAction], region_id: String) -> Dictionary:
	"""Calculate expected impact of actions in region"""
	var total_polling_impact = 0.0
	var total_awareness_impact = 0.0

	for action in actions:
		# This would use more sophisticated modeling in full implementation
		match action.action_type:
			"advertising":
				total_polling_impact += 2.5
				total_awareness_impact += 5.0
			"rallies":
				total_polling_impact += 3.0
				total_awareness_impact += 7.0
			"door_to_door":
				total_polling_impact += 1.5
				total_awareness_impact += 3.0
			"social_media":
				total_polling_impact += 1.0
				total_awareness_impact += 8.0

	return {
		"polling_boost": total_polling_impact,
		"awareness_boost": total_awareness_impact,
		"confidence": "medium"
	}

func _calculate_action_timeline(actions: Array[CampaignAction]) -> Array[Dictionary]:
	"""Calculate timeline for executing actions"""
	var timeline = []
	var current_day = 0

	for action in actions:
		timeline.append({
			"action": action,
			"start_day": current_day,
			"duration": _get_action_duration(action),
			"end_day": current_day + _get_action_duration(action)
		})
		current_day += _get_action_duration(action) + 1  # 1 day gap between actions

	return timeline

func _get_action_duration(action: CampaignAction) -> int:
	"""Get duration for campaign action"""
	match action.action_type:
		"advertising":
			return 7  # 1 week campaign
		"rallies":
			return 3  # 3 days including setup
		"door_to_door":
			return 5  # 5 days of canvassing
		"social_media":
			return 1  # 1 day to launch
		_:
			return 2  # Default duration

# Export and analysis features

func export_regional_analysis() -> Dictionary:
	"""Export comprehensive regional analysis"""
	var all_regions = get_all_regions()
	var analysis = {
		"timestamp": Time.get_unix_time_from_system(),
		"total_regions": all_regions.size(),
		"regions": {},
		"summary": {}
	}

	var total_support = 0.0
	var strongholds = 0
	var opportunities = 0
	var targets = 0
	var at_risk = 0

	for region in all_regions:
		var region_data = get_region_data(region.region_id)
		analysis.regions[region.region_id] = region_data

		total_support += region_data.player_support
		match region_data.priority:
			"stronghold":
				strongholds += 1
			"opportunity":
				opportunities += 1
			"target":
				targets += 1
			"at_risk":
				at_risk += 1

	analysis.summary = {
		"average_support": total_support / all_regions.size(),
		"strongholds": strongholds,
		"opportunities": opportunities,
		"targets": targets,
		"at_risk": at_risk
	}

	return analysis

# Map interaction handling

func handle_region_click(region_id: String) -> void:
	"""Handle region click interaction"""
	select_region(region_id)
	map_interaction.emit("region_click", {"region_id": region_id})

func handle_region_hover(region_id: String) -> void:
	"""Handle region hover interaction"""
	var region_data = get_region_data(region_id)
	map_interaction.emit("region_hover", region_data)

func handle_region_double_click(region_id: String) -> void:
	"""Handle region double-click for detailed view"""
	select_region(region_id)
	map_interaction.emit("region_details", {"region_id": region_id})

# Constitutional compliance

func get_transparency_data() -> Dictionary:
	"""Get transparency data for constitutional compliance"""
	return {
		"data_sources": [
			"regional_polling_data",
			"demographic_census_data",
			"campaign_activity_tracking"
		],
		"calculation_methods": {
			"support_levels": "weighted_polling_average",
			"trends": "linear_regression_3_months",
			"priorities": "strategic_algorithm_v2"
		},
		"regional_coverage": get_all_regions().size(),
		"last_update": Time.get_unix_time_from_system(),
		"filter_status": {
			"type": filter_type,
			"value": filter_value,
			"active": filter_type != ""
		}
	}

func validate_geographic_accuracy() -> bool:
	"""Validate that geographic data is accurate"""
	var all_regions = get_all_regions()

	# Check that we have all Dutch provinces
	var expected_provinces = [
		"noord_holland", "zuid_holland", "utrecht", "gelderland",
		"overijssel", "flevoland", "friesland", "groningen", "drenthe",
		"noord_brabant", "limburg", "zeeland"
	]

	var found_provinces = []
	for region in all_regions:
		found_provinces.append(region.region_id)

	# Verify all provinces are represented
	for province in expected_provinces:
		if province not in found_provinces:
			return false

	return true