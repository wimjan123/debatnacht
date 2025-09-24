extends RefCounted
class_name TestMapInteraction

# Integration test: Map visualization with region filtering
# CRITICAL: This test MUST FAIL before implementation exists

var map_controller: MapViewController
var simulation_api: SimulationAPI

func _init():
	# This will fail initially since classes don't exist yet
	map_controller = MapViewController.new()
	simulation_api = FakeSimulation.new()

func test_map_visualization_with_party_support():
	# Test map displays party support data correctly
	var game_state = GameState.new()

	# Get regional data for party support visualization
	var region_data = simulation_api.get_regional_data(
		"party_support",
		"test_party",
		game_state
	)

	var legend_info = {
		"min": 0.0,
		"max": 1.0,
		"title": "Party Support",
		"unit": "%"
	}

	# Update map with party support data
	map_controller.update_map_data("party_support", region_data, legend_info)

	# Verify map shows regional variations (will fail until implemented)
	assert(region_data.size() > 0, "Must have regional party support data")
	assert(region_data.has("Noord-Holland"), "Must include major provinces")
	assert(region_data.has("Zuid-Holland"), "Must include major provinces")

	print("Map party support visualization test completed")

func test_region_tooltip_details():
	# Test that region tooltips show detailed information
	var game_state = GameState.new()
	var region_id = "Noord-Holland"

	# Get tooltip data for specific region
	var tooltip_data = simulation_api.get_region_tooltip_data(region_id, game_state)

	# Show region tooltip
	map_controller.show_region_tooltip(region_id, tooltip_data)

	# Verify tooltip contains required information
	assert(tooltip_data.region_name != null, "Tooltip must show region name")
	assert(tooltip_data.party_support != null, "Tooltip must show party support breakdown")
	assert(tooltip_data.key_issues.size() > 0, "Tooltip must show key local issues")
	assert(tooltip_data.demographic_info != null, "Tooltip must show demographic information")
	assert(tooltip_data.turnout_prediction > 0.0, "Tooltip must show turnout prediction")

	print("Region tooltip details test completed")

func test_map_filter_switching():
	# Test switching between different map visualization filters
	var game_state = GameState.new()

	# Test party support filter
	var party_data = simulation_api.get_regional_data("party_support", "test_party", game_state)
	map_controller.update_map_data("party_support", party_data, {"title": "Party Support"})

	# Test issue salience filter
	var issue_data = simulation_api.get_regional_data("issue_salience", "healthcare", game_state)
	map_controller.update_map_data("issue_salience", issue_data, {"title": "Healthcare Importance"})

	# Test turnout prediction filter
	var turnout_data = simulation_api.get_regional_data("turnout", "", game_state)
	map_controller.update_map_data("turnout", turnout_data, {"title": "Expected Turnout"})

	# Test demographics filter
	var demo_data = simulation_api.get_regional_data("demographics", "age_65plus", game_state)
	map_controller.update_map_data("demographics", demo_data, {"title": "Population 65+"})

	# Verify all filters work (will fail until implemented)
	assert(party_data.size() > 0, "Party support data must be available")
	assert(issue_data.size() > 0, "Issue salience data must be available")
	assert(turnout_data.size() > 0, "Turnout data must be available")
	assert(demo_data.size() > 0, "Demographics data must be available")

	print("Map filter switching test completed")

func test_map_filter_persistence():
	# Test that map remembers current filter settings
	var initial_filters = {
		"type": "party_support",
		"party": "test_party",
		"show_labels": true
	}

	# Set initial filter state
	map_controller.update_map_data(
		initial_filters.type,
		{},
		{"party": initial_filters.party}
	)

	# Get current filter state
	var current_filters = map_controller.get_current_filters()

	# Verify filter state persists (will fail until implemented)
	assert(current_filters is Dictionary, "Current filters must be Dictionary")
	assert(current_filters.has("type"), "Must remember filter type")

	print("Map filter persistence test completed")

func test_region_interaction_flow():
	# Test complete user interaction flow with regions
	var game_state = GameState.new()

	# 1. User selects party support filter
	var party_data = simulation_api.get_regional_data("party_support", "test_party", game_state)
	map_controller.update_map_data("party_support", party_data, {"title": "Support"})

	# 2. User hovers over region (simulated)
	var region_id = "Noord-Holland"
	var tooltip_data = simulation_api.get_region_tooltip_data(region_id, game_state)
	map_controller.show_region_tooltip(region_id, tooltip_data)

	# 3. Verify tooltip shows contextual information for current filter
	assert(tooltip_data.party_support.has("test_party"), "Tooltip must show party support for current party")

	# 4. User switches to different filter
	var issue_data = simulation_api.get_regional_data("issue_salience", "environment", game_state)
	map_controller.update_map_data("issue_salience", issue_data, {"title": "Environmental Concern"})

	# 5. Verify new tooltip data reflects filter change
	var new_tooltip_data = simulation_api.get_region_tooltip_data(region_id, game_state)
	assert(new_tooltip_data.key_issues.size() > 0, "Tooltip must show relevant issues for new filter")

	print("Region interaction flow test completed")

func run_all_tests():
	print("Running map interaction tests...")
	test_map_visualization_with_party_support()
	test_region_tooltip_details()
	test_map_filter_switching()
	test_map_filter_persistence()
	test_region_interaction_flow()
	print("All map interaction tests completed")