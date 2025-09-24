extends RefCounted
class_name TestSimulationAPIContract

# Contract test for SimulationAPI interface compliance
# CRITICAL: This test MUST FAIL before implementation exists

var test_api: SimulationAPI

func _init():
	# This will fail initially since FakeSimulation doesn't exist yet
	test_api = FakeSimulation.new()

func test_initialize_game_signature():
	# Test that initialize_game method exists with correct signature
	var game_state = test_api.initialize_game("test_scenario", 12345)
	assert(game_state != null, "initialize_game must return GameState")
	assert(game_state is GameState, "initialize_game must return GameState type")

func test_load_game_signature():
	# Test that load_game method exists with correct signature
	var save_data = {"version": "1.0", "seed": 12345}
	var game_state = test_api.load_game(save_data)
	assert(game_state != null, "load_game must return GameState")
	assert(game_state is GameState, "load_game must return GameState type")

func test_save_game_signature():
	# Test that save_game method exists with correct signature
	var game_state = GameState.new()
	var save_data = test_api.save_game(game_state)
	assert(save_data != null, "save_game must return Dictionary")
	assert(save_data is Dictionary, "save_game must return Dictionary type")

func test_execute_campaign_action_signature():
	# Test that execute_campaign_action method exists with correct signature
	var action = CampaignAction.new()
	var game_state = GameState.new()
	var result = test_api.execute_campaign_action(action, game_state)
	assert(result != null, "execute_campaign_action must return ActionResult")
	assert(result is ActionResult, "execute_campaign_action must return ActionResult type")

func test_get_available_actions_signature():
	# Test that get_available_actions method exists with correct signature
	var game_state = GameState.new()
	var actions = test_api.get_available_actions("test_party", game_state)
	assert(actions != null, "get_available_actions must return Array")
	assert(actions is Array, "get_available_actions must return Array type")

func test_calculate_current_polls_signature():
	# Test that calculate_current_polls method exists with correct signature
	var game_state = GameState.new()
	var poll = test_api.calculate_current_polls(game_state)
	assert(poll != null, "calculate_current_polls must return OpinionPoll")
	assert(poll is OpinionPoll, "calculate_current_polls must return OpinionPoll type")

func test_get_regional_data_signature():
	# Test that get_regional_data method exists with correct signature
	var game_state = GameState.new()
	var data = test_api.get_regional_data("party_support", "test_party", game_state)
	assert(data != null, "get_regional_data must return Dictionary")
	assert(data is Dictionary, "get_regional_data must return Dictionary type")

func test_generate_media_event_signature():
	# Test that generate_media_event method exists with correct signature
	var game_state = GameState.new()
	var event = test_api.generate_media_event("tv_interview", game_state)
	assert(event != null, "generate_media_event must return MediaEvent")
	assert(event is MediaEvent, "generate_media_event must return MediaEvent type")

func test_explain_metric_signature():
	# Test that explain_metric method exists with correct signature
	var context = {"test": "value"}
	var tooltip = test_api.explain_metric("poll_percentage", 35.2, context)
	assert(tooltip != null, "explain_metric must return TooltipData")
	assert(tooltip is TooltipData, "explain_metric must return TooltipData type")

func run_all_tests():
	print("Running SimulationAPI contract tests...")
	test_initialize_game_signature()
	test_load_game_signature()
	test_save_game_signature()
	test_execute_campaign_action_signature()
	test_get_available_actions_signature()
	test_calculate_current_polls_signature()
	test_get_regional_data_signature()
	test_generate_media_event_signature()
	test_explain_metric_signature()
	print("All SimulationAPI contract tests completed")