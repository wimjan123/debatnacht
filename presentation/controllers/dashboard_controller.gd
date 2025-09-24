extends RefCounted
class_name DashboardController

# Dashboard controller for KPI updates and campaign status management
# Coordinates between simulation API and dashboard UI components

var simulation_api: SimulationAPI
var game_state: GameState
var ui_state: Dictionary = {}

signal kpi_updated(kpi_type: String, new_value: Variant)
signal campaign_action_available(action: CampaignAction)
signal phase_transition(new_phase: String)
signal dashboard_ready()

func _init(sim_api: SimulationAPI = null):
	simulation_api = sim_api if sim_api else FakeSimulation.new()

func initialize_dashboard(initial_state: GameState = null) -> void:
	"""Initialize dashboard with current game state"""
	if initial_state:
		game_state = initial_state
	else:
		game_state = simulation_api.get_current_state()

	# Initialize UI state
	ui_state = {
		"selected_region": "",
		"view_mode": "overview",
		"filter_applied": false,
		"tutorial_active": false,
		"last_refresh": Time.get_unix_time_from_system()
	}

	dashboard_ready.emit()

func refresh_dashboard_data() -> void:
	"""Refresh all dashboard KPIs and data"""
	if not simulation_api or not game_state:
		return

	# Get current polling data
	var current_polls = simulation_api.get_current_polls()
	_update_polling_kpis(current_polls)

	# Get campaign status
	var campaign_status = simulation_api.get_campaign_status()
	_update_campaign_kpis(campaign_status)

	# Get available actions
	var available_actions = simulation_api.get_available_actions()
	_update_available_actions(available_actions)

	# Update regional data
	var regional_data = simulation_api.get_regional_breakdown()
	_update_regional_kpis(regional_data)

	# Check for phase transitions
	_check_phase_transitions()

	ui_state.last_refresh = Time.get_unix_time_from_system()

func _update_polling_kpis(polls: Array[OpinionPoll]) -> void:
	"""Update polling-related KPIs"""
	if polls.is_empty():
		return

	var latest_poll = polls[0]  # Most recent poll
	var player_party = game_state.player_party

	# National polling percentage
	var national_percentage = latest_poll.get_party_support(player_party.party_id)
	kpi_updated.emit("national_polling", national_percentage)

	# Seat projection
	var projected_seats = _calculate_seat_projection(latest_poll)
	kpi_updated.emit("projected_seats", projected_seats)

	# Polling trend (compare with previous poll if available)
	if polls.size() > 1:
		var previous_poll = polls[1]
		var previous_percentage = previous_poll.get_party_support(player_party.party_id)
		var trend = national_percentage - previous_percentage
		kpi_updated.emit("polling_trend", trend)

func _update_campaign_kpis(status: Dictionary) -> void:
	"""Update campaign-related KPIs"""
	kpi_updated.emit("campaign_funds", status.get("available_funds", 0))
	kpi_updated.emit("days_remaining", status.get("days_to_election", 0))
	kpi_updated.emit("actions_used", status.get("actions_used_today", 0))
	kpi_updated.emit("actions_remaining", status.get("actions_remaining_today", 0))

	# Media sentiment
	kpi_updated.emit("media_sentiment", status.get("media_sentiment", 0.0))

	# Campaign effectiveness
	kpi_updated.emit("campaign_effectiveness", status.get("effectiveness_rating", 0.0))

func _update_available_actions(actions: Array[CampaignAction]) -> void:
	"""Update available campaign actions"""
	for action in actions:
		if _is_action_recommended(action):
			campaign_action_available.emit(action)

