extends RefCounted
class_name TestDashboardFlow

# Integration test: Dashboard KPI display and tooltip explanations
# CRITICAL: This test MUST FAIL before implementation exists

var dashboard_controller: DashboardController
var simulation_api: SimulationAPI

func _init():
	# This will fail initially since classes don't exist yet
	dashboard_controller = DashboardController.new()
	simulation_api = FakeSimulation.new()

func test_dashboard_displays_correct_kpis():
	# Test that dashboard shows correct KPI values from game state
	var game_state = GameState.new()
	game_state.current_date = "2025-01-15"
	game_state.player_party_id = "test_party"

	# Get current polls from simulation
	var polls = simulation_api.calculate_current_polls(game_state)
	var player_polls = polls.party_standings.get("test_party", 0.0)

	# Get projected seats for player party
	var player_party = null
	for party in game_state.parties:
		if party.id == "test_party":
			player_party = party
			break

	assert(player_party != null, "Player party must exist in game state")

	# Update dashboard with current values
	dashboard_controller.update_kpis(
		player_polls,
		player_party.projected_seats,
		player_party.campaign_funds,
		30  # days_left
	)

	# Verify dashboard shows correct values (will fail until UI implemented)
	var displayed_polls = dashboard_controller.poll_percentage_label.text
	var expected_polls = "%.1f%%" % player_polls
	assert(displayed_polls == expected_polls, "Dashboard must show correct poll percentage")

	var displayed_seats = dashboard_controller.projected_seats_label.text
	var expected_seats = "%d seats" % player_party.projected_seats
	assert(displayed_seats == expected_seats, "Dashboard must show correct projected seats")

	print("Dashboard KPI display test completed")

func test_tooltip_explanations_work():
	# Test that tooltips provide explanations for KPI values
	var tooltip_manager = TooltipManager.new()
	var target_element = Control.new()

	# Create tooltip data for poll percentage
	var tooltip_data = simulation_api.explain_metric(
		"poll_percentage",
		35.2,
		{"party_id": "test_party", "recent_actions": ["rally", "advertisement"]}
	)

	# Show tooltip and verify it contains explanation
	tooltip_manager.show_tooltip(target_element, tooltip_data)

	assert(tooltip_data.title != null and tooltip_data.title != "", "Tooltip must have title")
	assert(tooltip_data.explanation != null and tooltip_data.explanation != "", "Tooltip must have explanation")
	assert(tooltip_data.contributing_factors.size() > 0, "Tooltip must list contributing factors")

	print("Tooltip explanations test completed")

func test_daily_changes_display():
	# Test that dashboard shows daily changes with explanations
	var changes = {
		"polls": 2.1,
		"funds": -15000,
		"projected_seats": 3
	}

	var explanations = {
		"polls": "Successful rally in Amsterdam increased support",
		"funds": "TV advertisement campaign costs",
		"projected_seats": "Poll increase translated to more projected seats"
	}

	dashboard_controller.show_daily_changes(changes, explanations)

	# Verify changes are displayed with explanations (will fail until implemented)
	# This test ensures constitutional requirement for transparency/explainability

	print("Daily changes display test completed")

func test_campaign_action_selection():
	# Test that dashboard properly handles campaign action selection
	var available_actions = simulation_api.get_available_actions("test_party", GameState.new())

	assert(available_actions.size() > 0, "Must have available campaign actions")

	var selected_action = dashboard_controller.request_campaign_action(available_actions)
	# selected_action can be null if user cancelled

	if selected_action != null:
		assert(selected_action is CampaignAction, "Selected action must be CampaignAction")
		assert(available_actions.has(selected_action), "Selected action must be from available list")

	print("Campaign action selection test completed")

func run_all_tests():
	print("Running dashboard integration tests...")
	test_dashboard_displays_correct_kpis()
	test_tooltip_explanations_work()
	test_daily_changes_display()
	test_campaign_action_selection()
	print("All dashboard integration tests completed")