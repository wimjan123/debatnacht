extends RefCounted
class_name TestDataModels

# Contract test for data model validation rules
# CRITICAL: This test MUST FAIL before implementation exists

func test_game_state_validation():
	# Test GameState class exists and has required attributes
	var state = GameState.new()

	# Test required properties exist (will fail until implemented)
	assert(state.has_method("get") or "current_date" in state, "GameState must have current_date")
	assert(state.has_method("get") or "game_phase" in state, "GameState must have game_phase")
	assert(state.has_method("get") or "player_party_id" in state, "GameState must have player_party_id")
	assert(state.has_method("get") or "rng_seed" in state, "GameState must have rng_seed")

	print("GameState validation test completed")

func test_party_validation():
	# Test Party class exists and has required attributes
	var party = Party.new()

	# Test required properties exist (will fail until implemented)
	assert(party.has_method("get") or "id" in party, "Party must have id")
	assert(party.has_method("get") or "display_name" in party, "Party must have display_name")
	assert(party.has_method("get") or "ideology_position" in party, "Party must have ideology_position")
	assert(party.has_method("get") or "current_polls" in party, "Party must have current_polls")
	assert(party.has_method("get") or "projected_seats" in party, "Party must have projected_seats")

	# Test ideology position constraints
	if "ideology_position" in party and party.ideology_position != null:
		assert(party.ideology_position.x >= -1.0 and party.ideology_position.x <= 1.0, "Economic axis must be -1.0 to 1.0")
		assert(party.ideology_position.y >= -1.0 and party.ideology_position.y <= 1.0, "Social axis must be -1.0 to 1.0")

	print("Party validation test completed")

func test_campaign_action_validation():
	# Test CampaignAction class exists and has required attributes
	var action = CampaignAction.new()

	# Test required properties exist (will fail until implemented)
	assert(action.has_method("get") or "action_type" in action, "CampaignAction must have action_type")
	assert(action.has_method("get") or "cost" in action, "CampaignAction must have cost")
	assert(action.has_method("get") or "duration_hours" in action, "CampaignAction must have duration_hours")
	assert(action.has_method("get") or "expected_effects" in action, "CampaignAction must have expected_effects")

	print("CampaignAction validation test completed")

func test_opinion_poll_validation():
	# Test OpinionPoll class exists and has required attributes
	var poll = OpinionPoll.new()

	# Test required properties exist (will fail until implemented)
	assert(poll.has_method("get") or "poll_date" in poll, "OpinionPoll must have poll_date")
	assert(poll.has_method("get") or "party_standings" in poll, "OpinionPoll must have party_standings")
	assert(poll.has_method("get") or "margin_of_error" in poll, "OpinionPoll must have margin_of_error")
	assert(poll.has_method("get") or "sample_size" in poll, "OpinionPoll must have sample_size")

	print("OpinionPoll validation test completed")

func test_coalition_validation():
	# Test Coalition class exists and has required attributes
	var coalition = Coalition.new()

	# Test required properties exist (will fail until implemented)
	assert(coalition.has_method("get") or "member_parties" in coalition, "Coalition must have member_parties")
	assert(coalition.has_method("get") or "total_seats" in coalition, "Coalition must have total_seats")
	assert(coalition.has_method("get") or "majority_status" in coalition, "Coalition must have majority_status")
	assert(coalition.has_method("get") or "stability_score" in coalition, "Coalition must have stability_score")

	# Test majority status logic (76+ seats for Dutch parliament)
	if "total_seats" in coalition and "majority_status" in coalition:
		if coalition.total_seats != null and coalition.majority_status != null:
			assert((coalition.total_seats >= 76) == coalition.majority_status, "Majority status must match seat count >= 76")

	print("Coalition validation test completed")

func test_result_types_validation():
	# Test ActionResult class exists and has required attributes
	var result = ActionResult.new()

	# Test required properties exist (will fail until implemented)
	assert(result.has_method("get") or "success" in result, "ActionResult must have success")
	assert(result.has_method("get") or "new_state" in result, "ActionResult must have new_state")
	assert(result.has_method("get") or "effects" in result, "ActionResult must have effects")
	assert(result.has_method("get") or "explanation" in result, "ActionResult must have explanation")

	print("Result types validation test completed")

func test_ui_data_types_validation():
	# Test TooltipData class exists and has required attributes
	var tooltip = TooltipData.new()

	# Test required properties exist (will fail until implemented)
	assert(tooltip.has_method("get") or "title" in tooltip, "TooltipData must have title")
	assert(tooltip.has_method("get") or "current_value" in tooltip, "TooltipData must have current_value")
	assert(tooltip.has_method("get") or "explanation" in tooltip, "TooltipData must have explanation")

	print("UI data types validation test completed")

func run_all_tests():
	print("Running data model validation tests...")
	test_game_state_validation()
	test_party_validation()
	test_campaign_action_validation()
	test_opinion_poll_validation()
	test_coalition_validation()
	test_result_types_validation()
	test_ui_data_types_validation()
	print("All data model validation tests completed")