func _update_regional_kpis(regional_data: Array[Dictionary]) -> void:
	"""Update regional breakdown data"""
	var strongest_regions = []
	var weakest_regions = []
	var player_party_id = game_state.player_party.party_id

	for region_data in regional_data:
		var region_name = region_data.region_name
		var support = region_data.party_support.get(player_party_id, 0.0)

		if support > 0.25:  # Strong support threshold
			strongest_regions.append({"region": region_name, "support": support})
		elif support < 0.1:  # Weak support threshold
			weakest_regions.append({"region": region_name, "support": support})

	kpi_updated.emit("strongest_regions", strongest_regions)
	kpi_updated.emit("weakest_regions", weakest_regions)

func _calculate_seat_projection(poll: OpinionPoll) -> int:
	"""Calculate projected seats using D'Hondt method"""
	var player_party_id = game_state.player_party.party_id
	var national_support = poll.get_party_support(player_party_id)

	# Simple seat calculation (150 seats in Dutch parliament)
	var total_seats = 150
	var projected_seats = int(national_support * total_seats / 100.0)

	return projected_seats

func _is_action_recommended(action: CampaignAction) -> bool:
	"""Determine if action should be highlighted as recommended"""
	# Simple heuristic based on current game state
	var player_party = game_state.player_party
	var funds = player_party.campaign_resources.available_funds

	# Don't recommend if can't afford
	if action.cost > funds:
		return false

	# Recommend high-value actions
	var expected_benefit = _calculate_action_benefit(action)
	return expected_benefit > 0.1  # 10% improvement threshold

func _calculate_action_benefit(action: CampaignAction) -> float:
	"""Calculate expected benefit of campaign action"""
	# This would use more sophisticated logic in full implementation
	match action.action_type:
		"advertising":
			return 0.15  # 15% expected benefit
		"rallies":
			return 0.12
		"media_appearances":
			return 0.08
		"social_media":
			return 0.05
		_:
			return 0.03

func _check_phase_transitions() -> void:
	"""Check if game phase should transition"""
	var current_phase = game_state.game_phase
	var days_remaining = simulation_api.get_campaign_status().get("days_to_election", 100)

	var new_phase = current_phase
	match current_phase:
		"campaign":
			if days_remaining <= 0:
				new_phase = "election"
		"election":
			# Check if election results are ready
			if simulation_api.get_election_results() != null:
				var election_result = simulation_api.get_election_results()
				if election_result.needs_coalition():
					new_phase = "coalition"
				elif election_result.has_majority():
					new_phase = "parliament"
		"coalition":
			# Check if coalition is formed
			if game_state.formed_coalition != null:
				new_phase = "parliament"

	if new_phase != current_phase:
		game_state.game_phase = new_phase
		phase_transition.emit(new_phase)

# Regional filtering and analysis

func set_regional_filter(region_name: String) -> void:
	"""Set regional filter for dashboard data"""
	ui_state.selected_region = region_name
	ui_state.filter_applied = region_name != ""

	# Refresh data with regional focus
	if region_name != "":
		_refresh_regional_data(region_name)

func _refresh_regional_data(region_name: String) -> void:
	"""Refresh data for specific region"""
	var regional_polls = simulation_api.get_regional_polls(region_name)
	var regional_demographics = simulation_api.get_regional_demographics(region_name)

	kpi_updated.emit("regional_polling", regional_polls)
	kpi_updated.emit("regional_demographics", regional_demographics)

func clear_regional_filter() -> void:
	"""Clear regional filter and return to national view"""
	ui_state.selected_region = ""
	ui_state.filter_applied = false
	refresh_dashboard_data()

# Campaign action execution

func execute_campaign_action(action: CampaignAction, target_region: String = "") -> ActionResult:
	"""Execute campaign action and update dashboard"""
	if not simulation_api:
		return ActionResult.new_failure("No simulation API available")

	# Execute action
	var result = simulation_api.execute_action(action, target_region)

	# Refresh dashboard data to reflect changes
	refresh_dashboard_data()

	return result

func get_action_preview(action: CampaignAction, target_region: String = "") -> Dictionary:
	"""Get preview of action effects without executing"""
	return simulation_api.preview_action_effects(action, target_region)

# Tutorial mode support

func set_tutorial_mode(enabled: bool) -> void:
	"""Enable/disable tutorial mode"""
	ui_state.tutorial_active = enabled

	if enabled:
		_setup_tutorial_guidance()

func _setup_tutorial_guidance() -> void:
	"""Setup tutorial-specific dashboard state"""
	# Highlight key KPIs for tutorial
	kpi_updated.emit("tutorial_highlight", ["national_polling", "campaign_funds", "days_remaining"])

func get_tutorial_step_data() -> Dictionary:
	"""Get data for current tutorial step"""
	if not ui_state.tutorial_active:
		return {}

	return {
		"current_polls": simulation_api.get_current_polls(),
		"available_actions": simulation_api.get_available_actions(),
		"recommended_action": _get_tutorial_recommended_action()
	}

func _get_tutorial_recommended_action() -> CampaignAction:
	"""Get recommended action for tutorial"""
	var actions = simulation_api.get_available_actions()
	# Return first affordable action
	var player_funds = game_state.player_party.campaign_resources.available_funds

	for action in actions:
		if action.cost <= player_funds:
			return action

	return null

# View mode management

func set_view_mode(mode: String) -> void:
	"""Set dashboard view mode (overview, detailed, regional)"""
	ui_state.view_mode = mode

	match mode:
		"overview":
			refresh_dashboard_data()
		"detailed":
			_load_detailed_data()
		"regional":
			_load_regional_overview()

func _load_detailed_data() -> void:
	"""Load detailed analytics data"""
	var detailed_polls = simulation_api.get_detailed_polling_data()
	var trend_analysis = simulation_api.get_polling_trends()
	var demographic_breakdown = simulation_api.get_demographic_analysis()

	kpi_updated.emit("detailed_polls", detailed_polls)
	kpi_updated.emit("trend_analysis", trend_analysis)
	kpi_updated.emit("demographic_breakdown", demographic_breakdown)

func _load_regional_overview() -> void:
	"""Load regional overview data"""
	var all_regions = simulation_api.get_all_regions()
	var regional_summary = []

	for region in all_regions:
		var region_data = simulation_api.get_regional_breakdown_for_region(region.region_id)
		regional_summary.append(region_data)

	kpi_updated.emit("regional_overview", regional_summary)

# State management

func get_dashboard_state() -> Dictionary:
	"""Get current dashboard state for persistence"""
	return {
		"ui_state": ui_state,
		"game_phase": game_state.game_phase if game_state else "",
		"last_update": Time.get_unix_time_from_system()
	}

func restore_dashboard_state(state: Dictionary) -> void:
	"""Restore dashboard state from saved data"""
	if state.has("ui_state"):
		ui_state = state.ui_state

	# Refresh data after state restoration
	refresh_dashboard_data()

# Constitutional compliance

func get_transparency_data() -> Dictionary:
	"""Get transparency data for constitutional compliance"""
	return {
		"data_sources": ["simulation_api", "opinion_polls", "campaign_status"],
		"calculation_methods": {
			"seat_projection": "D'Hondt method with current polling",
			"campaign_effectiveness": "Action success rate over time",
			"regional_strength": "Support percentage by region"
		},
		"last_update": ui_state.last_refresh,
		"assumptions": [
			"Polling trends continue",
			"Turnout similar to previous elections",
			"No major external events"
		]
	}

func validate_data_integrity() -> bool:
	"""Validate that dashboard data maintains integrity"""
	if not simulation_api or not game_state:
		return false

	# Check that polling percentages sum to reasonable total
	var polls = simulation_api.get_current_polls()
	if polls.is_empty():
		return true

	var latest_poll = polls[0]
	var total_support = 0.0

	for party_id in latest_poll.party_support.keys():
		total_support += latest_poll.party_support[party_id]

	# Should be close to 100% (allow some margin for undecided voters)
	return total_support >= 80.0 and total_support <= 110.0